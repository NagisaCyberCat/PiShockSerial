program PiShockSerial;

uses
  Vcl.Forms,
  piserial in 'piserial.pas' {Form1},
  uCommandMapping in 'uCommandMapping.pas',
  uPiShockDevice in 'uPiShockDevice.pas',
  uWebSocketServer in 'uWebSocketServer.pas',
  uAddMapping in 'uAddMapping.pas' {AddMappingForm},
  uLogForm in 'uLogForm.pas' {LogForm},
  uHdsTrigger in 'uHdsTrigger.pas',
  uHdsHttpServer in 'uHdsHttpServer.pas',
  uAddHdsTrigger in 'uAddHdsTrigger.pas' {AddHdsTriggerForm},
  uHdsForm in 'uHdsForm.pas' {HdsForm},
  uSettingsForm in 'uSettingsForm.pas' {SettingsForm},
  uLanguage in 'uLanguage.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  // LogForm und HdsForm zuerst erzeugen, damit sie in Form1.FormCreate verfuegbar sind
  LogForm := TLogForm.Create(Application);
  HdsForm := THdsForm.Create(Application);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
