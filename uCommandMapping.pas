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

  /// <summary>Eine Befehlszuordnung: Trigger-String -> PiShock-Operation</summary>
  TCommandMapping = class
  public
    TriggerString : string;       // Ausloesestring (z.B. "shock50")
    OpType        : TOpType;      // Art der Operation
    TargetType    : TTargetType;  // Welches Modul (alle/spezifisch/zufaellig)
    ShockerIndex  : Integer;      // 0-basierter Index fuer ttSpecific
    Intensity     : Integer;      // Intensitaet 0-100 (nicht fuer beep/end)
    Duration      : Integer;      // Dauer in Millisekunden (nicht fuer end)

    constructor Create; overload;
    constructor Create(const ATrigger: string; AOp: TOpType;
      ATarget: TTargetType; AIdx, AIntensity, ADuration: Integer); overload;

    /// <summary>Lesbare Beschreibung der Zuordnung</summary>
    function Describe: string;

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
begin
  case TargetType of
    ttAll:      TargStr := 'Alle';
    ttSpecific: TargStr := Format('Modul %d', [ShockerIndex + 1]);
    ttRandom:   TargStr := 'Zuf'#228'llig';
  end;

  case OpType of
    opShock, opVibrate:
      Result := Format('%s %d%% %dms (%s)',
        [OpTypeStr[OpType], Intensity, Duration, TargStr]);
    opBeep:
      Result := Format('%s %dms (%s)',
        [OpTypeStr[OpType], Duration, TargStr]);
    opEnd:
      Result := Format('%s (%s)',
        [OpTypeStr[OpType], TargStr]);
  end;
end;

function TCommandMapping.Clone: TCommandMapping;
begin
  Result := TCommandMapping.Create(TriggerString, OpType, TargetType,
    ShockerIndex, Intensity, Duration);
end;

end.
