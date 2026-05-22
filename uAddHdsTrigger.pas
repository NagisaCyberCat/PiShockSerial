unit uAddHdsTrigger;
{
  Dialog zum Hinzufuegen und Bearbeiten von HDS-Triggern.
  Verwendung:
    Dlg := TAddHdsTriggerForm.Create(Owner);
    try
      Dlg.MaxShockerIndex := Length(Device.DeviceInfo.Shockers);
      Dlg.LoadFromTrigger(Existing);  // optional bei Bearbeitung
      if Dlg.ShowModal = mrOk then
        NewTrigger := Dlg.GetTrigger;  // Aufrufer ist Eigentuemer
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
  uHdsTrigger, uCommandMapping, uLanguage;

type
  TAddHdsTriggerForm = class(TForm)
    // HDS-Trigger-Felder
    lblDataType   : TLabel;
    cmbDataType   : TComboBox;
    lblCondition  : TLabel;
    cmbCondition  : TComboBox;
    lblThreshold  : TLabel;
    edtThreshold  : TEdit;
    lblCooldown   : TLabel;
    spnCooldown   : TSpinEdit;
    lblCooldownS  : TLabel;

    // Trennlinie
    lblActionSep  : TLabel;
    bvlSep        : TBevel;

    // Aktion-Felder
    lblOperation  : TLabel;
    cmbOperation  : TComboBox;
    lblTarget     : TLabel;
    cmbTarget     : TComboBox;
    lblIndex      : TLabel;
    cmbModule     : TComboBox;
    spnIndex      : TSpinEdit;
    lblIntensity  : TLabel;
    spnIntensity  : TSpinEdit;
    lblIntPct     : TLabel;
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
    FModuleChoices  : TStringList;
    FMaxShockerIndex: Integer;
    procedure SetMaxShockerIndex(const Value: Integer);
    procedure RebuildModuleChoices;
    procedure UpdateControlStates;
    procedure ApplyLanguage;
  public
    property MaxShockerIndex: Integer
      read FMaxShockerIndex write SetMaxShockerIndex;

    destructor Destroy; override;

    /// <summary>Optionale Modulnamen fuer die Auswahl setzen</summary>
    procedure SetModuleChoices(Choices: TStrings);

    /// <summary>Vorhandenen Trigger zum Bearbeiten laden</summary>
    procedure LoadFromTrigger(T: THdsTrigger);

    /// <summary>
    ///   Neue THdsTrigger-Instanz mit den aktuellen Formularwerten erstellen.
    ///   Aufrufer ist fuer die Freigabe verantwortlich.
    /// </summary>
    function GetTrigger: THdsTrigger;
  end;

implementation

{$R *.dfm}

procedure TAddHdsTriggerForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FModuleChoices := TStringList.Create;
  FMaxShockerIndex := 0;

  // Datentyp-Combobox
  cmbDataType.Items.Clear;
  for I := 0 to HdsDataTypeCount - 1 do
    cmbDataType.Items.Add(HdsDataTypeLabel[I]);
  cmbDataType.ItemIndex := 0;

  // Spinner-Grenzen
  spnCooldown.MinValue  := 0;
  spnCooldown.MaxValue  := 3600;
  spnCooldown.Value     := 30;

  spnIntensity.MinValue := 0;
  spnIntensity.MaxValue := 100;
  spnIntensity.Value    := 50;

  spnDuration.MinValue  := 50;
  spnDuration.MaxValue  := 30000;
  spnDuration.Value     := 1000;

  spnIndex.MinValue     := 1;
  spnIndex.MaxValue     := 1;
  spnIndex.Value        := 1;
  spnIndex.Visible      := False;
  spnIndex.TabStop      := False;

  cmbModule.Style       := csDropDownList;

  edtThreshold.Text := '120';

  ApplyLanguage;
  RebuildModuleChoices;
  UpdateControlStates;
end;

procedure TAddHdsTriggerForm.SetMaxShockerIndex(const Value: Integer);
begin
  FMaxShockerIndex := Value;
  RebuildModuleChoices;
end;

procedure TAddHdsTriggerForm.SetModuleChoices(Choices: TStrings);
begin
  FModuleChoices.Clear;
  if Assigned(Choices) then
    FModuleChoices.AddStrings(Choices);
  RebuildModuleChoices;
end;

procedure TAddHdsTriggerForm.RebuildModuleChoices;
var
  I: Integer;
  PrevIdx: Integer;
  MaxIdx: Integer;
begin
  PrevIdx := cmbModule.ItemIndex;
  cmbModule.Items.Clear;

  if FModuleChoices.Count > 0 then
    cmbModule.Items.AddStrings(FModuleChoices)
  else
  begin
    if FMaxShockerIndex > 0 then
      MaxIdx := FMaxShockerIndex
    else
      MaxIdx := 99;

    for I := 1 to MaxIdx do
      cmbModule.Items.Add('Module ' + IntToStr(I));
  end;

  if (PrevIdx >= 0) and (PrevIdx < cmbModule.Items.Count) then
    cmbModule.ItemIndex := PrevIdx
  else if cmbModule.Items.Count > 0 then
    cmbModule.ItemIndex := 0;

  if cmbModule.ItemIndex >= 0 then
    spnIndex.Value := cmbModule.ItemIndex + 1;
end;

procedure TAddHdsTriggerForm.ApplyLanguage;
var
  SelCond, SelOp, SelTgt: Integer;
begin
  Caption               := LS.AddHdsTriggerCaption;
  lblDataType.Caption   := LS.LblDataType;
  lblCondition.Caption  := LS.LblCondition;
  lblThreshold.Caption  := LS.LblThreshold;
  lblCooldown.Caption   := LS.LblCooldown;
  lblActionSep.Caption  := LS.LblActionSep;
  lblOperation.Caption  := LS.LblOperation;
  lblTarget.Caption     := LS.LblTarget;
  lblIndex.Caption      := LS.LblModuleNo;
  lblIntensity.Caption  := LS.LblIntensity;
  lblDuration.Caption   := LS.LblDuration;
  btnCancel.Caption     := LS.BtnCancel;

  SelCond := cmbCondition.ItemIndex;
  cmbCondition.Items.Clear;
  cmbCondition.Items.AddStrings([LS.CmbCondGT, LS.CmbCondGE, LS.CmbCondLT, LS.CmbCondLE]);
  if SelCond >= 0 then cmbCondition.ItemIndex := SelCond
  else cmbCondition.ItemIndex := 0;

  SelOp := cmbOperation.ItemIndex;
  cmbOperation.Items.Clear;
  cmbOperation.Items.AddStrings([LS.CmbOpShock, LS.CmbOpVibrate, LS.CmbOpBeep, LS.CmbOpStop]);
  if SelOp >= 0 then cmbOperation.ItemIndex := SelOp
  else cmbOperation.ItemIndex := 1;  // Vibrate as default for HDS

  SelTgt := cmbTarget.ItemIndex;
  cmbTarget.Items.Clear;
  cmbTarget.Items.AddStrings([LS.CmbTgtAll, LS.CmbTgtSpecific, LS.CmbTgtRandom]);
  if SelTgt >= 0 then cmbTarget.ItemIndex := SelTgt
  else cmbTarget.ItemIndex := 0;

  RebuildModuleChoices;
end;

procedure TAddHdsTriggerForm.UpdateControlStates;
var
  Op      : TOpType;
  IsSpec  : Boolean;
  MaxIdx  : Integer;
begin
  Op     := TOpType(cmbOperation.ItemIndex);
  IsSpec := cmbTarget.ItemIndex = 1;  // ttSpecific

  // Intensitaet nur fuer Schock und Vibration
  spnIntensity.Enabled := Op in [opShock, opVibrate];
  lblIntensity.Enabled := spnIntensity.Enabled;
  lblIntPct.Enabled    := spnIntensity.Enabled;

  // Dauer fuer alles ausser Stop
  spnDuration.Enabled  := Op <> opEnd;
  lblDuration.Enabled  := spnDuration.Enabled;
  lblDurMs.Enabled     := spnDuration.Enabled;

  // Modul-Index nur fuer "Spezifisch"
  cmbModule.Enabled    := IsSpec;
  lblIndex.Enabled     := IsSpec;

  // Modul-Spinner begrenzen
  if FMaxShockerIndex > 0 then
    MaxIdx := FMaxShockerIndex
  else
    MaxIdx := 99;
  spnIndex.MaxValue := MaxIdx;
  if spnIndex.Value > MaxIdx then
    spnIndex.Value := MaxIdx;

  if cmbModule.ItemIndex < 0 then
    cmbModule.ItemIndex := 0;
end;

procedure TAddHdsTriggerForm.cmbOperationChange(Sender: TObject);
begin
  UpdateControlStates;
end;

procedure TAddHdsTriggerForm.cmbTargetChange(Sender: TObject);
begin
  UpdateControlStates;
end;

procedure TAddHdsTriggerForm.btnOKClick(Sender: TObject);
var
  V: Double;
  FS: TFormatSettings;
begin
  // Schwellwert validieren: Komma und Punkt akzeptieren
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  if not TryStrToFloat(StringReplace(Trim(edtThreshold.Text), ',', '.', []), V, FS) then
  begin
    ShowMessage(LS.MsgInvalidThreshold);
    edtThreshold.SetFocus;
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TAddHdsTriggerForm.LoadFromTrigger(T: THdsTrigger);
var
  I: Integer;
begin
  // Datentyp
  cmbDataType.ItemIndex := 0;
  for I := 0 to HdsDataTypeCount - 1 do
    if SameText(HdsDataTypeKey[I], T.DataTypeKey) then
    begin
      cmbDataType.ItemIndex := I;
      Break;
    end;

  // Bedingung
  cmbCondition.ItemIndex := Ord(T.Condition);

  // Schwellwert (immer mit Punkt als Dezimaltrenner im Edit)
  edtThreshold.Text := StringReplace(
    Format('%.6g', [T.Threshold]), ',', '.', []);

  spnCooldown.Value     := T.CooldownSec;
  cmbOperation.ItemIndex := Ord(T.OpType);
  cmbTarget.ItemIndex   := Ord(T.TargetType);
  if (T.ShockerIndex >= 0) and (T.ShockerIndex < cmbModule.Items.Count) then
    cmbModule.ItemIndex := T.ShockerIndex
  else
    cmbModule.ItemIndex := 0;
  spnIndex.Value        := cmbModule.ItemIndex + 1;
  spnIntensity.Value    := T.Intensity;
  spnDuration.Value     := T.Duration;

  UpdateControlStates;
end;

function TAddHdsTriggerForm.GetTrigger: THdsTrigger;
var
  FS: TFormatSettings;
begin
  Result := THdsTrigger.Create;

  if cmbDataType.ItemIndex >= 0 then
    Result.DataTypeKey := HdsDataTypeKey[cmbDataType.ItemIndex]
  else
    Result.DataTypeKey := 'heartRate';

  Result.Condition   := THdsCondition(cmbCondition.ItemIndex);

  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  TryStrToFloat(StringReplace(Trim(edtThreshold.Text), ',', '.', []),
    Result.Threshold, FS);

  Result.CooldownSec   := spnCooldown.Value;
  Result.OpType        := TOpType(cmbOperation.ItemIndex);
  Result.TargetType    := TTargetType(cmbTarget.ItemIndex);
  if cmbModule.ItemIndex >= 0 then
    Result.ShockerIndex := cmbModule.ItemIndex
  else
    Result.ShockerIndex := spnIndex.Value - 1;
  Result.Intensity     := spnIntensity.Value;
  Result.Duration      := spnDuration.Value;
end;

destructor TAddHdsTriggerForm.Destroy;
begin
  FModuleChoices.Free;
  inherited;
end;

end.
