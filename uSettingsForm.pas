unit uSettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uLanguage;

type
  TSettingsForm = class(TForm)
    grpWs         : TGroupBox;
    lblWsPort     : TLabel;
    lblWsToken    : TLabel;
    edtWsPort     : TEdit;
    edtWsToken    : TEdit;
    grpHds        : TGroupBox;
    lblHdsPort    : TLabel;
    edtHdsPort    : TEdit;
    grpHotkey     : TGroupBox;
    lblHotkeyHint : TLabel;
    hotKey1       : THotKey;
    grpLanguage   : TGroupBox;
    lblLanguage   : TLabel;
    cmbLanguage   : TComboBox;
    pnlButtons    : TPanel;
    btnOK         : TButton;
    btnCancel     : TButton;

    procedure FormCreate(Sender: TObject);
  private
    procedure ApplyLanguage;
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.dfm}

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  cmbLanguage.Items.Clear;
  cmbLanguage.Items.Add('English');
  cmbLanguage.Items.Add('Deutsch');
  cmbLanguage.ItemIndex := Ord(AppLang);
  ApplyLanguage;
end;

procedure TSettingsForm.ApplyLanguage;
begin
  Caption               := LS.SettingsCaption;
  grpHotkey.Caption     := LS.GrpHotkey;
  lblHotkeyHint.Caption := LS.LblHotkeyKey;
  lblLanguage.Caption   := LS.LblLanguage;
  btnCancel.Caption     := LS.BtnCancel;
end;

end.
