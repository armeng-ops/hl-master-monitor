program MSCli;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  HLMasterProtocol in 'HLMasterProtocol.pas',
  MSCliRunner in 'MSCliRunner.pas';

begin
  try
    RunCliMode;
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
end.
