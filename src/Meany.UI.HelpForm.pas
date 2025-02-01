{
  Copyright (c) 2025, Peter Johnson, delphidabbler.com
  MIT License
  https://github.com/ddabapps/meany
}

unit Meany.UI.HelpForm;

interface

uses
  System.UITypes,
  System.Classes,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Memo,
  FMX.Memo.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Controls.Presentation,
  FMX.ScrollBox;

type
  THelpForm = class(TForm)
    HelpMemo: TMemo;
    BottomPanel: TPanel;
    CloseButton: TCornerButton;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar;
      Shift: TShiftState);
  public
    class procedure Show(const AOwner: TComponent);
  end;

implementation

{$R *.fmx}

{ THelpForm }

procedure THelpForm.FormCreate(Sender: TObject);
begin
  HelpMemo.WordWrap := True;
end;

procedure THelpForm.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkEscape then
    Close;
end;

class procedure THelpForm.Show(const AOwner: TComponent);
begin
  var Dlg := THelpForm.Create(AOwner);
  try
    Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

end.
