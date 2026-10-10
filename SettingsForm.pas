unit SettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TFormSettings = class(TForm)
    grpGames: TGroupBox;
    lblHL: TLabel;
    edtHL: TEdit;
    btnBrowseHL: TButton;
    lblCS: TLabel;
    edtCS: TEdit;
    btnBrowseCS: TButton;
    grpMasterServers: TGroupBox;
    lblMasterList: TLabel;
    mmoMasterServers: TMemo;
    grpFilters: TGroupBox;
    lblFilterList: TLabel;
    mmoGameFilters: TMemo;
    grpQuery: TGroupBox;
    lblThreads: TLabel;
    cbThreads: TComboBox;
    lblTimeout: TLabel;
    cbTimeout: TComboBox;
    lblRegion: TLabel;
    cbRegion: TComboBox;
    lblLimit: TLabel;
    cbLimit: TComboBox;
    grpAppearance: TGroupBox;
    lblTheme: TLabel;
    cbTheme: TComboBox;
    grpFilterOptions: TGroupBox;
    chkHideEmpty: TCheckBox;
    chkHideUnresponsive: TCheckBox;
    chkAutoRefresh: TCheckBox;
    lblSort: TLabel;
    cbSort: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    dlgOpen: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnBrowseHLClick(Sender: TObject);
    procedure btnBrowseCSClick(Sender: TObject);
  public
    function GetSortIndex: Integer;
    procedure SetSortIndex(Value: Integer);
    function GetMasterServers: TArray<string>;
    procedure SetMasterServers(const List: TArray<string>);
    function GetGameFilters: TArray<string>;
    procedure SetGameFilters(const List: TArray<string>);
    function GetThreadCount: Integer;
    procedure SetThreadCount(Value: Integer);
    function GetTimeoutMs: Integer;
    procedure SetTimeoutMs(Value: Integer);
    function GetRegionByte: Byte;
    procedure SetRegionByte(Value: Byte);
    function GetLimitCount: Integer;
    procedure SetLimitCount(Value: Integer);
    function GetHideEmpty: Boolean;
    procedure SetHideEmpty(Value: Boolean);
    function GetHideUnresponsive: Boolean;
    procedure SetHideUnresponsive(Value: Boolean);
    function GetAutoRefresh: Boolean;
    procedure SetAutoRefresh(Value: Boolean);
    function GetAppStyle: string;
    procedure SetAppStyle(const Value: string);
  end;

var
  FormSettings: TFormSettings;

implementation

{$R *.dfm}

procedure TFormSettings.FormCreate(Sender: TObject);
begin
  Caption := 'MSMonitor Settings';
  grpGames.Caption := ' Game Executables (.exe / .cmd) ';
  lblHL.Caption := 'Half-Life 1 Executable (hl.exe, RUN_HL.exe):';
  lblCS.Caption := 'Counter-Strike 1.6 Executable (hl.exe, cstrike.exe):';
  btnBrowseHL.Caption := 'Browse...';
  btnBrowseCS.Caption := 'Browse...';

  grpMasterServers.Caption := ' Master Servers ';
  lblMasterList.Caption := 'Servers (host:port, one per line):';

  grpFilters.Caption := ' Game Filters (gamedir) ';
  lblFilterList.Caption := 'Game mods (one per line):';

  grpQuery.Caption := ' Query Settings ';
  lblThreads.Caption := 'Query threads (1-10 threads):';
  lblTimeout.Caption := 'Query timeout (A2S_INFO):';
  lblRegion.Caption := 'Region:';
  lblLimit.Caption := 'Server limit per master:';

  grpAppearance.Caption := ' Appearance Style ';
  lblTheme.Caption := 'Theme:';
  cbTheme.Items.Clear;
  cbTheme.Items.Add('Light Style (Default)');
  cbTheme.Items.Add('Dark Style (Windows 10 Dark)');
  cbTheme.ItemIndex := 0;

  grpFilterOptions.Caption := ' Sorting, Filtering and Auto-Refresh ';
  chkHideEmpty.Caption := 'Hide empty servers (0 players)';
  chkHideUnresponsive.Caption := 'Hide unresponsive servers (query timeout)';
  chkAutoRefresh.Caption := 'Automatically refresh servers in background every minute';
  lblSort.Caption := 'List sorting:';

  cbSort.Items.Clear;
  cbSort.Items.Add('By ping (ascending, lowest ping first)');
  cbSort.Items.Add('By players (descending, highest players first)');
  cbSort.Items.Add('By server name (A-Z)');
  cbSort.Items.Add('By map (A-Z)');
  cbSort.Items.Add('By mod / folder (A-Z)');
  cbSort.Items.Add('By IP address and port');
  cbSort.Items.Add('By master server (A-Z)');
  cbSort.ItemIndex := 0;

  btnOK.Caption := 'Save';
  btnCancel.Caption := 'Cancel';

  cbThreads.Items.Clear;
  cbThreads.Items.Add('1 thread');
  cbThreads.Items.Add('2 threads');
  cbThreads.Items.Add('3 threads');
  cbThreads.Items.Add('4 threads');
  cbThreads.Items.Add('5 threads');
  cbThreads.Items.Add('6 threads');
  cbThreads.Items.Add('7 threads');
  cbThreads.Items.Add('8 threads');
  cbThreads.Items.Add('9 threads');
  cbThreads.Items.Add('10 threads (Maximum)');

  cbTimeout.Items.Clear;
  cbTimeout.Items.Add('350 ms (Fast)');
  cbTimeout.Items.Add('600 ms (Normal)');
  cbTimeout.Items.Add('1000 ms (Deep)');

  cbRegion.Items.Clear;
  cbRegion.Items.Add('Worldwide (0xFF)');
  cbRegion.Items.Add('Europe (0x03)');
  cbRegion.Items.Add('US East (0x00)');
  cbRegion.Items.Add('US West (0x01)');
  cbRegion.Items.Add('Asia (0x04)');

  cbLimit.Items.Clear;
  cbLimit.Items.Add('200 servers');
  cbLimit.Items.Add('600 servers');
  cbLimit.Items.Add('1000 servers');
  cbLimit.Items.Add('3000 servers');
  cbLimit.Items.Add('All available');
end;

procedure TFormSettings.btnBrowseHLClick(Sender: TObject);
begin
  dlgOpen.Title := 'Select Half-Life 1 Executable (hl.exe, RUN_HL.exe, .cmd)';
  if (edtHL.Text <> '') and FileExists(edtHL.Text) then
  begin
    dlgOpen.InitialDir := ExtractFilePath(edtHL.Text);
    dlgOpen.FileName := edtHL.Text;
  end
  else if DirectoryExists('C:\Games\Half-Life') then
    dlgOpen.InitialDir := 'C:\Games\Half-Life';

  if dlgOpen.Execute then
    edtHL.Text := dlgOpen.FileName;
end;

procedure TFormSettings.btnBrowseCSClick(Sender: TObject);
begin
  dlgOpen.Title := 'Select Counter-Strike 1.6 Executable (hl.exe, cstrike.exe, .cmd)';
  if (edtCS.Text <> '') and FileExists(edtCS.Text) then
  begin
    dlgOpen.InitialDir := ExtractFilePath(edtCS.Text);
    dlgOpen.FileName := edtCS.Text;
  end
  else if DirectoryExists('C:\Games\Counter-Strike 1.6') then
    dlgOpen.InitialDir := 'C:\Games\Counter-Strike 1.6'
  else if DirectoryExists('C:\Games\CS 1.6') then
    dlgOpen.InitialDir := 'C:\Games\CS 1.6';

  if dlgOpen.Execute then
    edtCS.Text := dlgOpen.FileName;
end;

function TFormSettings.GetMasterServers: TArray<string>;
var
  i: Integer;
  Line: string;
  Res: TStringList;
begin
  Res := TStringList.Create;
  try
    for i := 0 to mmoMasterServers.Lines.Count - 1 do
    begin
      Line := Trim(mmoMasterServers.Lines[i]);
      if (Line <> '') and not CharInSet(Line[1], [';', '#']) then
        Res.Add(Line);
    end;

    SetLength(Result, Res.Count);
    for i := 0 to Res.Count - 1 do
      Result[i] := Res[i];
  finally
    Res.Free;
  end;
end;

procedure TFormSettings.SetMasterServers(const List: TArray<string>);
var
  i: Integer;
begin
  mmoMasterServers.Lines.Clear;
  for i := 0 to High(List) do
    if Trim(List[i]) <> '' then
      mmoMasterServers.Lines.Add(Trim(List[i]));
end;

function TFormSettings.GetGameFilters: TArray<string>;
var
  i: Integer;
  Line: string;
  Res: TStringList;
begin
  Res := TStringList.Create;
  try
    for i := 0 to mmoGameFilters.Lines.Count - 1 do
    begin
      Line := Trim(mmoGameFilters.Lines[i]);
      if (Line <> '') and not CharInSet(Line[1], [';', '#']) then
        Res.Add(Line);
    end;

    SetLength(Result, Res.Count);
    for i := 0 to Res.Count - 1 do
      Result[i] := Res[i];
  finally
    Res.Free;
  end;
end;

procedure TFormSettings.SetGameFilters(const List: TArray<string>);
var
  i: Integer;
begin
  mmoGameFilters.Lines.Clear;
  for i := 0 to High(List) do
    if Trim(List[i]) <> '' then
      mmoGameFilters.Lines.Add(Trim(List[i]));
end;

function TFormSettings.GetThreadCount: Integer;
begin
  Result := cbThreads.ItemIndex + 1;
  if Result < 1 then Result := 1;
  if Result > 10 then Result := 10;
end;

procedure TFormSettings.SetThreadCount(Value: Integer);
begin
  if Value < 1 then Value := 1;
  if Value > 10 then Value := 10;
  cbThreads.ItemIndex := Value - 1;
end;

function TFormSettings.GetTimeoutMs: Integer;
begin
  case cbTimeout.ItemIndex of
    0: Result := 350;
    1: Result := 600;
    2: Result := 1000;
  else
    Result := 350;
  end;
end;

procedure TFormSettings.SetTimeoutMs(Value: Integer);
begin
  case Value of
    1..450: cbTimeout.ItemIndex := 0;   // 350ms
    451..800: cbTimeout.ItemIndex := 1; // 600ms
  else
    cbTimeout.ItemIndex := 2;           // 1000ms
  end;
end;

function TFormSettings.GetRegionByte: Byte;
begin
  case cbRegion.ItemIndex of
    0: Result := $FF; // All
    1: Result := $03; // Europe
    2: Result := $00; // US East
    3: Result := $01; // US West
    4: Result := $04; // Asia
  else
    Result := $FF;
  end;
end;

procedure TFormSettings.SetRegionByte(Value: Byte);
begin
  case Value of
    $03: cbRegion.ItemIndex := 1;
    $00: cbRegion.ItemIndex := 2;
    $01: cbRegion.ItemIndex := 3;
    $04: cbRegion.ItemIndex := 4;
  else
    cbRegion.ItemIndex := 0;
  end;
end;

function TFormSettings.GetLimitCount: Integer;
begin
  case cbLimit.ItemIndex of
    0: Result := 200;
    1: Result := 600;
    2: Result := 1000;
    3: Result := 3000;
  else
    Result := 0; // All
  end;
end;

procedure TFormSettings.SetLimitCount(Value: Integer);
begin
  case Value of
    200: cbLimit.ItemIndex := 0;
    600: cbLimit.ItemIndex := 1;
    1000: cbLimit.ItemIndex := 2;
    3000: cbLimit.ItemIndex := 3;
  else
    cbLimit.ItemIndex := 4; // All
  end;
end;

function TFormSettings.GetHideEmpty: Boolean;
begin
  Result := chkHideEmpty.Checked;
end;

procedure TFormSettings.SetHideEmpty(Value: Boolean);
begin
  chkHideEmpty.Checked := Value;
end;

function TFormSettings.GetHideUnresponsive: Boolean;
begin
  Result := chkHideUnresponsive.Checked;
end;

procedure TFormSettings.SetHideUnresponsive(Value: Boolean);
begin
  chkHideUnresponsive.Checked := Value;
end;

function TFormSettings.GetAutoRefresh: Boolean;
begin
  Result := chkAutoRefresh.Checked;
end;

procedure TFormSettings.SetAutoRefresh(Value: Boolean);
begin
  chkAutoRefresh.Checked := Value;
end;

function TFormSettings.GetAppStyle: string;
begin
  if cbTheme.ItemIndex = 1 then
    Result := 'Windows10 Dark'
  else
    Result := 'Windows10';
end;

procedure TFormSettings.SetAppStyle(const Value: string);
begin
  if SameText(Value, 'Windows10 Dark') or SameText(Value, 'Dark') then
    cbTheme.ItemIndex := 1
  else
    cbTheme.ItemIndex := 0;
end;

function TFormSettings.GetSortIndex: Integer;
begin
  Result := cbSort.ItemIndex;
  if Result < 0 then
    Result := 0;
end;

procedure TFormSettings.SetSortIndex(Value: Integer);
begin
  if (Value >= 0) and (Value < cbSort.Items.Count) then
    cbSort.ItemIndex := Value
  else
    cbSort.ItemIndex := 0;
end;

end.
