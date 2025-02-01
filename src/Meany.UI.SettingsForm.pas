{
  Copyright (c) 2025, Peter Johnson, delphidabbler.com
  MIT License
  https://github.com/ddabapps/meany
}

unit Meany.UI.SettingsForm;

interface

uses
  System.Classes,
  System.Variants,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Types,
  FMX.Controls,
  FMX.Controls.Presentation;

type
  TSettingsForm = class(TForm)
    HoldingTextLabel: TLabel;
  public
    class function Execute(AOwner: TComponent): Boolean;
  end;

implementation

uses
  System.UITypes;

{$R *.fmx}

{ TSettingsForm }

class function TSettingsForm.Execute(AOwner: TComponent): Boolean;
begin
  var Dlg := TSettingsForm.Create(AOwner);
  try
    Result := Dlg.ShowModal = mrOK;
  finally
    Dlg.Free;
  end;
end;

end.
