program MSMonitor;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  System.SysUtils,
  System.Win.Registry,
  Winapi.Windows,
  MainForm in 'MainForm.pas' {FormMain},
  SettingsForm in 'SettingsForm.pas' {FormSettings},
  HLMasterProtocol in 'HLMasterProtocol.pas',
  MSCliRunner in 'MSCliRunner.pas';

{$R *.res}

var
  Reg: TRegistry;
  SavedStyle: string;
begin
  // Unified executable: if launched from command line with arguments or switches, run CLI mode
  if FindCmdLineSwitch('cli') or FindCmdLineSwitch('help') or
     FindCmdLineSwitch('h') or FindCmdLineSwitch('?') or
     FindCmdLineSwitch('host') or FindCmdLineSwitch('filter') or
     FindCmdLineSwitch('limit') or FindCmdLineSwitch('timeout') or
     FindCmdLineSwitch('region') or FindCmdLineSwitch('threads') or
     ((ParamCount >= 1) and not SameText(ExtractFileName(ParamStr(1)), 'msmonitor.exe')) then
  begin
    RunCliMode;
    Exit;
  end;

  // Otherwise run GUI mode
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // Default is light style ('Windows10')
  SavedStyle := 'Windows10';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\MSMonitor') then
    begin
      if Reg.ValueExists('AppStyle') then
        SavedStyle := Reg.ReadString('AppStyle');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  if SameText(SavedStyle, 'Windows10 Dark') or SameText(SavedStyle, 'Dark') then
  begin
    if not TStyleManager.TrySetStyle('Windows10 Dark') then
      if FileExists('Windows10Dark.vsf') then
        TStyleManager.SetStyle(TStyleManager.LoadFromFile('Windows10Dark.vsf'));
  end
  else
  begin
    if not TStyleManager.TrySetStyle('Windows10') then
      if FileExists('Windows10.vsf') then
        TStyleManager.SetStyle(TStyleManager.LoadFromFile('Windows10.vsf'));
  end;

  Application.Title := 'Half-Life & GoldSrc MasterServer Monitor';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
