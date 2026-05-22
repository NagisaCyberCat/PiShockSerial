unit uHdsForm;
{
  Modales Verwaltungsfenster fuer HDS-Trigger.
  Wird vom Hauptformular geoeffnet (aehnlich wie uLogForm).
  Zeigt die Liste der konfigurierten Trigger und erlaubt
  Hinzufuegen, Bearbeiten und Loeschen.
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uHdsTrigger, uAddHdsTrigger, uLanguage;

type
  THdsSaveProc = reference to procedure;

  THdsForm = class(TForm)
    grpTrigger   : TGroupBox;
    lvTriggers   : TListView;
    pnlBtns      : TPanel;
    btnAddHds    : TButton;
    btnEditHds   : TButton;
    btnDelHds    : TButton;
    lblHint      : TLabel;

    procedure FormCreate(Sender: TObject);
    procedure btnAddHdsClick(Sender: TObject);
    procedure btnEditHdsClick(Sender: TObject);
    procedure btnDelHdsClick(Sender: TObject);
    procedure lvTriggersSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lvTriggersDblClick(Sender: TObject);

  private
    FTriggerList     : THdsTriggerList;
    FOnSave          : THdsSaveProc;
    FMaxShockerIndex : Integer;

    procedure UpdateButtons;
    function  SelectedTrigger: THdsTrigger;

  public
    /// <summary>
    ///   Trigger-Liste und Save-Callback setzen (wird von Hauptformular aufgerufen).
    ///   TriggerList: gemeinsame Liste, Eigentuemer bleibt das Hauptformular.
    ///   OnSave: wird nach jeder Aenderung aufgerufen (z.B. SaveSettings).
    /// </summary>
    procedure Setup(ATriggerList: THdsTriggerList;
      AOnSave: THdsSaveProc;
      AMaxShockerIndex: Integer = 0);

    /// <summary>ListView aus der Trigger-Liste neu aufbauen</summary>
    procedure RefreshList;

    /// <summary>Anzahl bekannter Module aktualisieren (fuer Dialog-Spinner)</summary>
    procedure UpdateMaxShockerIndex(AMax: Integer);

    /// <summary>Alle Beschriftungen auf aktuelle Sprache umstellen</summary>
    procedure ApplyLanguage;
  end;

var
  HdsForm: THdsForm;

implementation

{$R *.dfm}

procedure THdsForm.FormCreate(Sender: TObject);
begin
  // ListView-Spalten anlegen
  with lvTriggers.Columns.Add do begin Caption := 'Data type';  Width := 115; end;
  with lvTriggers.Columns.Add do begin Caption := 'Condition';  Width := 90;  end;
  with lvTriggers.Columns.Add do begin Caption := 'Action';     Width := 160; end;
  with lvTriggers.Columns.Add do begin Caption := 'Cooldown';   Width := 70;  end;

  ApplyLanguage;
  UpdateButtons;
end;

procedure THdsForm.ApplyLanguage;
begin
  Caption            := LS.HdsFormCaption;
  grpTrigger.Caption := LS.GrpHdsTrigger;
  btnAddHds.Caption  := LS.BtnAddHds;
  btnEditHds.Caption := LS.BtnEditHds;
  btnDelHds.Caption  := LS.BtnDelHds;
  lblHint.Caption    := LS.LblHdsTip;
  if lvTriggers.Columns.Count >= 4 then
  begin
    lvTriggers.Columns[0].Caption := LS.ColDataType;
    lvTriggers.Columns[1].Caption := LS.ColCondition;
    lvTriggers.Columns[2].Caption := LS.ColAction;
    lvTriggers.Columns[3].Caption := LS.ColCooldown;
  end;
end;

procedure THdsForm.Setup(ATriggerList: THdsTriggerList;
  AOnSave: THdsSaveProc; AMaxShockerIndex: Integer);
begin
  FTriggerList     := ATriggerList;
  FOnSave          := AOnSave;
  FMaxShockerIndex := AMaxShockerIndex;
  RefreshList;
end;

procedure THdsForm.UpdateMaxShockerIndex(AMax: Integer);
begin
  FMaxShockerIndex := AMax;
end;

procedure THdsForm.RefreshList;
var
  I    : Integer;
  T    : THdsTrigger;
  Item : TListItem;
  Sel  : Integer;
  LblIdx: Integer;
begin
  if FTriggerList = nil then
    Exit;

  Sel := -1;
  if lvTriggers.Selected <> nil then
    Sel := lvTriggers.Selected.Index;

  lvTriggers.Items.BeginUpdate;
  try
    lvTriggers.Items.Clear;
    for I := 0 to FTriggerList.Count - 1 do
    begin
      T := FTriggerList[I];

      // Label fuer Datentyp suchen
      LblIdx := 0;
      while (LblIdx < HdsDataTypeCount - 1) and
            not SameText(HdsDataTypeKey[LblIdx], T.DataTypeKey) do
        Inc(LblIdx);

      Item := lvTriggers.Items.Add;
      Item.Caption := HdsDataTypeLabel[LblIdx];
      Item.SubItems.Add(
        HdsConditionSym[T.Condition] + ' ' +
        StringReplace(Format('%.6g', [T.Threshold]), ',', '.', []));
      Item.SubItems.Add(T.Describe);
      if T.CooldownSec > 0 then
        Item.SubItems.Add(IntToStr(T.CooldownSec) + ' s')
      else
        Item.SubItems.Add('-');
    end;
  finally
    lvTriggers.Items.EndUpdate;
  end;

  if (Sel >= 0) and (Sel < lvTriggers.Items.Count) then
    lvTriggers.Items[Sel].Selected := True;

  UpdateButtons;
end;

procedure THdsForm.UpdateButtons;
var
  HasSel: Boolean;
begin
  HasSel := lvTriggers.Selected <> nil;
  btnEditHds.Enabled := HasSel;
  btnDelHds.Enabled  := HasSel;
end;

function THdsForm.SelectedTrigger: THdsTrigger;
var
  Idx: Integer;
begin
  Result := nil;
  if lvTriggers.Selected = nil then
    Exit;
  Idx := lvTriggers.Selected.Index;
  if (FTriggerList <> nil) and (Idx >= 0) and (Idx < FTriggerList.Count) then
    Result := FTriggerList[Idx];
end;

procedure THdsForm.btnAddHdsClick(Sender: TObject);
var
  Dlg : TAddHdsTriggerForm;
  T   : THdsTrigger;
begin
  if FTriggerList = nil then
    Exit;
  Dlg := TAddHdsTriggerForm.Create(Self);
  try
    Dlg.MaxShockerIndex := FMaxShockerIndex;
    if Dlg.ShowModal = mrOk then
    begin
      T := Dlg.GetTrigger;
      FTriggerList.Add(T);
      RefreshList;
      if Assigned(FOnSave) then
        FOnSave;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure THdsForm.btnEditHdsClick(Sender: TObject);
var
  Dlg      : TAddHdsTriggerForm;
  Existing : THdsTrigger;
  Updated  : THdsTrigger;
  Idx      : Integer;
begin
  Existing := SelectedTrigger;
  if Existing = nil then
    Exit;
  Idx := lvTriggers.Selected.Index;

  Dlg := TAddHdsTriggerForm.Create(Self);
  try
    Dlg.MaxShockerIndex := FMaxShockerIndex;
    Dlg.LoadFromTrigger(Existing);
    if Dlg.ShowModal = mrOk then
    begin
      Updated := Dlg.GetTrigger;
      FTriggerList.Delete(Idx);
      FTriggerList.Insert(Idx, Updated);
      RefreshList;
      if Assigned(FOnSave) then
        FOnSave;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure THdsForm.btnDelHdsClick(Sender: TObject);
var
  T   : THdsTrigger;
  Idx : Integer;
begin
  T := SelectedTrigger;
  if T = nil then
    Exit;
  if MessageDlg(
      'HDS-Trigger "' + T.DataTypeKey + '" l'#246'schen?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Idx := lvTriggers.Selected.Index;
    FTriggerList.Delete(Idx);
    RefreshList;
    if Assigned(FOnSave) then
      FOnSave;
  end;
end;

procedure THdsForm.lvTriggersSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  UpdateButtons;
end;

procedure THdsForm.lvTriggersDblClick(Sender: TObject);
begin
  if SelectedTrigger <> nil then
    btnEditHdsClick(nil);
end;

end.
