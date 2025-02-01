unit Meany.MainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Actions,
  FMX.ActnList, FMX.ListBox, FMX.Layouts, FMX.Memo.Types, FMX.StdCtrls,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.Edit,

  System.Math,
  FMX.Objects,
  Meany.Stats, System.ImageList, FMX.ImgList;

type
  TMainForm = class(TForm)
    ActionList: TActionList;
    pnlValues: TPanel;
    lblValues: TLabel;
    memoValues: TMemo;
    pnlWeights: TPanel;
    lblWeights: TLabel;
    memoWeights: TMemo;
    lblInfo1: TLabel;
    actCalculate: TAction;
    lblInfo2: TLabel;
    pnlButtons: TPanel;
    lblHeading: TLabel;
    pnlLambda: TPanel;
    lblLambda: TLabel;
    edLambda: TEdit;
    btnCalculate: TCornerButton;
    lblResult: TLabel;
    edResult: TEdit;
    ImageList: TImageList;
    btnSettings: TButton;
    actSettings: TAction;
    btnHelp: TButton;
    actHelp: TAction;
    StyleBook1: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure actCalculateUpdate(Sender: TObject);
    procedure actCalculateExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actSettingsExecute(Sender: TObject);
    procedure actHelpExecute(Sender: TObject);
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
  System.Character;

{$R *.fmx}

{ TMainForm }

procedure TMainForm.actCalculateExecute(Sender: TObject);
resourcestring
  SNoValues = 'You must enter at least one value';
  SBadWeightCount = 'You must enter the same number of weights as values';
begin
  // Convert layout of entered values and weights into one number per line
  var Values := ParseEnteredNumberList(memoValues.Text);
  var Weights := ParseEnteredNumberList(memoWeights.Text);
  memoValues.Text := FormatEnteredData(Values);
  memoWeights.Text := FormatEnteredData(Weights);
  // Perform calculation
  edResult.Text := fCurrentStat.Calculate(fFmtSettings);
end;

procedure TMainForm.actCalculateUpdate(Sender: TObject);
begin
  actCalculate.Enabled := Assigned(fCurrentStat) and
    (memoValues.Lines.Count > 0);
end;

procedure TMainForm.actHelpExecute(Sender: TObject);
begin
  ShowMessage('Help here');
end;

procedure TMainForm.actSettingsExecute(Sender: TObject);
begin
  ShowMessage('Settings here');
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
//        'RMS',
//        'Total Sum Of Squares'

  procedure CreateButton(var ATop: Double; const ACaption:
    string; AStatClass: TStatClass);
  begin
    var Btn := TStatButton.Create(Self);
    Btn.Parent := pnlButtons;
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
    ATop := ATop + Btn.Height;
  end;

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
  pnlButtons.Height := BtnTop;
end;

function TMainForm.DefaultStat: TStat;
begin
  // The default stat is the one associated with the first stat button
  Result := nil;
  for var Ctrl in pnlButtons.Controls do
    if (Ctrl is TStatButton) then
      Exit((Ctrl as TStatButton).Stat);
end;

function TMainForm.FindStatButton(const AStat: TStat): TStatButton;
begin
  Result := nil;
  for var Ctrl in pnlButtons.Controls do
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
    Values may be whole numbers, in decimal format (e.g. 1042%0:s56), or in
    exponential format (e.g. 1042%0:s23e78).
    ''';
begin
  inherited;
  fFmtSettings := TFormatSettings.Create;   // use user's current locale
  lblInfo1.Text := IfThen(
    CanUseListSeparator,
    Format(SPromptWithComma, [fFmtSettings.ListSeparator]),
    SPromptWithoutComma
  );
  lblInfo2.Text := Format(
    SFormatPrompt, [fFmtSettings.DecimalSeparator]
  );
  CreateStatButtons;
  SelectStat(DefaultStat);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
//  for var Ctrl in pnlButton.Controls do
//    if Ctrl is TStatButton then
//    begin
//      TStatButton(Ctrl).Stat.Free;
//    end;
  inherited;
end;

function TMainForm.LambdaProvider: Double;
resourcestring
  SBadNumber = '"%d" is not a valid number for Lambda';
  SMissingValue = 'A value for Lambda is required';
begin
  var LambdaStr := edLambda.Text.Trim;
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
    lblHeading.Text := AStat.DisplayName;
    pnlWeights.Enabled := AStat.RequiresWeigths;
    pnlLambda.Enabled := AStat.RequiresLambda;
    edResult.Text := string.Empty;
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

procedure TMainForm.StatButtonClick(Sender: TObject);
begin
  SelectStat((Sender as TStatButton).Stat);
end;

function TMainForm.ValuesProvider: TArray<Double>;
begin
  try
    Result := ParseEnteredNumberList(memoValues.Text);
  except
    on E: Exception do
      raise Exception.Create('Error in values: ' + E.Message);
  end;
end;

function TMainForm.WeightsProvider: TArray<Double>;
begin
  try
    Result := ParseEnteredNumberList(memoWeights.Text);
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
