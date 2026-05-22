unit uHdsHttpServer;
(*
  HTTP-Server fuer HDS (Health Data Server) Apple Watch / Android Watch App.

  Protokoll:
    Watch App sendet HTTP PUT-Requests an Port 3476 (Standard):
    Body (JSON): {"data":"heartRate:75"}
    Datenformat: "dataType:value"  (Schluessel gemaess HDS camelCase-Enum)

  Dieser Server empfaengt PUT-Requests, parst den Body und ruft den
  OnData-Callback sicher im VCL-Hauptthread auf.
*)

interface

uses
  System.SysUtils, System.Classes,
  IdHTTPServer, IdCustomHTTPServer, IdContext;

type
  TOnHdsDataEvent = procedure(const DataType: string; Value: Double) of object;
  TOnHdsLogEvent  = procedure(const Msg: string) of object;

  /// <summary>
  ///   Leichtgewichtiger HTTP-Server, der PUT-Requests von der HDS Watch-App
  ///   entgegennimmt und OnData-Events ausfeuert.
  /// </summary>
  THdsHttpServer = class
  private
    FServer : TIdHTTPServer;
    FPort   : Integer;
    FOnData : TOnHdsDataEvent;
    FOnLog  : TOnHdsLogEvent;

    procedure HandleCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure HandleCommandOther(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);

    procedure ParseAndFire(const ABody: string);
    procedure DoLog(const Msg: string);
    function  GetActive: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Server auf dem angegebenen Port starten</summary>
    procedure Start(APort: Integer);

    /// <summary>Server stoppen</summary>
    procedure Stop;

    property Active : Boolean         read GetActive;
    property Port   : Integer         read FPort;

    /// <summary>Wird im Hauptthread gerufen wenn ein Wert empfangen wurde</summary>
    property OnData : TOnHdsDataEvent read FOnData write FOnData;

    /// <summary>Wird im Hauptthread gerufen fuer Log-Meldungen</summary>
    property OnLog  : TOnHdsLogEvent  read FOnLog  write FOnLog;
  end;

implementation

uses
  System.JSON;

{ THdsHttpServer }

constructor THdsHttpServer.Create;
begin
  inherited Create;
  FServer                := TIdHTTPServer.Create(nil);
  FServer.ParseParams    := False;
  FServer.OnCommandGet   := HandleCommandGet;
  FServer.OnCommandOther := HandleCommandOther;
end;

destructor THdsHttpServer.Destroy;
begin
  Stop;
  FreeAndNil(FServer);
  inherited Destroy;
end;

function THdsHttpServer.GetActive: Boolean;
begin
  Result := FServer.Active;
end;

procedure THdsHttpServer.Start(APort: Integer);
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
  DoLog(Format('HDS-Server gestartet auf Port %d', [APort]));
end;

procedure THdsHttpServer.Stop;
begin
  if FServer.Active then
  begin
    FServer.Active := False;
    DoLog('HDS-Server gestoppt');
  end;
end;

{ ---- HTTP-Handler --------------------------------------------------------- }

procedure THdsHttpServer.HandleCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  AResponseInfo.ResponseNo  := 200;
  AResponseInfo.ContentText := 'PiShock HDS Receiver';
end;

procedure THdsHttpServer.HandleCommandOther(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  Body : string;
  SS   : TStringStream;
begin
  AResponseInfo.ResponseNo  := 200;
  AResponseInfo.ContentText := '';

  if not SameText(ARequestInfo.Command, 'PUT') then
    Exit;

  Body := '';
  try
    // Body aus PostStream lesen (Indy fuellt diesen fuer PUT/POST mit Body)
    if Assigned(ARequestInfo.PostStream) and (ARequestInfo.PostStream.Size > 0) then
    begin
      SS := TStringStream.Create('', TEncoding.UTF8);
      try
        ARequestInfo.PostStream.Position := 0;
        SS.CopyFrom(ARequestInfo.PostStream, 0);
        Body := SS.DataString;
      finally
        SS.Free;
      end;
    end;

    if Body <> '' then
      ParseAndFire(Body);

  except
    on E: Exception do
      DoLog('[HDS] HTTP-Fehler: ' + E.Message);
  end;
end;

procedure THdsHttpServer.ParseAndFire(const ABody: string);
var
  JVal     : TJSONValue;
  DataStr  : string;
  Parts    : TArray<string>;
  DblVal   : Double;
  DataType : string;
  FS       : TFormatSettings;
begin
  try
    JVal := TJSONObject.ParseJSONValue(ABody);
    if JVal = nil then
    begin
      DoLog('[HDS] Ungueltiges JSON empfangen');
      Exit;
    end;
    try
      DataStr := JVal.GetValue<string>('data', '');
    finally
      JVal.Free;
    end;

    if DataStr = '' then
      Exit;

    // Format: "heartRate:75" -> Parts[0]="heartRate", Parts[1]="75"
    Parts := DataStr.Split([':'], 2);
    if Length(Parts) < 2 then
      Exit;

    DataType := Parts[0];

    // Immer englische Punkt-Notation (wie von HDS gesendet)
    FS := TFormatSettings.Create('en-US');
    if not TryStrToFloat(Parts[1], DblVal, FS) then
      DblVal := 0;

    if Assigned(FOnData) then
      TThread.Synchronize(nil, procedure
        begin
          FOnData(DataType, DblVal);
        end);

  except
    on E: Exception do
      DoLog('[HDS] Parse-Fehler: ' + E.Message);
  end;
end;

procedure THdsHttpServer.DoLog(const Msg: string);
begin
  if Assigned(FOnLog) then
    TThread.Queue(nil, procedure
      begin
        FOnLog(Msg);
      end);
end;

end.
