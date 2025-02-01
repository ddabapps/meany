{
  Copyright (c) 2025, Peter Johnson, delphidabbler.com
  MIT License
  https://github.com/ddabapps/meany
}

unit Meany.Stats;

{$ScopedEnums on}

interface

uses
  System.SysUtils;

type

  TDataArrayProvider = reference to function: TArray<Double>;

  TDataItemProvider = reference to function: Double;

  TStatValueRange = (Any, NonNegative, Positive);

  TStatValueType = (FloatNumber, WholeNumber);

  TStatValuesSize = (Fixed, Variable);

  TStatDataRequirement = (Weights, Lambda);

  TStatDataRequirements = set of TStatDataRequirement;

  TStat = class abstract(TObject)
  strict private
    var
      fDisplayName: string;
      fValuesProvider: TDataArrayProvider;
      fWeightsProvider: TDataArrayProvider;
      fLambdaProvider: TDataItemProvider;

      fValueRange: TStatValueRange;
      fValueType: TStatValueType;
      fValuesSize: TStatValuesSize;
      fDataRequirements: TStatDataRequirements;
      fSizeLimit: Cardinal;
    procedure Validate(const AValues, AWeights: array of Double;
      const ALambda: Double);
  strict protected
    property ValuesProvider: TDataArrayProvider read fValuesProvider;
    property WeightsProvider: TDataArrayProvider read fWeightsProvider;
    property LambdaProvider: TDataItemProvider read fLambdaProvider;
    procedure SetValueRange(const AValue: TStatValueRange);
    procedure SetValueType(const AValue: TStatValueType);
    procedure SetDataRequirements(const AValue: TStatDataRequirements);
    procedure SetStatValuesSize(const AValue: TStatValuesSize);
    procedure SetSizeLimit(const AValue: Cardinal);
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      virtual; abstract;
    procedure SetCharacteristics; virtual; abstract;
  public
    constructor Create(const ADisplayName: string;
      const AValuesProvider: TDataArrayProvider;
      const AWeightsProvider: TDataArrayProvider;
      const ALambdaProvider: TDataItemProvider);
    function Calculate(const AFmtSettings: TFormatSettings): string;
    property DisplayName: string read fDisplayName;
    property ValueRange: TStatValueRange read fValueRange;
    property ValueType: TStatValueType read fValueType;
    property ValuesSize: TStatValuesSize read fValuesSize;
    property DataRequirements: TStatDataRequirements read fDataRequirements;
    property SizeLimit: Cardinal read fSizeLimit;
  end;

  TStatClass = class of TStat;

  EStat = class(Exception);

  TArithmeticMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TWeightedArithmeticMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TGeometricMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TWeightedGeometricMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  THarmonicMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TWeightedHarmonicMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TPowerMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TWeightedPowerMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TLogarithmicMean = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TMedian = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TMode = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TRMS = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

  TTSS = class sealed(TStat)
  strict protected
    function DoCalculate(const AValues, AWeights: array of Double;
      const ALambda: Double; const AFmtSettings: TFormatSettings): string;
      override;
    procedure SetCharacteristics; override;
  end;

implementation

uses
  Meany.AverageFns,
  Meany.Validators;

{ TStat }

function TStat.Calculate(const AFmtSettings: TFormatSettings): string;
begin
  try
    var Values: TArray<Double> := ValuesProvider;
    var Weights: TArray<Double> := [];
    var Lambda: Double := 0.0;

    if TStatDataRequirement.Weights in fDataRequirements then
      Weights := WeightsProvider;
    if TStatDataRequirement.Lambda in fDataRequirements then
      Lambda := LambdaProvider;

    Validate(Values, Weights, Lambda);

    Result := DoCalculate(Values, Weights, Lambda, AFmtSettings);

  except
    on E: Exception do
      raise EStat.Create(fDisplayName + ': ' + E.Message);
  end;
end;

constructor TStat.Create(const ADisplayName: string;
  const AValuesProvider: TDataArrayProvider;
  const AWeightsProvider: TDataArrayProvider;
  const ALambdaProvider: TDataItemProvider);
begin
  inherited Create;
  fDisplayName := ADisplayName;
  fValuesProvider := AValuesProvider;
  fWeightsProvider := AWeightsProvider;
  fLambdaProvider := ALambdaProvider;
  SetCharacteristics;
end;

procedure TStat.SetDataRequirements(const AValue: TStatDataRequirements);
begin
  fDataRequirements := AValue;
end;

procedure TStat.SetSizeLimit(const AValue: Cardinal);
begin
  fSizeLimit := AValue;
end;

procedure TStat.SetStatValuesSize(const AValue: TStatValuesSize);
begin
  fValuesSize := AValue;
end;

procedure TStat.SetValueRange(const AValue: TStatValueRange);
begin
  fValueRange := AValue;
end;

procedure TStat.SetValueType(const AValue: TStatValueType);
begin
  fValueType := AValue;
end;

procedure TStat.Validate(const AValues, AWeights: array of Double;
  const ALambda: Double);
begin
  case fValuesSize of
    TStatValuesSize.Fixed:
    begin
      ValidateFixedSizeValuesArray(AValues, fSizeLimit);
    end;
    TStatValuesSize.Variable:
    begin
      if fSizeLimit = 1 then
        ValidateNonEmptyValuesArray(AValues)
      else
        ValidateMinimumSizeValuesArray(AValues, fSizeLimit);
    end;
  end;

  case fValueRange of
    TStatValueRange.Any:
      {No validation of sign of values required};
    TStatValueRange.NonNegative:
      ValidateNonNegativeValuesArray(AValues);
    TStatValueRange.Positive:
      ValidatePositiveValuesArray(AValues);
  end;

  case fValueType of
    TStatValueType.FloatNumber:
      {No validation of type required: values are float by default};
    TStatValueType.WholeNumber:
      ValidateIntegerValuesArray(AValues);
  end;

  if TStatDataRequirement.Weights in fDataRequirements then
    ValidateWeights(AWeights, Length(AValues));
  if TStatDataRequirement.Lambda in fDataRequirements then
    ValidateLambda(ALambda);

end;

{ TArithmeticMean }

function TArithmeticMean.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := ArithmeticMean(AValues).ToString(AFmtSettings);
end;

procedure TArithmeticMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

{ TWeightedArithmeticMean }

function TWeightedArithmeticMean.DoCalculate(
  const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := WeightedArithmeticMean(AValues, AWeights).ToString(AFmtSettings);
end;

procedure TWeightedArithmeticMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([TStatDataRequirement.Weights]);
end;

{ TGeometricMean }

function TGeometricMean.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := GeometricMean(AValues).ToString(AFmtSettings);
end;

procedure TGeometricMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Positive);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

{ TWeightedGeometricMean }

function TWeightedGeometricMean.DoCalculate(
  const AValues, AWeights: array of Double; const ALambda: Double;
  const AFmtSettings: TFormatSettings): string;
begin
  Result := WeightedGeometricMean(AValues, AWeights).ToString(AFmtSettings);
end;

procedure TWeightedGeometricMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Positive);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([TStatDataRequirement.Weights]);
end;

{ THarmonicMean }

function THarmonicMean.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := HarmonicMean(AValues).ToString(AFmtSettings);
end;

procedure THarmonicMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Positive);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

{ TWeightedHarmonicMean }

function TWeightedHarmonicMean.DoCalculate(
  const AValues, AWeights: array of Double; const ALambda: Double;
  const AFmtSettings: TFormatSettings): string;
begin
  Result := WeightedHarmonicMean(AValues, AWeights).ToString(AFmtSettings);
end;

procedure TWeightedHarmonicMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Positive);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([TStatDataRequirement.Weights]);
end;

{ TPowerMean }

function TPowerMean.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := PowerMean(AValues, ALambda).ToString(AFmtSettings);
end;

procedure TPowerMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.NonNegative);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([TStatDataRequirement.Lambda]);
end;

{ TWeightedPowerMean }

function TWeightedPowerMean.DoCalculate(
  const AValues, AWeights: array of Double; const ALambda: Double;
  const AFmtSettings: TFormatSettings): string;
begin
  Result := WeightedPowerMean(AValues, AWeights, ALambda).ToString(
    AFmtSettings
  );
end;

procedure TWeightedPowerMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.NonNegative);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements(
    [TStatDataRequirement.Lambda, TStatDataRequirement.Weights]
  );
end;

{ TLogarithmicMean }

function TLogarithmicMean.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := LogarithmicMean(AValues[0], AValues[1]).ToString(AFmtSettings);
end;

procedure TLogarithmicMean.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Positive);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Fixed);
  SetSizeLimit(2);
  SetDataRequirements([]);
end;

{ TMedian }

function TMedian.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := Median(AValues).ToString(AFmtSettings);
end;

procedure TMedian.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

{ TMode }

function TMode.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;

  function ConvertValuesToIntegers(const AFloatValues: array of Double):
    TArray<Integer>;
  begin
    SetLength(Result, Length(AFloatValues));
    for var Idx := 0 to Pred(Length(AFloatValues)) do
      Result[Idx] := Round(AFloatValues[Idx]);
  end;

  function ResultsToString(const AResults: array of Integer): string;
  resourcestring
    SNoMode = 'No mode';
  begin
    if Length(AResults) = 0 then
      Exit(SNoMode);
    Result := string.Empty;
    Result := AResults[0].ToString;
    for var Idx := 1 to Pred(Length(AResults)) do
      Result := Result + AFmtSettings.ListSeparator + ' '
        + AResults[Idx].ToString;
  end;

begin
  Result := ResultsToString(ModeAlt(ConvertValuesToIntegers(AValues)));
end;

procedure TMode.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.WholeNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(2);
  SetDataRequirements([]);
end;

{ TRMS }

function TRMS.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := RMS(AValues).ToString(AFmtSettings);
end;

procedure TRMS.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

{ TTSS }

function TTSS.DoCalculate(const AValues, AWeights: array of Double;
  const ALambda: Double; const AFmtSettings: TFormatSettings): string;
begin
  Result := TSS(AValues).ToString(AFmtSettings);
end;

procedure TTSS.SetCharacteristics;
begin
  SetValueRange(TStatValueRange.Any);
  SetValueType(TStatValueType.FloatNumber);
  SetStatValuesSize(TStatValuesSize.Variable);
  SetSizeLimit(1);
  SetDataRequirements([]);
end;

end.

