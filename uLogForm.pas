unit uLogForm;
{
  PiShock Seriell-Controller - Log-Fenster
  Separates, nicht-modales Fenster fuer Statusmeldungen.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  uLanguage;

type
  TLogForm = class(TForm)
    mmoLog    : TMemo;
    pnlBottom : TPanel;
    btnClear  : TButton;
    procedure btnClearClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  public
    procedure AddLine(const Msg: string);
    procedure ApplyLanguage;
  end;

var
  LogForm: TLogForm;

implementation

{$R *.dfm}

procedure TLogForm.AddLine(const Msg: string);
begin
  mmoLog.Lines.Add(Msg);
  if mmoLog.Lines.Count > 2000 then
    mmoLog.Lines.Delete(0);
  SendMessage(mmoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TLogForm.btnClearClick(Sender: TObject);
begin
  mmoLog.Lines.Clear;
end;

procedure TLogForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;  // Nur verstecken, nicht freigeben
end;

procedure TLogForm.ApplyLanguage;
begin
  Caption          := LS.LogFormCaption;
  btnClear.Caption := LS.BtnClearLog;
end;

end.
