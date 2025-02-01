program Meany;

uses
  System.StartUpCopy,
  FMX.Forms,
  Meany.UI.MainForm in 'Meany.UI.MainForm.pas' {MainForm},
  Meany.AverageFns in 'Meany.AverageFns.pas',
  Meany.Validators in 'Meany.Validators.pas',
  Meany.Stats in 'Meany.Stats.pas',
  Meany.UI.HelpForm in 'Meany.UI.HelpForm.pas' {HelpForm},
  Meany.UI.SettingsForm in 'Meany.UI.SettingsForm.pas' {SettingsForm};

{$R *.res}

{$IFDEF MSWINDOWS}
  {$R Version.res}
{$ENDIF}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
