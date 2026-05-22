unit uAddMapping;
{
  Dialog zum Hinzufuegen und Bearbeiten von Befehlszuordnungen.
  Verwendung:
    Dlg := TAddMappingForm.Create(Owner);
    try
      Dlg.MaxShockerIndex := Length(Device.DeviceInfo.Shockers); // 0 = beliebig
      Dlg.LoadFromMapping(ExistingMapping);  // optional bei Bearbeitung
      if Dlg.ShowModal = mrOk then
        NewMapping := Dlg.GetMapping;  // Aufrufer ist Eigentümer
    finally
      Dlg.Free;
    end;
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin,
  uCommandMapping, uLanguage;

type
  TAddMappingForm = class(TForm)
    // Trigger
    lblTrigger    : TLabel;
    edtTrigger    : TEdit;
    // Operation
    lblOperation  : TLabel;
    cmbOperation  : TComboBox;
    // Ziel
    lblTarget     : TLabel;
    cmbTarget     : TComboBox;
    // Modul-Index
    lblIndex      : TLabel;
    spnIndex      : TSpinEdit;
    // Intensitaet
    lblIntensity  : TLabel;
    spnIntensity  : TSpinEdit;
    lblIntPct     : TLabel;
    // Dauer
    lblDuration   : TLabel;
    spnDuration   : TSpinEdit;
    lblDurMs      : TLabel;
    // Buttons
    pnlButtons    : TPanel;
    btnOK         : TButton;
    btnCancel     : TButton;

    procedure FormCreate(Sender: TObject);
    procedure cmbOperationChange(Sender: TObject);
    procedure cmbTargetChange(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FMaxShockerIndex: Integer;
    procedure UpdateControlStates;
    procedure ApplyLanguage;
  public
    /// <summary>
    ///   Anzahl bekannter Module setzen - begrenzt den Modul-Spinner.
    ///   0 = noch unbekannt (Spinner geht bis 99).
    /// </summary>
    property MaxShockerIndex: Integer
      read FMaxShockerIndex write FMaxShockerIndex;

    /// <summary>Vorhandene Zuordnung zum Bearbeiten laden</summary>
    procedure LoadFromMapping(M: TCommandMapping);

    /// <summary>
    ///   Neue TCommandMapping-Instanz mit den aktuellen Formularwerten erstellen.
    ///   Aufrufer ist fuer die Freigabe verantwortlich.
    /// </summary>
    function GetMapping: TCommandMapping;
  end;

implementation

{$R *.dfm}

procedure TAddMappingForm.FormCreate(Sender: TObject);
begin
  FMaxShockerIndex := 0;

  // Combobox-Eintraege (werden durch ApplyLanguage gesetzt)
  cmbOperation.Items.Clear;
  cmbOperation.ItemIndex := 0;

  cmbTarget.Items.Clear;
  cmbTarget.ItemIndex := 0;

  // Spinner-Grenzen
  spnIntensity.MinValue := 0;
  spnIntensity.MaxValue := 100;
  spnIntensity.Value    := 50;

  spnDuration.MinValue := 50;
  spnDuration.MaxValue := 30000;
  spnDuration.Value    := 1000;

  spnIndex.MinValue := 1;
  spnIndex.MaxValue := 99;
  spnIndex.Value    := 1;

  ApplyLanguage;
  UpdateControlStates;
end;

procedure TAddMappingForm.ApplyLanguage;
var
  SelOp, SelTgt: Integer;
begin
  Caption              := LS.AddMappingCaption;
  lblTrigger.Caption   := LS.LblTriggerStr;
  lblOperation.Caption := LS.LblOperation;
  lblTarget.Caption    := LS.LblTarget;
  lblIndex.Caption     := LS.LblModuleNo;
  lblIntensity.Caption := LS.LblIntensity;
  lblDuration.Caption  := LS.LblDuration;
  btnCancel.Caption    := LS.BtnCancel;

  SelOp  := cmbOperation.ItemIndex;
  SelTgt := cmbTarget.ItemIndex;

  cmbOperation.Items.Clear;
  cmbOperation.Items.AddStrings([LS.CmbOpShock, LS.CmbOpVibrate, LS.CmbOpBeep, LS.CmbOpStop]);
  if SelOp >= 0 then cmbOperation.ItemIndex := SelOp
  else cmbOperation.ItemIndex := 0;

  cmbTarget.Items.Clear;
  cmbTarget.Items.AddStrings([LS.CmbTgtAll, LS.CmbTgtSpecific, LS.CmbTgtRandom]);
  if SelTgt >= 0 then cmbTarget.ItemIndex := SelTgt
  else cmbTarget.ItemIndex := 0;
end;

procedure TAddMappingForm.cmbOperationChange(Sender: TObject);
begin
  UpdateControlStates;
end;

procedure TAddMappingForm.cmbTargetChange(Sender: TObject);
begin
  UpdateControlStates;
end;

procedure TAddMappingForm.UpdateControlStates;
var
  Op          : TOpType;
  IsSpecific  : Boolean;
  NeedIntens  : Boolean;
  NeedDur     : Boolean;
begin
  Op         := TOpType(cmbOperation.ItemIndex);
  IsSpecific := (cmbTarget.ItemIndex = Ord(ttSpecific));
  NeedIntens := Op in [opShock, opVibrate];
  NeedDur    := Op <> opEnd;

  // Modul-Index: nur bei "Spezifisch"
  lblIndex.Enabled  := IsSpecific;
  spnIndex.Enabled  := IsSpecific;
  if FMaxShockerIndex > 0 then
    spnIndex.MaxValue := FMaxShockerIndex;

  // Intensitaet: nicht fuer Beep und Stop
  lblIntensity.Enabled := NeedIntens;
  spnIntensity.Enabled := NeedIntens;
  lblIntPct.Enabled    := NeedIntens;

  // Dauer: nicht fuer Stop
  lblDuration.Enabled := NeedDur;
  spnDuration.Enabled := NeedDur;
  lblDurMs.Enabled    := NeedDur;
end;

procedure TAddMappingForm.LoadFromMapping(M: TCommandMapping);
begin
  if M = nil then
    Exit;
  edtTrigger.Text        := M.TriggerString;
  cmbOperation.ItemIndex := Ord(M.OpType);
  cmbTarget.ItemIndex    := Ord(M.TargetType);
  spnIndex.Value         := M.ShockerIndex + 1;
  spnIntensity.Value     := M.Intensity;
  spnDuration.Value      := M.Duration;
  UpdateControlStates;
end;

procedure TAddMappingForm.btnOKClick(Sender: TObject);
begin
  if Trim(edtTrigger.Text) = '' then
  begin
    ShowMessage(LS.MsgEnterTrigger);
    edtTrigger.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

function TAddMappingForm.GetMapping: TCommandMapping;
begin
  Result := TCommandMapping.Create;
  Result.TriggerString := Trim(edtTrigger.Text);
  Result.OpType        := TOpType(cmbOperation.ItemIndex);
  Result.TargetType    := TTargetType(cmbTarget.ItemIndex);
  Result.ShockerIndex  := spnIndex.Value - 1;
  Result.Intensity     := spnIntensity.Value;
  Result.Duration      := spnDuration.Value;
end;

end.
