program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {FormMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
