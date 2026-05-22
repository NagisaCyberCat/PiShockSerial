unit uModuleNamesForm;
{
  Verwaltung benutzerdefinierter Namen fuer bekannte PiShock-Module.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  uPiShockDevice, uLanguage;

type
  TModuleNamesForm = class(TForm)
    lvModules: TListView;
    lblName: TLabel;
    edtName: TEdit;
    btnSaveName: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure lvModulesSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnSaveNameClick(Sender: TObject);
  private
    FShockers: TArray<TShockerInfo>;
    FNames: TDictionary<Integer, string>;
    procedure RefreshList;
    function TryGetSelectedShockerId(out AShockerId: Integer): Boolean;
  public
    procedure Setup(const AShockers: TArray<TShockerInfo>;
      ANames: TDictionary<Integer, string>);
    procedure ApplyLanguage;
  end;

implementation

{$R *.dfm}

procedure TModuleNamesForm.FormCreate(Sender: TObject);
begin
  ApplyLanguage;

  lvModules.ReadOnly := True;
  lvModules.RowSelect := True;
  lvModules.ViewStyle := vsReport;
end;

procedure TModuleNamesForm.ApplyLanguage;
begin
  Caption := LS.ModuleNamesCaption;
  lblName.Caption := LS.ModuleNamesLblName;
  btnSaveName.Caption := LS.ModuleNamesBtnSave;
  btnClose.Caption := LS.ModuleNamesBtnClose;

  if lvModules.Columns.Count = 0 then
  begin
    with lvModules.Columns.Add do
    begin
      Caption := LS.ModuleNamesColIndex;
      Width := 40;
    end;
    with lvModules.Columns.Add do
    begin
      Caption := LS.ModuleNamesColId;
      Width := 100;
    end;
    with lvModules.Columns.Add do
    begin
      Caption := LS.ModuleNamesColName;
      Width := 180;
    end;
  end
  else if lvModules.Columns.Count >= 3 then
  begin
    lvModules.Columns[0].Caption := LS.ModuleNamesColIndex;
    lvModules.Columns[1].Caption := LS.ModuleNamesColId;
    lvModules.Columns[2].Caption := LS.ModuleNamesColName;
  end;
end;

procedure TModuleNamesForm.Setup(const AShockers: TArray<TShockerInfo>;
  ANames: TDictionary<Integer, string>);
begin
  FShockers := AShockers;
  FNames := ANames;
  RefreshList;
end;

procedure TModuleNamesForm.RefreshList;
var
  I: Integer;
  Item: TListItem;
  NameVal: string;
begin
  lvModules.Items.BeginUpdate;
  try
    lvModules.Items.Clear;
    for I := 0 to High(FShockers) do
    begin
      Item := lvModules.Items.Add;
      Item.Caption := IntToStr(I + 1);
      Item.SubItems.Add(IntToStr(FShockers[I].ID));

      NameVal := '';
      if Assigned(FNames) then
        FNames.TryGetValue(FShockers[I].ID, NameVal);

      if Trim(NameVal) = '' then
        Item.SubItems.Add('-')
      else
        Item.SubItems.Add(NameVal);
    end;
  finally
    lvModules.Items.EndUpdate;
  end;

  edtName.Clear;
end;

function TModuleNamesForm.TryGetSelectedShockerId(
  out AShockerId: Integer): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  AShockerId := 0;

  if lvModules.Selected = nil then
    Exit;

  Idx := lvModules.Selected.Index;
  if (Idx < 0) or (Idx > High(FShockers)) then
    Exit;

  AShockerId := FShockers[Idx].ID;
  Result := True;
end;

procedure TModuleNamesForm.lvModulesSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  ShockerId: Integer;
  NameVal: string;
begin
  if not Selected then
    Exit;

  if not TryGetSelectedShockerId(ShockerId) then
    Exit;

  NameVal := '';
  if Assigned(FNames) then
    FNames.TryGetValue(ShockerId, NameVal);

  edtName.Text := NameVal;
end;

procedure TModuleNamesForm.btnSaveNameClick(Sender: TObject);
var
  ShockerId: Integer;
  NameVal: string;
  Idx: Integer;
begin
  if not TryGetSelectedShockerId(ShockerId) then
    Exit;

  NameVal := Trim(edtName.Text);
  if not Assigned(FNames) then
    Exit;

  if NameVal = '' then
    FNames.Remove(ShockerId)
  else if FNames.ContainsKey(ShockerId) then
    FNames[ShockerId] := NameVal
  else
    FNames.Add(ShockerId, NameVal);

  Idx := lvModules.Selected.Index;
  RefreshList;
  if (Idx >= 0) and (Idx < lvModules.Items.Count) then
  begin
    lvModules.Items[Idx].Selected := True;
    lvModules.Items[Idx].Focused := True;
    lvModules.SetFocus;
  end;
end;

end.
