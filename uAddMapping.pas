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
  System.StrUtils,
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
    cmbModule     : TComboBox;
    spnIndex      : TSpinEdit;
    // Intensitaet
    lblIntensity  : TLabel;
    spnIntensity  : TSpinEdit;
    lblIntPct     : TLabel;
    // Dauer
    lblDuration   : TLabel;
    spnDuration   : TSpinEdit;
    lblDurMs      : TLabel;

    // Optionale HDS-Abhaengigkeit
    chkHdsRequired: TCheckBox;
    lblHdsType    : TLabel;
    cmbHdsType    : TComboBox;
    lblHdsCond    : TLabel;
    cmbHdsCond    : TComboBox;
    lblHdsThresh  : TLabel;
    edtHdsThresh  : TEdit;
    // Buttons
    pnlButtons    : TPanel;
    btnOK         : TButton;
    btnCancel     : TButton;

    procedure FormCreate(Sender: TObject);
    procedure cmbOperationChange(Sender: TObject);
    procedure cmbTargetChange(Sender: TObject);
    procedure chkHdsRequiredClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FModuleChoices  : TStringList;
    FMaxShockerIndex: Integer;
    procedure SetMaxShockerIndex(const Value: Integer);
    procedure RebuildModuleChoices;
    procedure UpdateControlStates;
    procedure ApplyLanguage;
  public
    destructor Destroy; override;

    /// <summary>
    ///   Anzahl bekannter Module setzen - begrenzt den Modul-Spinner.
    ///   0 = noch unbekannt (Spinner geht bis 99).
    /// </summary>
    property MaxShockerIndex: Integer
      read FMaxShockerIndex write SetMaxShockerIndex;

    /// <summary>Optionale Modulnamen fuer die Auswahl setzen</summary>
    procedure SetModuleChoices(Choices: TStrings);

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
var
  I: Integer;
begin
  FModuleChoices := TStringList.Create;
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
  spnIndex.Visible  := False;
  spnIndex.TabStop  := False;

  cmbModule.Style := csDropDownList;

  cmbHdsType.Style := csDropDownList;
  cmbHdsType.Items.Clear;
  cmbHdsType.Items.AddStrings([
    'heartRate', 'calories', 'stepCount', 'distanceTraveled',
    'speed', 'oxygenSaturation', 'bodyMass', 'bmi'
  ]);
  cmbHdsType.ItemIndex := 0;

  cmbHdsCond.Style := csDropDownList;
  cmbHdsCond.Items.Clear;
  for I := 0 to Ord(High(THdsGateCondition)) do
    cmbHdsCond.Items.Add('');
  cmbHdsCond.ItemIndex := 0;

  chkHdsRequired.Checked := False;
  edtHdsThresh.Text := '120';

  ApplyLanguage;
  RebuildModuleChoices;
  UpdateControlStates;
end;

procedure TAddMappingForm.SetMaxShockerIndex(const Value: Integer);
begin
  FMaxShockerIndex := Value;
  if FMaxShockerIndex > 0 then
    spnIndex.MaxValue := FMaxShockerIndex;
  RebuildModuleChoices;
end;

procedure TAddMappingForm.SetModuleChoices(Choices: TStrings);
begin
  FModuleChoices.Clear;
  if Assigned(Choices) then
    FModuleChoices.AddStrings(Choices);
  RebuildModuleChoices;
end;

procedure TAddMappingForm.RebuildModuleChoices;
var
  I: Integer;
  PrevIdx: Integer;
begin
  PrevIdx := cmbModule.ItemIndex;
  cmbModule.Items.Clear;

  if FModuleChoices.Count > 0 then
    cmbModule.Items.AddStrings(FModuleChoices)
  else if FMaxShockerIndex > 0 then
    for I := 1 to FMaxShockerIndex do
      cmbModule.Items.Add('Module ' + IntToStr(I))
  else
    cmbModule.Items.Add('Module 1');

  if (PrevIdx >= 0) and (PrevIdx < cmbModule.Items.Count) then
    cmbModule.ItemIndex := PrevIdx
  else
    cmbModule.ItemIndex := 0;

  spnIndex.Value := cmbModule.ItemIndex + 1;
end;

procedure TAddMappingForm.ApplyLanguage;
var
  SelOp, SelTgt, SelCond: Integer;
begin
  Caption              := LS.AddMappingCaption;
  lblTrigger.Caption   := LS.LblTriggerStr;
  lblOperation.Caption := LS.LblOperation;
  lblTarget.Caption    := LS.LblTarget;
  lblIndex.Caption     := LS.LblModuleNo;
  lblIntensity.Caption := LS.LblIntensity;
  lblDuration.Caption  := LS.LblDuration;
  btnCancel.Caption    := LS.BtnCancel;
  chkHdsRequired.Caption := LS.LblHdsRequired;
  lblHdsType.Caption   := LS.LblDataType;
  lblHdsCond.Caption   := LS.LblCondition;
  lblHdsThresh.Caption := LS.LblThreshold;

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

  SelCond := cmbHdsCond.ItemIndex;
  cmbHdsCond.Items.Clear;
  cmbHdsCond.Items.AddStrings([LS.CmbCondGT, LS.CmbCondGE, LS.CmbCondLT, LS.CmbCondLE]);
  if SelCond >= 0 then cmbHdsCond.ItemIndex := SelCond
  else cmbHdsCond.ItemIndex := 0;

  RebuildModuleChoices;
end;

procedure TAddMappingForm.chkHdsRequiredClick(Sender: TObject);
begin
  UpdateControlStates;
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
  cmbModule.Enabled := IsSpecific;
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

  lblHdsType.Enabled   := chkHdsRequired.Checked;
  cmbHdsType.Enabled   := chkHdsRequired.Checked;
  lblHdsCond.Enabled   := chkHdsRequired.Checked;
  cmbHdsCond.Enabled   := chkHdsRequired.Checked;
  lblHdsThresh.Enabled := chkHdsRequired.Checked;
  edtHdsThresh.Enabled := chkHdsRequired.Checked;
end;

procedure TAddMappingForm.LoadFromMapping(M: TCommandMapping);
begin
  if M = nil then
    Exit;
  edtTrigger.Text        := M.TriggerString;
  cmbOperation.ItemIndex := Ord(M.OpType);
  cmbTarget.ItemIndex    := Ord(M.TargetType);
  if (M.ShockerIndex >= 0) and (M.ShockerIndex < cmbModule.Items.Count) then
    cmbModule.ItemIndex := M.ShockerIndex
  else
    cmbModule.ItemIndex := 0;
  spnIndex.Value         := cmbModule.ItemIndex + 1;
  spnIntensity.Value     := M.Intensity;
  spnDuration.Value      := M.Duration;
  chkHdsRequired.Checked := M.HdsRequired;

  if cmbHdsType.Items.Count > 0 then
  begin
    var HdsIdx := cmbHdsType.Items.IndexOf(M.HdsDataTypeKey);
    if HdsIdx >= 0 then
      cmbHdsType.ItemIndex := HdsIdx
    else
      cmbHdsType.ItemIndex := 0;
  end;

  cmbHdsCond.ItemIndex   := Ord(M.HdsCondition);
  edtHdsThresh.Text      := StringReplace(Format('%.6g', [M.HdsThreshold]), ',', '.', []);
  UpdateControlStates;
end;

procedure TAddMappingForm.btnOKClick(Sender: TObject);
var
  FS: TFormatSettings;
  V: Double;
begin
  if Trim(edtTrigger.Text) = '' then
  begin
    ShowMessage(LS.MsgEnterTrigger);
    edtTrigger.SetFocus;
    Exit;
  end;

  if chkHdsRequired.Checked then
  begin
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := '.';
    if not TryStrToFloat(StringReplace(Trim(edtHdsThresh.Text), ',', '.', []), V, FS) then
    begin
      ShowMessage(LS.MsgInvalidThreshold);
      edtHdsThresh.SetFocus;
      Exit;
    end;
  end;

  ModalResult := mrOk;
end;

function TAddMappingForm.GetMapping: TCommandMapping;
begin
  var FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  Result := TCommandMapping.Create;
  Result.TriggerString := Trim(edtTrigger.Text);
  Result.OpType        := TOpType(cmbOperation.ItemIndex);
  Result.TargetType    := TTargetType(cmbTarget.ItemIndex);
  if cmbModule.ItemIndex >= 0 then
    Result.ShockerIndex := cmbModule.ItemIndex
  else
    Result.ShockerIndex := spnIndex.Value - 1;
  Result.Intensity     := spnIntensity.Value;
  Result.Duration      := spnDuration.Value;

  Result.HdsRequired    := chkHdsRequired.Checked;
  if cmbHdsType.ItemIndex >= 0 then
    Result.HdsDataTypeKey := Trim(cmbHdsType.Items[cmbHdsType.ItemIndex])
  else
    Result.HdsDataTypeKey := 'heartRate';
  Result.HdsCondition   := THdsGateCondition(cmbHdsCond.ItemIndex);
  if not TryStrToFloat(StringReplace(Trim(edtHdsThresh.Text), ',', '.', []),
    Result.HdsThreshold, FS) then
    Result.HdsThreshold := 120.0;
end;

destructor TAddMappingForm.Destroy;
begin
  FModuleChoices.Free;
  inherited;
end;

end.
