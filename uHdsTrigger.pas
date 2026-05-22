unit uHdsTrigger;
{
  Typen fuer HDS-Trigger (Health Data Server).
  Ein THdsTrigger beschreibt eine Schwellwert-basierte Ausloesebedingung:
  Wenn ein Gesundheitsdaten-Typ einen Schwellwert ueber-/unterschreitet,
  wird eine konfigurierte PiShock-Operation ausgefuehrt.

  Datentypen gemaess HDS-Protokoll (camelCase-Schluessel):
    heartRate, calories, stepCount, distanceTraveled, speed,
    oxygenSaturation, bodyMass, bmi
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.DateUtils,
  uCommandMapping;

type
  /// <summary>Vergleichsoperator fuer den Schwellwert</summary>
  THdsCondition = (hcAbove, hcAboveOrEqual, hcBelow, hcBelowOrEqual);

const
  HdsConditionSym: array[THdsCondition] of string = ('>', '>=', '<', '<=');

  HdsDataTypeCount = 8;

  HdsDataTypeKey: array[0..HdsDataTypeCount - 1] of string = (
    'heartRate', 'calories', 'stepCount',
    'distanceTraveled', 'speed', 'oxygenSaturation',
    'bodyMass', 'bmi'
  );

  HdsDataTypeLabel: array[0..HdsDataTypeCount - 1] of string = (
    'Herzrate (bpm)', 'Kalorien (kcal)', 'Schritte',
    'Distanz (m)', 'Geschwindigkeit (m/s)', 'O2-S'#228'ttigung (%)',
    'K'#246'rpermasse (kg)', 'BMI'
  );

type
  THdsTrigger = class
  public
    DataTypeKey  : string;        // z.B. 'heartRate'
    Condition    : THdsCondition;
    Threshold    : Double;
    CooldownSec  : Integer;       // Mindestzeitabstand in Sekunden (0 = kein Limit)

    // Aktion
    OpType       : TOpType;
    TargetType   : TTargetType;
    ShockerIndex : Integer;
    Intensity    : Integer;
    Duration     : Integer;

    // Laufzeit-Feld (nicht persistent)
    LastTriggered: TDateTime;

    constructor Create;

    /// <summary>Lesbare Kurzbeschreibung: DataType Bedingung Threshold -> Aktion</summary>
    function Describe: string;

    /// <summary>Kopie dieser Konfiguration</summary>
    function Clone: THdsTrigger;

    /// <summary>
    ///   Prueft ob dieser Trigger feuern soll.
    ///   Aktualisiert LastTriggered wenn True zurueckgegeben wird.
    /// </summary>
    function ShouldFire(const AKey: string; AValue: Double): Boolean;
  end;

  THdsTriggerList = TObjectList<THdsTrigger>;

implementation

constructor THdsTrigger.Create;
begin
  inherited Create;
  DataTypeKey   := 'heartRate';
  Condition     := hcAbove;
  Threshold     := 120.0;
  CooldownSec   := 30;
  OpType        := opVibrate;
  TargetType    := ttAll;
  ShockerIndex  := 0;
  Intensity     := 50;
  Duration      := 1000;
  LastTriggered := 0;
end;

function THdsTrigger.Describe: string;
var
  TrgStr: string;
begin
  case TargetType of
    ttAll:      TrgStr := 'Alle';
    ttSpecific: TrgStr := Format('Modul %d', [ShockerIndex + 1]);
    ttRandom:   TrgStr := 'Zuf'#228'llig';
  end;
  case OpType of
    opShock, opVibrate:
      Result := Format('%s %d%% %dms (%s)',
        [OpTypeStr[OpType], Intensity, Duration, TrgStr]);
    opBeep:
      Result := Format('%s %dms (%s)',
        [OpTypeStr[OpType], Duration, TrgStr]);
    opEnd:
      Result := Format('%s (%s)', [OpTypeStr[OpType], TrgStr]);
  end;
end;

function THdsTrigger.Clone: THdsTrigger;
begin
  Result               := THdsTrigger.Create;
  Result.DataTypeKey   := DataTypeKey;
  Result.Condition     := Condition;
  Result.Threshold     := Threshold;
  Result.CooldownSec   := CooldownSec;
  Result.OpType        := OpType;
  Result.TargetType    := TargetType;
  Result.ShockerIndex  := ShockerIndex;
  Result.Intensity     := Intensity;
  Result.Duration      := Duration;
end;

function THdsTrigger.ShouldFire(const AKey: string; AValue: Double): Boolean;
begin
  Result := False;

  if not SameText(AKey, DataTypeKey) then
    Exit;

  case Condition of
    hcAbove:        if AValue <= Threshold then Exit;
    hcAboveOrEqual: if AValue <  Threshold then Exit;
    hcBelow:        if AValue >= Threshold then Exit;
    hcBelowOrEqual: if AValue >  Threshold then Exit;
  end;

  if (CooldownSec > 0) and (LastTriggered > 0) and
     (SecondsBetween(Now, LastTriggered) < CooldownSec) then
    Exit;

  Result        := True;
  LastTriggered := Now;
end;

end.
