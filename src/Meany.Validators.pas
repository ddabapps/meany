{
  Copyright (c) 2025, Peter Johnson, delphidabbler.com
  MIT License
  https://github.com/ddabapps/meany
}

unit Meany.Validators;

interface

uses
  System.SysUtils;

procedure ValidateNonEmptyValuesArray(const AValues: array of Double);

procedure ValidateFixedSizeValuesArray(const AValues: array of Double;
  const ASize: Cardinal);

procedure ValidateMinimumSizeValuesArray(const AValues: array of Double;
  const AMinSize: Cardinal);

procedure ValidatePositiveValuesArray(const AValues: array of Double);

procedure ValidateNonNegativeValuesArray(const AValues: array of Double);

procedure ValidateIntegerValuesArray(const AValues: array of Double);

procedure ValidateWeights(const AWeights: array of Double;
  const AValueLength: Integer);

procedure ValidateLambda(const ALambda: Double);

type
  EValidator = class(Exception);

implementation

uses
  System.Math;

function ArrayAll(const A: array of Double;
  const APredicate: TPredicate<Double>): Boolean;
begin
  Result := True;
  for var Elem in A do
    if not APredicate(Elem) then
      Exit(False);
end;

function ArrayIsPositive(const A: array of Double): Boolean;
begin
  Result := ArrayAll(
    A,
    function (AElem: Double): Boolean
    begin
      Result := Sign(AElem) = PositiveValue;
    end
  );
end;

function ArrayIsNonNegative(const A: array of Double): Boolean;
begin
  Result := ArrayAll(
    A,
    function (AElem: Double): Boolean
    begin
      Result := Sign(AElem) <> NegativeValue;
    end
  );
end;

function ArrayIsZero(const A: array of Double): Boolean;
begin
  Result := ArrayAll(
    A,
    function (AElem: Double): Boolean
    begin
      Result := IsZero(AElem);
    end
  );
end;

procedure ValidateNonEmptyValuesArray(const AValues: array of Double);
resourcestring
  SEmptyValuesArrayError = 'At least one value must be provided.';
begin
  if Length(AValues) = 0 then
    raise EValidator.Create(SEmptyValuesArrayError);
end;

procedure ValidatePositiveValuesArray(const AValues: array of Double);
resourcestring
  SPositiveArrayError = 'All values must be positive.';
begin
  if not ArrayIsPositive(AValues) then
    raise EValidator.Create(SPositiveArrayError);
end;

procedure ValidateNonNegativeValuesArray(
  const AValues: array of Double);
resourcestring
  SNonNegativeArrayError = 'All values must be non-negative.';
begin
  if not ArrayIsNonNegative(AValues) then
    raise EValidator.Create(SNonNegativeArrayError);
end;

procedure ValidateFixedSizeValuesArray(const AValues: array of Double;
  const ASize: Cardinal);
resourcestring
  SWrongSize = 'Exactly %d values are required.';
begin
  if Length(AValues) <> ASize then
    raise EValidator.CreateFmt(SWrongSize, [ASize]);
end;

procedure ValidateMinimumSizeValuesArray(const AValues: array of Double;
  const AMinSize: Cardinal);
resourcestring
  STwoFewElements = 'At least %d values are required.';
begin
  if Length(AValues) < AMinSize then
    raise EValidator.CreateFmt(STwoFewElements, [AMinSize]);
end;

procedure ValidateIntegerValuesArray(const AValues: array of Double);
resourcestring
  SNotInteger = 'Values must all be integers.';
begin
  for var Elem in AValues do
  begin
    if not SameValue(Elem, Round(Elem)) then
      raise EValidator.Create(SNotInteger);
  end;
end;

procedure ValidateWeights(const AWeights: array of Double;
  const AValueLength: Integer);
resourcestring
  SEmptyWeightsArrayError = 'No weights have been provided.';
  SNonNegativeWeightsError = 'All weights must be non-negative.';
  SZeroWeightError = 'At least one weight must be non-zero.';
  SBadElementCount =
    'The number of weights must be the same as the number of values.';
begin
  if Length(AWeights) = 0 then
    raise EValidator.Create(SEmptyWeightsArrayError);
  if Length(AWeights) <> AValueLength then
    raise EValidator.Create(SBadElementCount);
  if not ArrayIsNonNegative(AWeights) then
    raise EValidator.Create(SNonNegativeWeightsError);
  if ArrayIsZero(AWeights) then
    raise EValidator.Create(SZeroWeightError);
end;

procedure ValidateLambda(const ALambda: Double);
resourcestring
  SZeroLambda = 'Lambda must not be zero.';
begin
  if IsZero(ALambda) then
    raise EValidator.Create(SZeroLambda);
end;

end.
