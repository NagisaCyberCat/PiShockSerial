unit uCommandMapping;
{
  Typen und Klassen fuer Befehlszuordnungen.
  Ein TCommandMapping verbindet einen Ausloesestring (z.B. "shock50l")
  mit einer PiShock-Operation (Schock/Vibration/Beep/Stop) fuer ein
  oder mehrere haptische Module.
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  /// <summary>Art der PiShock-Operation</summary>
  TOpType = (opShock, opVibrate, opBeep, opEnd);

  /// <summary>Welche Module angesprochen werden</summary>
  TTargetType = (ttAll, ttSpecific, ttRandom);

  /// <summary>Vergleich fuer optionale HDS-Abhaengigkeit im Mapping</summary>
  THdsGateCondition = (hgcAbove, hgcAboveOrEqual, hgcBelow, hgcBelowOrEqual);

  /// <summary>Eine Befehlszuordnung: Trigger-String -> PiShock-Operation</summary>
  TCommandMapping = class
  public
    TriggerString : string;       // Ausloesestring (z.B. "shock50")
    OpType        : TOpType;      // Art der Operation
    TargetType    : TTargetType;  // Welches Modul (alle/spezifisch/zufaellig)
    ShockerIndex  : Integer;      // 0-basierter Index fuer ttSpecific
    Intensity     : Integer;      // Intensitaet 0-100 (nicht fuer beep/end)
    Duration      : Integer;      // Dauer in Millisekunden (nicht fuer end)

    // Optionale HDS-Abhaengigkeit (wird vor WS-Ausfuehrung geprueft)
    HdsRequired   : Boolean;
    HdsDataTypeKey: string;
    HdsCondition  : THdsGateCondition;
    HdsThreshold  : Double;

    constructor Create; overload;
    constructor Create(const ATrigger: string; AOp: TOpType;
      ATarget: TTargetType; AIdx, AIntensity, ADuration: Integer); overload;

    /// <summary>Lesbare Beschreibung der Zuordnung</summary>
    function Describe: string;

    /// <summary>Prueft die konfigurierte HDS-Bedingung gegen einen Messwert</summary>
    function IsHdsConditionMet(AValue: Double): Boolean;

    /// <summary>Kopie dieser Zuordnung erstellen</summary>
    function Clone: TCommandMapping;
  end;

  TCommandMappingList = TObjectList<TCommandMapping>;

const
  /// <summary>Anzeigetext fuer OpType</summary>
  OpTypeStr: array[TOpType] of string = ('Schock', 'Vibration', 'Beep', 'Stop');

  /// <summary>API-Kommando-String fuer PiShock Serial</summary>
  OpApiStr: array[TOpType] of string = ('shock', 'vibrate', 'beep', 'end');

  /// <summary>Anzeigetext fuer TargetType</summary>
  TargetTypeStr: array[TTargetType] of string = ('Alle', 'Spezifisch', 'Zuf'#228'llig');

  HdsGateCondSym: array[THdsGateCondition] of string = ('>', '>=', '<', '<=');

implementation

constructor TCommandMapping.Create;
begin
  inherited Create;
  TriggerString := '';
  OpType        := opShock;
  TargetType    := ttAll;
  ShockerIndex  := 0;
  Intensity     := 50;
  Duration      := 1000;
  HdsRequired   := False;
  HdsDataTypeKey:= 'heartRate';
  HdsCondition  := hgcAbove;
  HdsThreshold  := 120.0;
end;

constructor TCommandMapping.Create(const ATrigger: string; AOp: TOpType;
  ATarget: TTargetType; AIdx, AIntensity, ADuration: Integer);
begin
  Create;
  TriggerString := ATrigger;
  OpType        := AOp;
  TargetType    := ATarget;
  ShockerIndex  := AIdx;
  Intensity     := AIntensity;
  Duration      := ADuration;
end;

function TCommandMapping.Describe: string;
var
  TargStr: string;
  BaseStr: string;
begin
  case TargetType of
    ttAll:      TargStr := 'Alle';
    ttSpecific: TargStr := Format('Modul %d', [ShockerIndex + 1]);
    ttRandom:   TargStr := 'Zuf'#228'llig';
  end;

  case OpType of
    opShock, opVibrate:
      BaseStr := Format('%s %d%% %dms (%s)',
        [OpTypeStr[OpType], Intensity, Duration, TargStr]);
    opBeep:
      BaseStr := Format('%s %dms (%s)',
        [OpTypeStr[OpType], Duration, TargStr]);
    opEnd:
      BaseStr := Format('%s (%s)',
        [OpTypeStr[OpType], TargStr]);
  end;

  if HdsRequired then
    Result := BaseStr + Format(' | HDS: %s %s %.6g',
      [HdsDataTypeKey, HdsGateCondSym[HdsCondition], HdsThreshold])
  else
    Result := BaseStr;
end;

function TCommandMapping.IsHdsConditionMet(AValue: Double): Boolean;
begin
  case HdsCondition of
    hgcAbove:        Result := AValue > HdsThreshold;
    hgcAboveOrEqual: Result := AValue >= HdsThreshold;
    hgcBelow:        Result := AValue < HdsThreshold;
  else
    Result := AValue <= HdsThreshold;
  end;
end;

function TCommandMapping.Clone: TCommandMapping;
begin
  Result := TCommandMapping.Create(TriggerString, OpType, TargetType,
    ShockerIndex, Intensity, Duration);
  Result.HdsRequired    := HdsRequired;
  Result.HdsDataTypeKey := HdsDataTypeKey;
  Result.HdsCondition   := HdsCondition;
  Result.HdsThreshold   := HdsThreshold;
end;

end.
