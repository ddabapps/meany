{
  Copyright (c) 2025, Peter Johnson, delphidabbler.com
  MIT License
  https://github.com/ddabapps/meany
}

unit Meany.UI.MainForm;

interface

uses
  System.SysUtils,
  System.Classes,
  System.ImageList,
  System.Actions,
  FMX.Forms,
  FMX.ImgList,
  FMX.Memo.Types,
  FMX.ActnList,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Types,

  Meany.Stats;

type
  TMainForm = class(TForm)
    ActionList: TActionList;
    ValuesPanel: TPanel;
    ValuesLabel: TLabel;
    ValuesMemo: TMemo;
    WeightsPanel: TPanel;
    WeightsLabel: TLabel;
    WeightsMemo: TMemo;
    InfoLabel: TLabel;
    CalculateAction: TAction;
    ButtonsPanel: TPanel;
    HeadingLabel: TLabel;
    LambdaPanel: TPanel;
    LambdaLabel: TLabel;
    LambdaEdit: TEdit;
    CalculateButton: TCornerButton;
    ResultLabel: TLabel;
    ResultEdit: TEdit;
    ImageList: TImageList;
    SettingsButton: TButton;
    SettingsAction: TAction;
    HelpButton: TButton;
    HelpAction: TAction;
    StyleBook: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure CalculateActionUpdate(Sender: TObject);
    procedure CalculateActionExecute(Sender: TObject);
    procedure SettingsActionExecute(Sender: TObject);
    procedure HelpActionExecute(Sender: TObject);
  strict private
    type
      TStatButton = class(TCornerButton)
      strict private
        var
          fStat: TStat;
      public
        property Stat: TStat read fStat write fStat;
        destructor Destroy; override;
      end;
    var
      fFmtSettings: TFormatSettings;
      fCurrentStat: TStat;
      fPrevStatButton: TStatButton;
    function ValuesProvider: TArray<Double>;
    function WeightsProvider: TArray<Double>;
    function LambdaProvider: Double;
    class function CompressWhiteSpace(const S: string): string;
    function CanUseListSeparator: Boolean;
    function ParseEnteredNumberList(AText: string): TArray<Double>;
    function SeparateData(const AData: array of Double;
      const ASeparator: string): string;
    function FormatEnteredData(const AData: array of Double): string;
    procedure CreateStatButtons;
    procedure StatButtonClick(Sender: TObject);
    procedure SelectStat(const AStat: TStat);
    function FindStatButton(const AStat: TStat): TStatButton;
    function DefaultStat: TStat;
  public
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.StrUtils,
  System.Character,
  System.Generics.Collections,
  System.UITypes,

  Meany.UI.HelpForm,
  Meany.UI.SettingsForm;

{$R *.fmx}

{ TMainForm }

procedure TMainForm.CalculateActionExecute(Sender: TObject);
resourcestring
  SError = 'Error';
begin
  try
    // Convert layout of entered values and weights into one number per line
    var Values := ParseEnteredNumberList(ValuesMemo.Text);
    var Weights := ParseEnteredNumberList(WeightsMemo.Text);
    ValuesMemo.Text := FormatEnteredData(Values);
    WeightsMemo.Text := FormatEnteredData(Weights);
    // Perform calculation
    ResultEdit.Text := fCurrentStat.Calculate(fFmtSettings);
  except
    ResultEdit.Text := SError;
    raise;
  end;
end;

procedure TMainForm.CalculateActionUpdate(Sender: TObject);
begin
  CalculateAction.Enabled := Assigned(fCurrentStat) and
    (ValuesMemo.Lines.Count > 0);
end;

function TMainForm.CanUseListSeparator: Boolean;
begin
  Result := fFmtSettings.DecimalSeparator <> fFmtSettings.ListSeparator;
end;

class function TMainForm.CompressWhiteSpace(const S: string): string;
begin
  Result := string.Empty;
  var ProcessingWhiteSpace: Boolean := False;
  for var Ch in S do
  begin
    if Ch.IsWhiteSpace then
    begin
      // We have white space char: keep 1st one in a sequence & ignore the rest
      if not ProcessingWhiteSpace then
      begin
        Result := Result + ' ';
        ProcessingWhiteSpace := True;
      end;
    end
    else // not white space
    begin
      Result := Result + Ch;
      ProcessingWhiteSpace := False;
    end;
  end;
end;

procedure TMainForm.CreateStatButtons;

  function BuildHint(const AStat: TStat): string;
  resourcestring
    SFields = 'The following data is required: %s.';
    SValues = 'Values';
    SWeights = 'Weights';
    SLambda = 'Power (λ)';
    SWholeNumber = 'Values must be whole numbers.';
    SFloatNumber = 'Values can be floating point or whole numbers.';
    SNonNegativeValue = 'Values must all be ≥ 0.';
    SPositiveValue = 'Values must all be > 0.';
    SAnyValue = 'Values can be positive, negative or zero.';
    SExactValues = 'Exactly %d values must be provided.';
    SMinValues = '%d or more values must be provided.';
    SLambdaValue = 'λ must be a floating point number ≠ 0.';
    SWeightsCount = 'There must be exactly one weight per value.';
    SWeightsValue = '''
      Weights are floating point numbers ≥ 0, with at least one weight > 0.
      ''';

    procedure AddLine(const ALine: string);
    begin
      if not Result.IsEmpty then
        Result := Result + sLineBreak;
      Result := Result + ALine;
    end;

  const
    ValueContraints: array[TStatValueRange] of string = (
      SAnyValue, SNonNegativeValue, SPositiveValue
    );
  begin
    Result := string.Empty;
    var DataReqStrs := TList<string>.Create([SValues]);
    try
      if TStatDataRequirement.Weights in AStat.DataRequirements then
        DataReqStrs.Add(SWeights);
      if TStatDataRequirement.Lambda in AStat.DataRequirements then
        DataReqStrs.Add(SLambda);
      AddLine(
        Format(
          SFields,
          [string.Join(fFmtSettings.ListSeparator + ' ', DataReqStrs.ToArray)]
        )
      );
    finally
      DataReqStrs.Free;
    end;
    AddLine(ValueContraints[AStat.ValueRange]);
    AddLine(
      IfThen(
        AStat.ValueType = TStatValueType.WholeNumber,
        SWholeNumber,
        SFloatNumber
      )
    );
    if AStat.ValuesSize = TStatValuesSize.Fixed then
      AddLine(Format(SExactValues, [AStat.SizeLimit]))
    else if (AStat.ValuesSize = TStatValuesSize.Variable)
      and (AStat.SizeLimit > 0) then
      AddLine(Format(SMinValues, [AStat.SizeLimit]));
    if TStatDataRequirement.Weights in AStat.DataRequirements then
    begin
      AddLine(SWeightsCount);
      AddLine(SWeightsValue);
    end;
    if TStatDataRequirement.Lambda in AStat.DataRequirements then
      AddLine(SLambdaValue);
  end;

  procedure CreateButton(var ATop: Double; const ACaption:
    string; AStatClass: TStatClass);
  begin
    var Btn := TStatButton.Create(Self);
    Btn.Parent := ButtonsPanel;
    Btn.Width := 204;
    Btn.Height := 36;
    Btn.Position.X := 0;
    Btn.Position.Y := ATop;
    Btn.Text := ACaption;
    Btn.StyledSettings := Btn.StyledSettings  - [TStyledSetting.Style];
    Btn.Stat := AStatClass.Create(
      ACaption, ValuesProvider, WeightsProvider, LambdaProvider
    );
    Btn.OnClick := StatButtonClick;
    Btn.Hint := BuildHint(Btn.Stat);
    Btn.ShowHint := True;
    ATop := ATop + Btn.Height;
  end;

resourcestring
  SArithmeticMean = 'Arithmetic Mean';
  SWeightedArithmeticMean = 'Weighted Arithmetic Mean';
  SGeometricMean = 'Geometric Mean';
  SWeightedGeometricMean = 'Weighted Geometric Mean';
  SHarmonicMean = 'Harmonic Mean';
  SWeightedHarmonicMean = 'Weighted Harmonic Mean';
  SPowerMean = 'Power Mean';
  SWeightedPowerMean = 'Weighted Power Mean';
  SLogarithmicMean = 'Logarithmic Mean';
  SMedian = 'Median';
  SMode = 'Mode';
  SRMS = 'Root Mean Square (RMS)';
  STSS = 'Total Sum Of Squares (TSS)';
begin
  var BtnTop: Double := 0.0;
  CreateButton(BtnTop, SArithmeticMean, TArithmeticMean);
  CreateButton(BtnTop, SWeightedArithmeticMean, TWeightedArithmeticMean);
  CreateButton(BtnTop, SGeometricMean, TGeometricMean);
  CreateButton(BtnTop, SWeightedGeometricMean, TWeightedGeometricMean);
  CreateButton(BtnTop, SHarmonicMean, THarmonicMean);
  CreateButton(BtnTop, SWeightedHarmonicMean, TWeightedHarmonicMean);
  CreateButton(BtnTop, SPowerMean, TPowerMean);
  CreateButton(BtnTop, SWeightedPowerMean, TWeightedPowerMean);
  CreateButton(BtnTop, SLogarithmicMean, TLogarithmicMean);
  CreateButton(BtnTop, SMedian, TMedian);
  CreateButton(BtnTop, SMode, TMode);
  CreateButton(BtnTop, SRMS, TRMS);
  CreateButton(BtnTop, STSS, TTSS);
  ButtonsPanel.Height := BtnTop;
end;

function TMainForm.DefaultStat: TStat;
begin
  // The default stat is the one associated with the first stat button
  Result := nil;
  for var Ctrl in ButtonsPanel.Controls do
    if (Ctrl is TStatButton) then
      Exit((Ctrl as TStatButton).Stat);
end;

function TMainForm.FindStatButton(const AStat: TStat): TStatButton;
begin
  Result := nil;
  for var Ctrl in ButtonsPanel.Controls do
  begin
    if (Ctrl is TStatButton) then
    begin
      var StatButton := Ctrl as TStatButton;
      if StatButton.Stat = AStat then
        Exit(StatButton);
    end;
  end;
end;

function TMainForm.FormatEnteredData(const AData: array of Double): string;
begin
  Result := SeparateData(AData, sLineBreak);
end;

procedure TMainForm.FormCreate(Sender: TObject);
resourcestring
  SPromptWithComma = '''
    Enter values and weights separated by spaces, new lines or " %s ".
    ''';
  SPromptWithoutComma = '''
    Enter values and weights separated by spaces or new lines.
    ''';
  SFormatPrompt = '''
    Values may be in decimal format (e.g. 1042%0:s56), in exponential format
    (e.g. 1042%0:s23e78) or may be whole numbers.
    ''';
begin
  inherited;
  fFmtSettings := TFormatSettings.Create;   // use user's current locale
  InfoLabel.Text := IfThen(
    CanUseListSeparator,
    Format(SPromptWithComma, [fFmtSettings.ListSeparator]),
    SPromptWithoutComma
  )
  + ' ' +
  Format(
    SFormatPrompt, [fFmtSettings.DecimalSeparator]
  );
  CreateStatButtons;
  SelectStat(DefaultStat);
end;

procedure TMainForm.HelpActionExecute(Sender: TObject);
begin
  THelpForm.Show(Self);
end;

function TMainForm.LambdaProvider: Double;
resourcestring
  SBadNumber = '"%d" is not a valid number for Lambda';
  SMissingValue = 'A value for Lambda is required';
begin
  var LambdaStr := LambdaEdit.Text.Trim;
  if LambdaStr.IsEmpty then
    raise Exception.Create(SMissingValue);
  if not TryStrToFloat(LambdaStr, Result, fFmtSettings) then
    raise Exception.CreateFmt(SBadNumber, [LambdaStr]);
end;

function TMainForm.ParseEnteredNumberList(AText: string): TArray<Double>;
resourcestring
  SBadNumber = '"%s" is not a valid number';
begin
  // If locale's list separator can be used then replace them by spaces
  if CanUseListSeparator then
    AText := AText.Replace(fFmtSettings.ListSeparator, ' ');
  // Create array of entered data
  var DataStrings := CompressWhiteSpace(AText.Trim).Split([' ']);
  // Convert text values to floating point numbers
  SetLength(Result, Length(DataStrings));
  for var Idx := 0 to Pred(Length(DataStrings)) do
  begin
    var Number: Double;
    if not TryStrToFloat(DataStrings[Idx].Trim, Number, fFmtSettings) then
      raise Exception.CreateFmt(SBadNumber, [DataStrings[Idx]]);
    // Can't pass Result[Idx] as a parameter to TryStrToFloat: causes crash
    Result[Idx] := Number;
  end;
end;

procedure TMainForm.SelectStat(const AStat: TStat);

  procedure ChangeButtonHighlight(const NewButton: TStatButton);
  begin
    if Assigned(fPrevStatButton) then
      fPrevStatButton.Font.Style := fPrevStatButton.Font.Style
        - [TFontStyle.fsBold];
    NewButton.Font.Style := NewButton.Font.Style + [TFontStyle.fsBold];
    fPrevStatButton := NewButton;
  end;

begin
  Assert(Assigned(AStat));
  // Make given stat current
  fCurrentStat := AStat;
  // Update controls
  var ClickedBtn := FindStatButton(AStat);
  Assert(Assigned(ClickedBtn));
  if fPrevStatButton <> ClickedBtn then
  begin
    ChangeButtonHighlight(ClickedBtn);
    HeadingLabel.Text := AStat.DisplayName;
    WeightsPanel.Enabled := TStatDataRequirement.Weights
      in AStat.DataRequirements;
    LambdaPanel.Enabled := TStatDataRequirement.Lambda
      in AStat.DataRequirements;
    ResultEdit.Text := string.Empty;
    fPrevStatButton := ClickedBtn;
  end;
end;

function TMainForm.SeparateData(const AData: array of Double;
  const ASeparator: string): string;
begin
  if Length(AData) = 0 then
    Exit(string.Empty);
  Result := AData[0].ToString(fFmtSettings);
  for var Idx := 1 to Pred(Length(AData)) do
    Result := Result + ASeparator + AData[Idx].ToString(fFmtSettings);
end;

procedure TMainForm.SettingsActionExecute(Sender: TObject);
begin
  TSettingsForm.Execute(Self);
end;

procedure TMainForm.StatButtonClick(Sender: TObject);
begin
  SelectStat((Sender as TStatButton).Stat);
end;

function TMainForm.ValuesProvider: TArray<Double>;
begin
  try
    Result := ParseEnteredNumberList(ValuesMemo.Text);
  except
    on E: Exception do
      raise Exception.Create('Error in values: ' + E.Message);
  end;
end;

function TMainForm.WeightsProvider: TArray<Double>;
begin
  try
    Result := ParseEnteredNumberList(WeightsMemo.Text);
  except
    on E: Exception do
      raise Exception.Create('Error in weights: ' + E.Message);
  end;
end;

{ TMainForm.TStatButton }

destructor TMainForm.TStatButton.Destroy;
begin
  fStat.Free;
  inherited;
end;

end.
