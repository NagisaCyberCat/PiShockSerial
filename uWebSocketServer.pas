unit uWebSocketServer;
{
  WebSocket-Server auf Basis von Indy (TIdTCPServer).
  Implementiert RFC 6455 (WebSocket-Protokoll) manuell:
    - HTTP-Upgrade-Handshake
    - Frame-Parsing/-Encoding (Text, Ping/Pong, Close)
    - Mehrere gleichzeitige Verbindungen

  Jede Client-Verbindung laeuft im eigenen Indy-Thread.
  Callbacks (OnCommand, OnLog) werden per TThread.Synchronize/Queue
  sicher in den Hauptthread zurueckgefuehrt.
}

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs,
  System.Hash, System.NetEncoding,
  IdTCPServer, IdContext, IdBaseComponent, IdComponent,
  IdCustomTCPServer, IdGlobal, IdTCPConnection, IdYarn,
  IdExceptionCore, IdException;

type
  TWebSocketState = (wsHandshake, wsOpen);

  /// <summary>
  ///   Pro-Client-Kontext: haelt WebSocket-Zustand und Write-Lock
  ///   (mehrere Threads koennen WriteFrame aufrufen)
  /// </summary>
  TWebSocketClientCtx = class(TIdServerContext)
  public
    WSState   : TWebSocketState;
    WriteLock : TCriticalSection;
    constructor Create(AConnection: TIdTCPConnection; AYarn: TIdYarn;
      AList: TIdContextThreadList = nil); override;
    destructor Destroy; override;
  end;

  TOnWSCommandEvent      = procedure(const Cmd: string) of object;
  TOnWSLogEvent          = procedure(const Msg: string) of object;
  TOnWSClientCountEvent  = procedure(Count: Integer) of object;

  /// <summary>
  ///   WebSocket-Server.
  ///   Start(Port) -> Wartet auf Verbindungen.
  ///   Eingehende Text-Frames loesen OnCommand aus.
  ///   CloseAllClients / Stop fuer Not-Stop.
  /// </summary>
  TWebSocketServer = class
  private
    FServer          : TIdTCPServer;
    FPort            : Integer;
    FToken           : string;
    FClientLock      : TCriticalSection;
    FClientCount     : Integer;
    FOnCommand       : TOnWSCommandEvent;
    FOnLog           : TOnWSLogEvent;
    FOnClientCount   : TOnWSClientCountEvent;

    procedure DoConnect(AContext: TIdContext);
    procedure DoDisconnect(AContext: TIdContext);
    procedure DoExecute(AContext: TIdContext);

    function  PerformHandshake(AContext: TIdContext): Boolean;
    function  ReadFrame(AContext: TIdContext;
                out OpCode: Byte; out Data: TIdBytes): Boolean;
    procedure WriteFrame(AContext: TIdContext;
                OpCode: Byte; const Data: TIdBytes);
    procedure WriteCloseFrame(AContext: TIdContext);
    procedure WritePongFrame(AContext: TIdContext; const Data: TIdBytes);

    procedure DoLog(const Msg: string);
    function  GetActive: Boolean;

    class function CalcWSAccept(const Key: string): string; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Server auf dem angegebenen Port starten</summary>
    procedure Start(APort: Integer);

    /// <summary>Server stoppen (alle Verbindungen werden getrennt)</summary>
    procedure Stop;

    /// <summary>
    ///   Alle verbundenen Clients mit WebSocket-Close-Frame trennen.
    ///   Fuer Not-Stop-Funktion.
    /// </summary>
    procedure CloseAllClients;

    /// <summary>Text-Frame an alle verbundenen Clients senden</summary>
    procedure BroadcastText(const Text: string);

    property Active      : Boolean               read GetActive;
    property Port        : Integer               read FPort;
    property ClientCount : Integer               read FClientCount;
    /// <summary>
    ///   Optionaler Zugriffstoken. Ist er gesetzt, muss der Client ihn entweder
    ///   als URL-Query-Parameter (?token=...) oder als HTTP-Header
    ///   (Authorization: Bearer ...) beim Upgrade mitsenden.
    ///   Leer = keine Authentifizierung erforderlich.
    /// </summary>
    property Token       : string                read FToken write FToken;

    property OnCommand: TOnWSCommandEvent
      read FOnCommand write FOnCommand;
    property OnLog: TOnWSLogEvent
      read FOnLog write FOnLog;
    property OnClientCountChanged: TOnWSClientCountEvent
      read FOnClientCount write FOnClientCount;
  end;

implementation

uses
  System.Threading, StrUtils;

{ TWebSocketClientCtx }

constructor TWebSocketClientCtx.Create(AConnection: TIdTCPConnection;
  AYarn: TIdYarn; AList: TIdContextThreadList);
begin
  inherited Create(AConnection, AYarn, AList);
  WSState   := wsHandshake;
  WriteLock := TCriticalSection.Create;
end;

destructor TWebSocketClientCtx.Destroy;
begin
  FreeAndNil(WriteLock);
  inherited Destroy;
end;

{ TWebSocketServer }

constructor TWebSocketServer.Create;
begin
  inherited Create;
  FClientLock  := TCriticalSection.Create;
  FClientCount := 0;
  FPort        := 0;

  FServer              := TIdTCPServer.Create(nil);
  FServer.ContextClass := TWebSocketClientCtx;
  FServer.OnConnect    := DoConnect;
  FServer.OnDisconnect := DoDisconnect;
  FServer.OnExecute    := DoExecute;
end;

destructor TWebSocketServer.Destroy;
begin
  Stop;
  FreeAndNil(FServer);
  FreeAndNil(FClientLock);
  inherited Destroy;
end;

function TWebSocketServer.GetActive: Boolean;
begin
  Result := FServer.Active;
end;

procedure TWebSocketServer.Start(APort: Integer);
begin
  if FServer.Active then
    FServer.Active := False;

  FPort := APort;
  FServer.Bindings.Clear;
  with FServer.Bindings.Add do
  begin
    IP   := '0.0.0.0';
    Port := APort;
  end;

  FServer.Active := True;
  DoLog(Format('WebSocket-Server gestartet auf Port %d', [APort]));
end;

procedure TWebSocketServer.Stop;
begin
  if FServer.Active then
  begin
    FServer.Active := False;
    DoLog('WebSocket-Server gestoppt');
  end;
end;

procedure TWebSocketServer.CloseAllClients;
var
  List : TList;
  I    : Integer;
  Data : TIdBytes;
begin
  SetLength(Data, 0);
  List := FServer.Contexts.LockList;
  try
    for I := 0 to List.Count - 1 do
    try
      WriteFrame(TIdContext(List[I]), $08, Data);  // Close frame
      TIdContext(List[I]).Connection.Disconnect;
    except
      // Ignoriere Fehler beim Zwangs-Disconnect
    end;
  finally
    FServer.Contexts.UnlockList;
  end;
  DoLog('Alle WebSocket-Clients getrennt');
end;

procedure TWebSocketServer.BroadcastText(const Text: string);
var
  List : TList;
  I    : Integer;
  Data : TIdBytes;
begin
  Data := TIdBytes(TEncoding.UTF8.GetBytes(Text));
  List := FServer.Contexts.LockList;
  try
    for I := 0 to List.Count - 1 do
    try
      if (TIdContext(List[I]) as TWebSocketClientCtx).WSState = wsOpen then
        WriteFrame(TIdContext(List[I]), $01, Data);
    except
    end;
  finally
    FServer.Contexts.UnlockList;
  end;
end;

{ ---- Verbindungs-Events --------------------------------------------------- }

procedure TWebSocketServer.DoConnect(AContext: TIdContext);
begin
  FClientLock.Enter;
  try
    Inc(FClientCount);
  finally
    FClientLock.Leave;
  end;
  DoLog(Format('Neuer Client. Gesamt: %d', [FClientCount]));
  if Assigned(FOnClientCount) then
    TThread.Queue(nil, procedure
      begin
        FOnClientCount(FClientCount);
      end);
end;

procedure TWebSocketServer.DoDisconnect(AContext: TIdContext);
begin
  FClientLock.Enter;
  try
    if FClientCount > 0 then
      Dec(FClientCount);
  finally
    FClientLock.Leave;
  end;
  DoLog(Format('Client getrennt. Gesamt: %d', [FClientCount]));
  if Assigned(FOnClientCount) then
    TThread.Queue(nil, procedure
      begin
        FOnClientCount(FClientCount);
      end);
end;

{ ---- Haupt-Execute-Loop (pro Client, eigener Thread) ---------------------- }

procedure TWebSocketServer.DoExecute(AContext: TIdContext);
var
  Ctx    : TWebSocketClientCtx;
  OpCode : Byte;
  Data   : TIdBytes;
  Text   : string;
  EmptyData: TIdBytes;
begin
  Ctx := AContext as TWebSocketClientCtx;
  AContext.Connection.IOHandler.ReadTimeout := 5000;

  case Ctx.WSState of

    wsHandshake:
    begin
      if PerformHandshake(AContext) then
        Ctx.WSState := wsOpen
      else
        AContext.Connection.Disconnect;
    end;

    wsOpen:
    begin
      if ReadFrame(AContext, OpCode, Data) then
      begin
        case OpCode of
          $01: // Text-Frame
          begin
            Text := TEncoding.UTF8.GetString(TBytes(Data));
            DoLog('WS Empfangen: ' + Text);
            if Assigned(FOnCommand) then
              // Synchronize: blockiert bis Hauptthread verarbeitet hat
              TThread.Synchronize(nil, procedure
                begin
                  FOnCommand(Trim(Text));
                end);
          end;

          $02: ; // Binary-Frame: ignorieren

          $08: // Close-Frame
          begin
            SetLength(EmptyData, 0);
            WriteFrame(AContext, $08, EmptyData);
            AContext.Connection.Disconnect;
          end;

          $09: // Ping -> Pong
            WritePongFrame(AContext, Data);
        end;
      end;
      // Bei Timeout (Result=False) einfach weiter -> Indy ruft DoExecute erneut
    end;

  end;
end;

{ ---- WebSocket-Handshake (RFC 6455) --------------------------------------- }

function TWebSocketServer.PerformHandshake(AContext: TIdContext): Boolean;
var
  Line, WsKey, Resp    : string;
  RequestPath          : string;
  AuthHeader           : string;
  QueryToken           : string;
  TokenOk              : Boolean;
  SpacePos             : Integer;
begin
  Result := False;
  try
    // Request-Zeile lesen (z.B. "GET /?token=abc HTTP/1.1")
    Line := Trim(AContext.Connection.IOHandler.ReadLn(#10, 5000));
    if not StartsStr('GET ', Line) then
      Exit;

    // Pfad inkl. Query-String aus Request-Zeile extrahieren
    RequestPath := Copy(Line, 5, MaxInt);
    SpacePos    := Pos(' ', RequestPath);
    if SpacePos > 0 then
      RequestPath := Copy(RequestPath, 1, SpacePos - 1);

    // Token aus Query-String ?token=... lesen
    QueryToken := '';
    SpacePos   := Pos('?token=', RequestPath);
    if SpacePos > 0 then
    begin
      QueryToken := Copy(RequestPath, SpacePos + 7, MaxInt);
      SpacePos   := Pos('&', QueryToken);
      if SpacePos > 0 then
        QueryToken := Copy(QueryToken, 1, SpacePos - 1);
    end;

    // Header lesen bis Leerzeile
    WsKey      := '';
    AuthHeader := '';
    repeat
      Line := Trim(AContext.Connection.IOHandler.ReadLn(#10, 5000));
      if StartsText('Sec-WebSocket-Key:', Line) then
        WsKey := Trim(Copy(Line, Pos(':', Line) + 1, MaxInt));
      if StartsText('Authorization:', Line) then
        AuthHeader := Trim(Copy(Line, Pos(':', Line) + 1, MaxInt));
    until Line = '';

    if WsKey = '' then
    begin
      DoLog('Handshake: kein Sec-WebSocket-Key');
      Exit;
    end;

    // Token-Prüfung (nur wenn Server-Token gesetzt)
    if FToken <> '' then
    begin
      TokenOk := False;
      // 1. Bearer-Token aus Authorization-Header  (Bearer TOKEN)
      if StartsText('Bearer ', AuthHeader) then
        TokenOk := (Trim(Copy(AuthHeader, 8, MaxInt)) = FToken);
      // 2. Direktwert im Authorization-Header ohne Prefix (TOKEN)
      if not TokenOk then
        TokenOk := (Trim(AuthHeader) = FToken);
      // 3. Fallback: ?token= im URL-Query-String
      if not TokenOk then
        TokenOk := (QueryToken = FToken);
      if not TokenOk then
      begin
        AContext.Connection.IOHandler.Write(
          'HTTP/1.1 401 Unauthorized'#13#10 +
          'Content-Length: 0'#13#10 +
          'Connection: close'#13#10 +
          #13#10);
        DoLog('Handshake: Token ungültig – Verbindung abgelehnt');
        Exit;
      end;
    end;

    Resp :=
      'HTTP/1.1 101 Switching Protocols'#13#10 +
      'Upgrade: websocket'#13#10 +
      'Connection: Upgrade'#13#10 +
      'Sec-WebSocket-Accept: ' + CalcWSAccept(WsKey) + #13#10 +
      #13#10;

    AContext.Connection.IOHandler.Write(Resp);
    Result := True;
    DoLog('WebSocket-Handshake erfolgreich');
  except
    on E: Exception do
      DoLog('Handshake-Fehler: ' + E.Message);
  end;
end;

{ ---- Frame-Lesen (RFC 6455) ----------------------------------------------- }

function TWebSocketServer.ReadFrame(AContext: TIdContext;
  out OpCode: Byte; out Data: TIdBytes): Boolean;
var
  Header     : TIdBytes;
  PayloadLen : Int64;
  Masked     : Boolean;
  MaskKey    : TIdBytes;
  I          : Integer;
begin
  Result  := False;
  OpCode  := 0;
  SetLength(Data, 0);

  try
    // 2 Header-Bytes
    SetLength(Header, 0);
    AContext.Connection.IOHandler.ReadBytes(Header, 2, False);

    // FIN := (Header[0] and $80) <> 0  -- wir behandeln immer als vollstaendig
    OpCode  := Header[0] and $0F;
    Masked  := (Header[1] and $80) <> 0;
    PayloadLen := Header[1] and $7F;

    if PayloadLen = 126 then
    begin
      SetLength(Header, 0);
      AContext.Connection.IOHandler.ReadBytes(Header, 2, False);
      PayloadLen := (Int64(Header[0]) shl 8) or Header[1];
    end
    else if PayloadLen = 127 then
    begin
      SetLength(Header, 0);
      AContext.Connection.IOHandler.ReadBytes(Header, 8, False);
      PayloadLen := 0;
      for I := 0 to 7 do
        PayloadLen := (PayloadLen shl 8) or Header[I];
    end;

    // Masking-Key (Client -> Server ist immer maskiert)
    if Masked then
    begin
      SetLength(MaskKey, 0);
      AContext.Connection.IOHandler.ReadBytes(MaskKey, 4, False);
    end;

    // Payload
    SetLength(Data, 0);
    if PayloadLen > 0 then
      AContext.Connection.IOHandler.ReadBytes(Data, PayloadLen, False);

    // Demaskieren
    if Masked then
      for I := 0 to Length(Data) - 1 do
        Data[I] := Data[I] xor MaskKey[I mod 4];

    Result := True;

  except
    on E: EIdReadTimeout do
      ; // Normaler Timeout - kein Fehler, nur kein Daten
    on E: Exception do
      DoLog('ReadFrame-Fehler: ' + E.Message);
  end;
end;

{ ---- Frame-Schreiben (RFC 6455, Server->Client nie maskiert) -------------- }

procedure TWebSocketServer.WriteFrame(AContext: TIdContext;
  OpCode: Byte; const Data: TIdBytes);
var
  Frame   : TIdBytes;
  PayLen  : Integer;
  Ctx     : TWebSocketClientCtx;
begin
  Ctx    := AContext as TWebSocketClientCtx;
  PayLen := Length(Data);

  if PayLen <= 125 then
  begin
    SetLength(Frame, 2 + PayLen);
    Frame[0] := $80 or OpCode;
    Frame[1] := Byte(PayLen);
  end
  else
  begin
    SetLength(Frame, 4 + PayLen);
    Frame[0] := $80 or OpCode;
    Frame[1] := 126;
    Frame[2] := (PayLen shr 8) and $FF;
    Frame[3] := PayLen and $FF;
  end;

  if PayLen > 0 then
    Move(Data[0], Frame[Length(Frame) - PayLen], PayLen);

  Ctx.WriteLock.Enter;
  try
    AContext.Connection.IOHandler.Write(Frame);
  finally
    Ctx.WriteLock.Leave;
  end;
end;

procedure TWebSocketServer.WriteCloseFrame(AContext: TIdContext);
var
  Empty: TIdBytes;
begin
  SetLength(Empty, 0);
  try
    WriteFrame(AContext, $08, Empty);
  except
  end;
end;

procedure TWebSocketServer.WritePongFrame(AContext: TIdContext;
  const Data: TIdBytes);
begin
  try
    WriteFrame(AContext, $0A, Data);
  except
  end;
end;

{ ---- Hilfsfunktionen ------------------------------------------------------ }

class function TWebSocketServer.CalcWSAccept(const Key: string): string;
const
  MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
var
  HashBytes: TBytes;
begin
  HashBytes := THashSHA1.GetHashBytes(Key + MAGIC);
  Result    := Trim(TNetEncoding.Base64.EncodeBytesToString(HashBytes));
end;

procedure TWebSocketServer.DoLog(const Msg: string);
begin
  if Assigned(FOnLog) then
    TThread.Queue(nil, procedure
      begin
        FOnLog(Msg);
      end);
end;

end.
