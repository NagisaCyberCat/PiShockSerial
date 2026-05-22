unit uPiShockDevice;
{
  PiShock-Geraeteerkennung und serielle Kommunikation.
  Verwendet MHumm/ComPortDriver (CPDrv.pas) fuer die serielle Schnittstelle
  und SerialPorts.pas fuer die Portauflistung.

  VID/PID der PiShock-Geraete:
    VID  0x1A86
    PID  0x7523 -> Next-Hardware (Typ 3 in TERMINALINFO)
    PID  0x55D4 -> Lite-Hardware (Typ 4 in TERMINALINFO)

  Kommunikation: 115200 Baud, 8N1, JSON-Kommandos, zeilenweise ('\n')
  Antwort: "TERMINALINFO:[JSON]" nach "info"-Kommando
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.JSON,
  System.Generics.Collections, System.SyncObjs,
  StrUtils,
  CPDrv, SerialPorts;

type
  TDeviceGeneration = (dgUnknown, dgNext, dgLite);

  TShockerInfo = record
    ID          : Integer;  // Shocker-ID (wie auf der Website)
    ShockerType : Integer;  // 0=Petrainer, 1=SmallOne
    Paused      : Boolean;
  end;

  TDeviceInfo = record
    FirmwareVersion : string;
    HardwareType    : Integer;     // 3=Next, 4=Lite
    Generation      : TDeviceGeneration;
    IsConnected     : Boolean;     // Mit PiShock-Server verbunden?
    ClientId        : Integer;
    WiFiSSID        : string;
    Shockers        : TArray<TShockerInfo>;
  end;

  TOnDeviceInfoEvent = procedure(const Info: TDeviceInfo) of object;
  TOnSerialLogEvent  = procedure(const Msg: string) of object;

  /// <summary>Erkanntes PiShock-Geraet mit COM-Port-Infos</summary>
  TPiShockPortInfo = record
    PortName     : string;   // z.B. "COM3"
    Generation   : TDeviceGeneration;
    FriendlyName : string;   // z.B. "USB-SERIAL CH340 (COM3)"
  end;

/// <summary>Alle seriellen Ports auflisten (fuer ComboBox)</summary>
procedure GetAllComPorts(Dest: TStrings);

/// <summary>
///   Registry nach PiShock-Geraeten (VID 0x1A86 + bekannte PIDs) durchsuchen.
///   Gibt Eintraege fuer jeden gefundenen Port zurueck.
/// </summary>
function FindPiShockPorts: TArray<TPiShockPortInfo>;

type
  /// <summary>
  ///   Kapselt die Kommunikation mit einem PiShock-Geraet ueber die serielle
  ///   Schnittstelle. Ereignisse werden im Hauptthread ausgeloest (CPDrv
  ///   nutzt Timer-basiertes Polling im VCL-Thread).
  /// </summary>
  TPiShockDevice = class
  private
    FComDrv      : TCommPortDriver;
    FDeviceInfo  : TDeviceInfo;
    FBuffer      : string;          // Empfangspuffer (Hauptthread)
    FOnDeviceInfo: TOnDeviceInfoEvent;
    FOnLog       : TOnSerialLogEvent;
    FIsConnected : Boolean;

    procedure OnReceiveData(Sender: TObject; DataPtr: Pointer; DataSize: DWORD);
    procedure ProcessBuffer;
    procedure ParseTerminalInfo(const JSON: string);
    procedure DoLog(const Msg: string);
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Verbindung zum angegebenen COM-Port herstellen (z.B. "COM3").
    ///   Sendet nach erfolgreicher Verbindung automatisch ein "info"-Kommando.
    /// </summary>
    function Connect(const APortName: string): Boolean;

    /// <summary>Verbindung trennen</summary>
    procedure Disconnect;

    /// <summary>TERMINALINFO anfordern (Firmware, Module etc.)</summary>
    procedure RequestInfo;

    /// <summary>
    ///   Operate-Kommando senden.
    ///   Op: "shock" | "vibrate" | "beep" | "end"
    ///   Intensity wird fuer "beep" und "end" ignoriert.
    /// </summary>
    procedure Operate(ShockerID: Integer; const Op: string;
      Duration, Intensity: Integer);

    /// <summary>Alle bekannten Module sofort stoppen</summary>
    procedure EndAll;

    property IsConnected : Boolean      read FIsConnected;
    property DeviceInfo  : TDeviceInfo  read FDeviceInfo;
    property OnDeviceInfo: TOnDeviceInfoEvent
      read FOnDeviceInfo write FOnDeviceInfo;
    property OnLog: TOnSerialLogEvent
      read FOnLog write FOnLog;
  end;

implementation

const
  PISHOCK_VID      = 'VID_1A86';
  PISHOCK_PID_NEXT = 'PID_7523';  // Next-Hardware
  PISHOCK_PID_LITE = 'PID_55D4';  // Lite-Hardware

{ ---- Port-Auflistung und PiShock-Erkennung -------------------------------- }

procedure GetAllComPorts(Dest: TStrings);
var
  Ports : TSerialPortList;
  Port  : TSerialPort;
begin
  Dest.Clear;
  Ports := GetComPorts;
  try
    for Port in Ports do
      Dest.Add(Port.PortName);
  finally
    Ports.Free;
  end;
end;

function FindPiShockPorts: TArray<TPiShockPortInfo>;
var
  Ports   : TSerialPortList;
  Port    : TSerialPort;
  KeyUp   : string;
  Gen     : TDeviceGeneration;
  Results : TList<TPiShockPortInfo>;
  Info    : TPiShockPortInfo;
begin
  Results := TList<TPiShockPortInfo>.Create;
  Ports   := GetComPorts;
  try
    for Port in Ports do
    begin
      KeyUp := UpperCase(Port.KeyEnum);
      if not ContainsStr(KeyUp, PISHOCK_VID) then
        Continue;

      if ContainsStr(KeyUp, PISHOCK_PID_NEXT) then
        Gen := dgNext
      else if ContainsStr(KeyUp, PISHOCK_PID_LITE) then
        Gen := dgLite
      else
        Continue;

      Info.PortName     := Port.PortName;
      Info.Generation   := Gen;
      Info.FriendlyName := Port.FriendlyName;
      Results.Add(Info);
    end;
    Result := Results.ToArray;
  finally
    Results.Free;
    Ports.Free;
  end;
end;

{ ---- TPiShockDevice ------------------------------------------------------- }

constructor TPiShockDevice.Create;
begin
  inherited Create;
  FIsConnected := False;
  FBuffer      := '';

  FComDrv := TCommPortDriver.Create(nil);
  FComDrv.BaudRate      := br115200;
  FComDrv.DataBits      := db8BITS;
  FComDrv.StopBits      := sb1BITS;
  FComDrv.Parity        := ptNONE;
  FComDrv.HwFlow        := hfNONE;
  FComDrv.SwFlow        := sfNONE;
  FComDrv.OnReceiveData := OnReceiveData;
end;

destructor TPiShockDevice.Destroy;
begin
  Disconnect;
  FreeAndNil(FComDrv);
  inherited Destroy;
end;

function TPiShockDevice.Connect(const APortName: string): Boolean;
begin
  Result := False;
  try
    if FComDrv.Connected then
      FComDrv.Disconnect;

    FBuffer := '';
    // CPDrv erwartet "\\.\COMn" fuer den PortName
    FComDrv.PortName := '\\.\' + APortName;
    FComDrv.Port     := pnCustom;

    Result       := FComDrv.Connect;
    FIsConnected := Result;

    if Result then
    begin
      DoLog('Verbunden mit ' + APortName + ' (115200 8N1)');
      RequestInfo;
    end
    else
      DoLog('Verbindung zu ' + APortName + ' fehlgeschlagen');
  except
    on E: Exception do
    begin
      FIsConnected := False;
      DoLog('Verbindungsfehler (' + APortName + '): ' + E.Message);
    end;
  end;
end;

procedure TPiShockDevice.Disconnect;
begin
  if FComDrv.Connected then
  begin
    FComDrv.Disconnect;
    DoLog('Verbindung getrennt');
  end;
  FIsConnected := False;
end;

procedure TPiShockDevice.RequestInfo;
begin
  if not FComDrv.Connected then
    Exit;
  FComDrv.SendString('{"cmd":"info"}' + #10);
  DoLog('Info-Anfrage gesendet');
end;

procedure TPiShockDevice.Operate(ShockerID: Integer; const Op: string;
  Duration, Intensity: Integer);
var
  JSON: AnsiString;
begin
  if not FComDrv.Connected then
  begin
    DoLog('Geraet nicht verbunden - Operate ignoriert');
    Exit;
  end;

  if SameText(Op, 'beep') then
    JSON := AnsiString(
      Format('{"cmd":"operate","value":{"id":%d,"op":"beep","duration":%d}}',
        [ShockerID, Duration]))
  else if SameText(Op, 'end') then
    JSON := AnsiString(
      Format('{"cmd":"operate","value":{"id":%d,"op":"end","duration":0}}',
        [ShockerID]))
  else
    JSON := AnsiString(
      Format('{"cmd":"operate","value":{"id":%d,"op":"%s","duration":%d,"intensity":%d}}',
        [ShockerID, LowerCase(Op), Duration, Intensity]));

  FComDrv.SendString(JSON);
  FComDrv.SendString(#10);
  DoLog('Sende: ' + string(JSON));
end;

procedure TPiShockDevice.EndAll;
var
  S: TShockerInfo;
begin
  for S in FDeviceInfo.Shockers do
    Operate(S.ID, 'end', 0, 0);
end;

{ ---- Empfang und TERMINALINFO-Parsing ------------------------------------- }

// Wird vom CPDrv-Timer im Hauptthread aufgerufen
procedure TPiShockDevice.OnReceiveData(Sender: TObject;
  DataPtr: Pointer; DataSize: DWORD);
var
  Raw: AnsiString;
begin
  SetLength(Raw, DataSize);
  Move(DataPtr^, Raw[1], DataSize);
  FBuffer := FBuffer + string(Raw);
  ProcessBuffer;
end;

procedure TPiShockDevice.ProcessBuffer;
const
  TERM_PREFIX = 'TERMINALINFO:';
var
  P    : Integer;
  Line : string;
begin
  repeat
    // Suche nach Zeilenende (\r oder \n)
    P := 0;
    if ContainsStr(FBuffer, #10) then
      P := Pos(#10, FBuffer);
    if ContainsStr(FBuffer, #13) then
      if (Pos(#13, FBuffer) < P) or (P = 0) then
        P := Pos(#13, FBuffer);
    if P = 0 then
      Break;

    Line    := Trim(Copy(FBuffer, 1, P - 1));
    FBuffer := Copy(FBuffer, P + 1, MaxInt);

    // Folgende Zeilenenden ueberspringen
    while (FBuffer <> '') and CharInSet(FBuffer[1], [#10, #13]) do
      FBuffer := Copy(FBuffer, 2, MaxInt);

    if StartsStr(TERM_PREFIX, Line) then
      ParseTerminalInfo(Copy(Line, Length(TERM_PREFIX) + 1, MaxInt));
  until False;
end;

procedure TPiShockDevice.ParseTerminalInfo(const JSON: string);
var
  Obj        : TJSONObject;
  ShArr      : TJSONArray;
  ShObj      : TJSONObject;
  I          : Integer;
  S          : TShockerInfo;
  Shockers   : TArray<TShockerInfo>;
  Info       : TDeviceInfo;
  GenStr     : string;
begin
  Obj := TJSONObject.ParseJSONValue(JSON) as TJSONObject;
  if Obj = nil then
  begin
    DoLog('TERMINALINFO: Ungültiges JSON');
    Exit;
  end;
  try
    Info.FirmwareVersion := Obj.GetValue<string>('version', '');
    Info.HardwareType    := Obj.GetValue<Integer>('type', 0);
    Info.IsConnected     := Obj.GetValue<Boolean>('connected', False);
    Info.ClientId        := Obj.GetValue<Integer>('clientId', 0);
    Info.WiFiSSID        := Obj.GetValue<string>('wifi', '');

    case Info.HardwareType of
      3: Info.Generation := dgNext;
      4: Info.Generation := dgLite;
    else
      Info.Generation := dgUnknown;
    end;

    ShArr := Obj.GetValue('shockers') as TJSONArray;
    SetLength(Shockers, 0);
    if ShArr <> nil then
    begin
      SetLength(Shockers, ShArr.Count);
      for I := 0 to ShArr.Count - 1 do
      begin
        ShObj := ShArr.Items[I] as TJSONObject;
        S.ID          := ShObj.GetValue<Integer>('id', 0);
        S.ShockerType := ShObj.GetValue<Integer>('type', 0);
        S.Paused      := ShObj.GetValue<Boolean>('paused', False);
        Shockers[I]   := S;
      end;
    end;
    Info.Shockers := Shockers;
    FDeviceInfo   := Info;

    case Info.Generation of
      dgNext: GenStr := 'Next';
      dgLite: GenStr := 'Lite';
    else      GenStr := 'Unbekannt';
    end;

    DoLog(Format(
      'Ger'#228'tinfo: FW=%s | Typ=%s | %d Modul(e) | WLAN=%s | Server=%s',
      [Info.FirmwareVersion, GenStr, Length(Info.Shockers),
       Info.WiFiSSID,
       IfThen(Info.IsConnected, 'verbunden', 'getrennt')]));

    if Assigned(FOnDeviceInfo) then
      FOnDeviceInfo(FDeviceInfo);
  finally
    Obj.Free;
  end;
end;

procedure TPiShockDevice.DoLog(const Msg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Msg);
end;

end.
