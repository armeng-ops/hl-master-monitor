unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.CommCtrl, System.SysUtils, System.Variants, System.Classes,
  System.UITypes, System.Win.Registry, System.Math, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Clipbrd, Vcl.Themes, Vcl.Styles, Vcl.Menus, HLMasterProtocol, SettingsForm;

type
  TFormMain = class(TForm)
    pnlButtons: TPanel;
    btnFetch: TButton;
    btnStop: TButton;
    btnFavorite: TButton;
    btnSettings: TButton;
    btnConnect: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    btnClear: TButton;
    lvServers: TListView;
    pnlBottom: TPanel;
    pbProgress: TProgressBar;
    sbStatus: TStatusBar;
    dlgSave: TSaveDialog;
    tmrAutoStart: TTimer;
    pmServers: TPopupMenu;
    miFavorite: TMenuItem;
    miSep1: TMenuItem;
    miConnect: TMenuItem;
    miCopy: TMenuItem;
    miSep2: TMenuItem;
    miRefreshOne: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnFetchClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnFavoriteClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure lvServersColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvServersCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure lvServersCustomDrawItem(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvServersCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvServersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure miRefreshOneClick(Sender: TObject);
    procedure tmrAutoStartTimer(Sender: TObject);
    procedure tmrAutoRefreshTimer(Sender: TObject);
  private
    FMasterServers: TArray<string>;
    FGameFilters: TArray<string>;
    FRegionByte: Byte;
    FLimitCount: Integer;
    FTimeoutMs: Integer;
    FThreadCount: Integer;
    FHLPath: string;
    FCSPath: string;
    FHideEmpty: Boolean;
    FHideUnresponsive: Boolean;
    FAutoRefresh: Boolean;
    FAppStyle: string;
    tmrAutoRefresh: TTimer;
    FServerToItem: TArray<TListItem>;

    FMultiMasterThread: TMultiMasterQueryThread;
    FInfoThread: TA2SInfoThread;
    FFavInfoThread: TA2SInfoThread;
    FFavorites: TStringList;
    tmrFavoritesRefresh: TTimer;
    FServers: TServerArray;
    FRespondedCount: Integer;
    FSortIndex: Integer;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    FIsStopping: Boolean;
    FSortPending: Boolean;
    FLastSortTick: UInt64;
    tmrSortThrottle: TTimer;
    FOldListViewWndProc: TWndMethod;

    procedure RequestSort;
    procedure DoApplySort;
    procedure ListViewWndProc(var Msg: TMessage);
    procedure tmrSortThrottleTimer(Sender: TObject);

    procedure OnMasterBatch(const Servers: TServerArray);
    procedure OnServerInfoUpdate(Index: Integer; const Server: TServerInfo);
    procedure OnWorkerStatus(const StatusText: string; Progress, Total: Integer);
    procedure OnMasterStatus(const StatusText: string; Progress, Total: Integer);
    procedure OnMasterFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
    procedure OnInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);

    function IsDarkTheme: Boolean;
    procedure ApplyAppStyle(const StyleName: string);
    function FindItemByServerIndex(Index: Integer): TListItem;
    procedure RebuildListView;
    procedure SetWorking(IsBusy: Boolean);
    procedure RenumberList;

    procedure tmrFavoritesRefreshTimer(Sender: TObject);
    procedure OnFavInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
    function IsFavorite(const IP: string; Port: Word): Boolean;
    function IsItemFavorite(Item: TListItem): Boolean;
    procedure LoadFavoritesFromRegistry;
    procedure SaveFavoritesToRegistry;
    procedure UpdateFavoriteButtonState;

    procedure ApplySortIndex(Index: Integer);
    procedure ApplySort;
    procedure LoadSettingsFromRegistry;
    procedure SaveSettingsToRegistry;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

const
  VERIFIED_ACTIVE_MASTERS: array[0..6] of string = (
    'hl1.master.direct:27010',
    'ms.cs16.net:27010',
    'ms.gs-monitor.com:27010',
    'ms.varq.net:27010',
    'ms.tsarvar.com:27010',
    'master.csmetahook.com:27010',
    'masterserver.csboost.eu:27010'
  );

function IsDeadMaster(const S: string): Boolean;
var
  Low: string;
begin
  Low := LowerCase(Trim(S));
  Result := (Low = '') or
            (Pos('topms.ru', Low) > 0) or
            (Pos('steampowered.com', Low) > 0) or
            (Pos('188.40.40.201', Low) > 0) or
            (Pos('194.87.101.97', Low) > 0) or
            (Pos('gs4u.net', Low) > 0) or
            (Pos('csserv.ru', Low) > 0) or
            (Pos('hldm.org', Low) > 0);
end;

procedure TFormMain.LoadSettingsFromRegistry;
var
  Reg: TRegistry;
  Lines: TStringList;
  i, j: Integer;
  RawText: string;
  Found: Boolean;
  NeedSave: Boolean;
begin
  NeedSave := False;
  FHLPath := '';
  FCSPath := '';
  FThreadCount := 10;
  FTimeoutMs := 350;
  FRegionByte := $FF;
  FLimitCount := 600;
  FHideEmpty := True;
  FHideUnresponsive := True;
  FAutoRefresh := True;
  FAppStyle := 'Windows10';
  FSortIndex := 0;

  // Defaults for Master Servers (all verified active public GoldSrc master servers)
  SetLength(FMasterServers, Length(VERIFIED_ACTIVE_MASTERS));
  for i := 0 to High(VERIFIED_ACTIVE_MASTERS) do
    FMasterServers[i] := VERIFIED_ACTIVE_MASTERS[i];

  // Defaults for Game Filters (all active GoldSrc mods)
  SetLength(FGameFilters, 6);
  FGameFilters[0] := 'valve';
  FGameFilters[1] := 'cstrike';
  FGameFilters[2] := 'ag';
  FGameFilters[3] := 'gearbox';
  FGameFilters[4] := 'dod';
  FGameFilters[5] := 'tfc';

  Lines := TStringList.Create;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\MSMonitor') then
    begin
      if Reg.ValueExists('HLPath') then
        FHLPath := Reg.ReadString('HLPath');
      if Reg.ValueExists('CSPath') then
        FCSPath := Reg.ReadString('CSPath');

      if (FHLPath = '') and Reg.ValueExists('GamePath') then
        FHLPath := Reg.ReadString('GamePath');

      if Reg.ValueExists('Threads') then
      begin
        try
          FThreadCount := Reg.ReadInteger('Threads');
        except
          FThreadCount := StrToIntDef(Reg.ReadString('Threads'), 10);
        end;
      end;

      if Reg.ValueExists('Timeout') then
      begin
        try
          FTimeoutMs := Reg.ReadInteger('Timeout');
        except
          FTimeoutMs := StrToIntDef(Reg.ReadString('Timeout'), 350);
        end;
      end;

      if Reg.ValueExists('Region') then
      begin
        try
          FRegionByte := Byte(Reg.ReadInteger('Region'));
        except
          FRegionByte := $FF;
        end;
      end;

      if Reg.ValueExists('Limit') then
      begin
        try
          FLimitCount := Reg.ReadInteger('Limit');
        except
          FLimitCount := 600;
        end;
      end;

      // MasterServers list: clean out dead ones and ensure verified ones are present
      if Reg.ValueExists('MasterServers') then
      begin
        RawText := Reg.ReadString('MasterServers');
        Lines.Text := RawText;

        // 1. Remove dead/empty master servers
        for i := Lines.Count - 1 downto 0 do
        begin
          if IsDeadMaster(Lines[i]) then
          begin
            Lines.Delete(i);
            NeedSave := True;
          end;
        end;

        // 2. Ensure all verified active master servers are present
        for i := 0 to High(VERIFIED_ACTIVE_MASTERS) do
        begin
          Found := False;
          for j := 0 to Lines.Count - 1 do
          begin
            if SameText(Trim(Lines[j]), VERIFIED_ACTIVE_MASTERS[i]) then
            begin
              Found := True;
              Break;
            end;
          end;
          if not Found then
          begin
            Lines.Add(VERIFIED_ACTIVE_MASTERS[i]);
            NeedSave := True;
          end;
        end;

        if Lines.Count > 0 then
        begin
          SetLength(FMasterServers, Lines.Count);
          for i := 0 to Lines.Count - 1 do
            FMasterServers[i] := Trim(Lines[i]);
        end;
      end;

      // GameFilters list
      if Reg.ValueExists('GameFilters') then
      begin
        RawText := Reg.ReadString('GameFilters');
        Lines.Text := RawText;
        if Lines.Count > 0 then
        begin
          SetLength(FGameFilters, Lines.Count);
          for i := 0 to Lines.Count - 1 do
            FGameFilters[i] := Trim(Lines[i]);
        end;
      end;

      if Reg.ValueExists('HideEmpty') then
      begin
        try
          FHideEmpty := Reg.ReadBool('HideEmpty');
        except
          FHideEmpty := True;
        end;
      end;

      if Reg.ValueExists('HideUnresponsive') then
      begin
        try
          FHideUnresponsive := Reg.ReadBool('HideUnresponsive');
        except
          FHideUnresponsive := True;
        end;
      end;

      if Reg.ValueExists('AutoRefresh') then
      begin
        try
          FAutoRefresh := Reg.ReadBool('AutoRefresh');
        except
          FAutoRefresh := True;
        end;
      end;

      if Reg.ValueExists('AppStyle') then
      begin
        FAppStyle := Reg.ReadString('AppStyle');
        if Trim(FAppStyle) = '' then
          FAppStyle := 'Windows10';
      end;

      if Reg.ValueExists('SortIndex') then
      begin
        try
          FSortIndex := Reg.ReadInteger('SortIndex');
        except
          FSortIndex := 0;
        end;
      end;

      Reg.CloseKey;
    end;
  finally
    Reg.Free;
    Lines.Free;
  end;

  ApplySortIndex(FSortIndex);

  if NeedSave then
    SaveSettingsToRegistry;

  if FThreadCount < 1 then FThreadCount := 1;
  if FThreadCount > 10 then FThreadCount := 10;
  if FTimeoutMs <= 0 then FTimeoutMs := 350;
end;

procedure TFormMain.SaveSettingsToRegistry;
var
  Reg: TRegistry;
  Lines: TStringList;
  i: Integer;
begin
  Lines := TStringList.Create;
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\MSMonitor', True) then
    begin
      Reg.WriteString('HLPath', FHLPath);
      Reg.WriteString('CSPath', FCSPath);
      Reg.WriteString('GamePath', FHLPath);
      Reg.WriteInteger('Threads', FThreadCount);
      Reg.WriteInteger('Timeout', FTimeoutMs);
      Reg.WriteInteger('Region', FRegionByte);
      Reg.WriteInteger('Limit', FLimitCount);
      Reg.WriteBool('HideEmpty', FHideEmpty);
      Reg.WriteBool('HideUnresponsive', FHideUnresponsive);
      Reg.WriteBool('AutoRefresh', FAutoRefresh);
      Reg.WriteString('AppStyle', FAppStyle);
      Reg.WriteInteger('SortIndex', FSortIndex);

      Lines.Clear;
      for i := 0 to High(FMasterServers) do
        if Trim(FMasterServers[i]) <> '' then
          Lines.Add(Trim(FMasterServers[i]));
      Reg.WriteString('MasterServers', Lines.Text);

      Lines.Clear;
      for i := 0 to High(FGameFilters) do
        if Trim(FGameFilters[i]) <> '' then
          Lines.Add(Trim(FGameFilters[i]));
      Reg.WriteString('GameFilters', Lines.Text);

      Reg.CloseKey;
    end;
  finally
    Reg.Free;
    Lines.Free;
  end;
end;

procedure TFormMain.LoadFavoritesFromRegistry;
var
  Reg: TRegistry;
  Lines: TStringList;
  i, P, ExistingIdx: Integer;
  Line, Addr, SName, SMap, SMod, SGame, SMaster: string;
  Parts: TArray<string>;
  SIP: string;
  SPort: Word;
begin
  if not Assigned(FFavorites) then
  begin
    FFavorites := TStringList.Create;
    FFavorites.Sorted := True;
    FFavorites.Duplicates := dupIgnore;
  end;
  FFavorites.Clear;

  Lines := TStringList.Create;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\MSMonitor\Favorites') then
    begin
      if Reg.ValueExists('List') then
      begin
        Lines.Text := Reg.ReadString('List');
        for i := 0 to Lines.Count - 1 do
        begin
          Line := Trim(Lines[i]);
          if Line = '' then Continue;
          Parts := Line.Split(['|']);
          Addr := Trim(Parts[0]);
          if Addr = '' then Continue;
          FFavorites.Add(Addr);

          P := Pos(':', Addr);
          if P > 0 then
          begin
            SIP := Copy(Addr, 1, P - 1);
            SPort := Word(StrToIntDef(Copy(Addr, P + 1, MaxInt), 27015));
            SName := '';
            SMap := '';
            SMod := 'valve';
            SGame := 'Half-Life';
            SMaster := 'Favorite';

            if Length(Parts) > 1 then SName := Parts[1];
            if Length(Parts) > 2 then SMap := Parts[2];
            if Length(Parts) > 3 then SMod := Parts[3];
            if Length(Parts) > 4 then SGame := Parts[4];
            if Length(Parts) > 5 then SMaster := Parts[5];

            ExistingIdx := Length(FServers);
            SetLength(FServers, ExistingIdx + 1);
            FServers[ExistingIdx].IP := SIP;
            FServers[ExistingIdx].Port := SPort;
            FServers[ExistingIdx].Name := SName;
            FServers[ExistingIdx].Map := SMap;
            FServers[ExistingIdx].Folder := SMod;
            FServers[ExistingIdx].Game := SGame;
            FServers[ExistingIdx].MasterServer := SMaster;
            FServers[ExistingIdx].IsFavorite := True;
            FServers[ExistingIdx].Responded := False;
            FServers[ExistingIdx].Ping := 999999;
          end;
        end;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
    Lines.Free;
  end;
end;

procedure TFormMain.SaveFavoritesToRegistry;
var
  Reg: TRegistry;
  Lines: TStringList;
  i, j: Integer;
  Key, SName, SMap, SMod, SGame, SMaster: string;
begin
  Lines := TStringList.Create;
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\MSMonitor\Favorites', True) then
    begin
      if Assigned(FFavorites) then
      begin
        for i := 0 to FFavorites.Count - 1 do
        begin
          Key := FFavorites[i];
          SName := ''; SMap := ''; SMod := ''; SGame := ''; SMaster := '';
          for j := 0 to High(FServers) do
          begin
            if Format('%s:%d', [FServers[j].IP, FServers[j].Port]) = Key then
            begin
              SName := FServers[j].Name;
              SMap := FServers[j].Map;
              SMod := FServers[j].Folder;
              SGame := FServers[j].Game;
              SMaster := FServers[j].MasterServer;
              Break;
            end;
          end;
          Lines.Add(Format('%s|%s|%s|%s|%s|%s', [Key, SName, SMap, SMod, SGame, SMaster]));
        end;
      end;
      Reg.WriteString('List', Lines.Text);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
    Lines.Free;
  end;
end;

function TFormMain.IsFavorite(const IP: string; Port: Word): Boolean;
var
  Key: string;
begin
  if not Assigned(FFavorites) then
  begin
    Result := False;
    Exit;
  end;
  Key := Format('%s:%d', [IP, Port]);
  Result := FFavorites.IndexOf(Key) >= 0;
end;

function TFormMain.IsItemFavorite(Item: TListItem): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  if not Assigned(Item) then Exit;
  Idx := Integer(NativeInt(Item.Data));
  if (Idx >= 0) and (Idx < Length(FServers)) then
    Result := FServers[Idx].IsFavorite
  else if Item.SubItems.Count > 0 then
    Result := Assigned(FFavorites) and (FFavorites.IndexOf(Item.SubItems[0]) >= 0);
end;

procedure TFormMain.UpdateFavoriteButtonState;
var
  Item: TListItem;
  i: Integer;
  AllAreFav: Boolean;
begin
  if lvServers.SelCount = 0 then
  begin
    btnFavorite.Caption := '★ Favorite';
    miFavorite.Caption := '★ Add to Favorites';
    Exit;
  end;

  AllAreFav := True;
  for i := 0 to lvServers.Items.Count - 1 do
  begin
    Item := lvServers.Items[i];
    if Item.Selected then
    begin
      if not IsItemFavorite(Item) then
      begin
        AllAreFav := False;
        Break;
      end;
    end;
  end;

  if AllAreFav then
  begin
    btnFavorite.Caption := '★ Unfavorite';
    miFavorite.Caption := '★ Remove from Favorites';
  end
  else
  begin
    btnFavorite.Caption := '★ Favorite';
    miFavorite.Caption := '★ Add to Favorites';
  end;
end;

procedure TFormMain.lvServersSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  UpdateFavoriteButtonState;
end;

procedure TFormMain.btnFavoriteClick(Sender: TObject);
var
  i, Idx: Integer;
  Item: TListItem;
  Key: string;
  AllAreFav: Boolean;
  AnyModified: Boolean;
begin
  if lvServers.SelCount = 0 then
  begin
    ShowMessage('Select server(s) from the list to add or remove from Favorites!');
    Exit;
  end;

  AllAreFav := True;
  for i := 0 to lvServers.Items.Count - 1 do
  begin
    Item := lvServers.Items[i];
    if Item.Selected then
    begin
      if not IsItemFavorite(Item) then
      begin
        AllAreFav := False;
        Break;
      end;
    end;
  end;

  AnyModified := False;
  for i := 0 to lvServers.Items.Count - 1 do
  begin
    Item := lvServers.Items[i];
    if Item.Selected then
    begin
      Idx := Integer(NativeInt(Item.Data));
      Key := Item.SubItems[0];
      if AllAreFav then
      begin
        if FFavorites.IndexOf(Key) >= 0 then
          FFavorites.Delete(FFavorites.IndexOf(Key));
        if (Idx >= 0) and (Idx < Length(FServers)) then
          FServers[Idx].IsFavorite := False;
        AnyModified := True;
      end
      else
      begin
        if FFavorites.IndexOf(Key) < 0 then
          FFavorites.Add(Key);
        if (Idx >= 0) and (Idx < Length(FServers)) then
          FServers[Idx].IsFavorite := True;
        AnyModified := True;
      end;
    end;
  end;

  if AnyModified then
  begin
    SaveFavoritesToRegistry;
    UpdateFavoriteButtonState;
    DoApplySort;
    lvServers.Invalidate;

    if not AllAreFav then
      tmrFavoritesRefreshTimer(nil);
  end;
end;

procedure TFormMain.miRefreshOneClick(Sender: TObject);
var
  Item: TListItem;
  ServerIdx: Integer;
  SingleThread: TA2SInfoThread;
begin
  if not Assigned(lvServers.Selected) then Exit;
  Item := lvServers.Selected;
  ServerIdx := Integer(NativeInt(Item.Data));
  if (ServerIdx < 0) or (ServerIdx >= Length(FServers)) then Exit;

  if Assigned(FInfoThread) then
  begin
    FInfoThread.EnqueueServer(ServerIdx, FServers[ServerIdx]);
    sbStatus.Panels[0].Text := Format(' Server %s added to update queue...', [Item.SubItems[0]]);
  end
  else
  begin
    SingleThread := TA2SInfoThread.Create(
      FTimeoutMs, 1,
      OnServerInfoUpdate, nil, nil
    );
    SingleThread.EnqueueServer(ServerIdx, FServers[ServerIdx]);
    SingleThread.SetMasterScanFinished;
    sbStatus.Panels[0].Text := Format(' Refreshing server %s...', [Item.SubItems[0]]);
  end;
end;

procedure TFormMain.tmrFavoritesRefreshTimer(Sender: TObject);
var
  i, FavCount: Integer;
begin
  if FIsStopping then Exit;
  if Assigned(FInfoThread) or Assigned(FMultiMasterThread) then Exit;
  if Assigned(FFavInfoThread) then Exit;

  FavCount := 0;
  for i := 0 to High(FServers) do
    if FServers[i].IsFavorite then
      Inc(FavCount);

  if FavCount = 0 then Exit;

  FFavInfoThread := TA2SInfoThread.Create(
    FTimeoutMs, Min(4, FavCount),
    OnServerInfoUpdate, nil, OnFavInfoFinished
  );

  for i := 0 to High(FServers) do
    if FServers[i].IsFavorite then
      FFavInfoThread.EnqueueServer(i, FServers[i]);

  FFavInfoThread.SetMasterScanFinished;
end;

procedure TFormMain.OnFavInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
begin
  FFavInfoThread := nil;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  SetLength(FServers, 0);
  FMultiMasterThread := nil;
  FInfoThread := nil;
  FFavInfoThread := nil;
  FRespondedCount := 0;
  FSortColumn := 5; // Ping column
  FSortAscending := True;
  FIsStopping := False;
  pbProgress.Position := 0;

  LoadSettingsFromRegistry;

  // Auto-detect HL path if empty
  if (FHLPath = '') or not FileExists(FHLPath) then
  begin
    if FileExists('C:\Games\Half-Life\RUN_HL.exe') then
      FHLPath := 'C:\Games\Half-Life\RUN_HL.exe'
    else if FileExists('C:\Games\Half-Life\hl.exe') then
      FHLPath := 'C:\Games\Half-Life\hl.exe'
    else if FileExists('C:\Games\Half-Life\Safe_Half-Life_1600x900.cmd') then
      FHLPath := 'C:\Games\Half-Life\Safe_Half-Life_1600x900.cmd'
    else if FileExists('C:\Program Files (x86)\Steam\steamapps\common\Half-Life\hl.exe') then
      FHLPath := 'C:\Program Files (x86)\Steam\steamapps\common\Half-Life\hl.exe'
    else if FileExists('D:\Games\Half-Life\RUN_HL.exe') then
      FHLPath := 'D:\Games\Half-Life\RUN_HL.exe'
    else if FileExists('D:\Games\Half-Life\hl.exe') then
      FHLPath := 'D:\Games\Half-Life\hl.exe';
  end;

  // Auto-detect CS 1.6 path if empty
  if (FCSPath = '') or not FileExists(FCSPath) then
  begin
    if FileExists('C:\Games\Counter-Strike 1.6\hl.exe') then
      FCSPath := 'C:\Games\Counter-Strike 1.6\hl.exe'
    else if FileExists('C:\Games\Counter-Strike 1.6\cstrike.exe') then
      FCSPath := 'C:\Games\Counter-Strike 1.6\cstrike.exe'
    else if FileExists('C:\Games\CS 1.6\hl.exe') then
      FCSPath := 'C:\Games\CS 1.6\hl.exe'
    else if FileExists('C:\Games\CS 1.6\cstrike.exe') then
      FCSPath := 'C:\Games\CS 1.6\cstrike.exe'
    else if FileExists('D:\Games\Counter-Strike 1.6\hl.exe') then
      FCSPath := 'D:\Games\Counter-Strike 1.6\hl.exe'
    else if (FHLPath <> '') and FileExists(FHLPath) and (Pos('cstrike', LowerCase(FHLPath)) > 0) then
      FCSPath := FHLPath;
  end;

  SaveSettingsToRegistry;

  // Initialize and load favorites
  FFavorites := TStringList.Create;
  FFavorites.Sorted := True;
  FFavorites.Duplicates := dupIgnore;
  LoadFavoritesFromRegistry;

  Caption := 'Half-Life & GoldSrc MasterServer Monitor';

  btnFetch.Caption := 'Query Servers';
  btnStop.Caption := 'Stop';
  btnFavorite.Caption := '★ Favorite';
  btnSettings.Caption := 'Settings...';
  btnConnect.Caption := 'Connect';
  btnCopy.Caption := 'Copy IP:Port';
  btnExport.Caption := 'Export...';
  btnClear.Caption := 'Clear';

  if lvServers.Columns.Count >= 9 then
  begin
    lvServers.Columns[0].Caption := '#';
    lvServers.Columns[1].Caption := 'IP:Port';
    lvServers.Columns[2].Caption := 'Server Name';
    lvServers.Columns[3].Caption := 'Map';
    lvServers.Columns[4].Caption := 'Players';
    lvServers.Columns[5].Caption := 'Ping';
    lvServers.Columns[6].Caption := 'Mod';
    lvServers.Columns[7].Caption := 'Game';
    lvServers.Columns[8].Caption := 'Master Server';
  end;

  if sbStatus.Panels.Count >= 4 then
  begin
    sbStatus.Panels[0].Text := ' Ready.';
    sbStatus.Panels[1].Text := ' Servers: 0';
    sbStatus.Panels[2].Text := ' Responded: 0';
    sbStatus.Panels[3].Text := Format(' Master Servers: %d', [Length(FMasterServers)]);
  end;

  dlgSave.Filter := 'Text File (*.txt)|*.txt|CSV File (*.csv)|*.csv|All Files (*.*)|*.*';
  dlgSave.Title := 'Export Server List';

  DoubleBuffered := True;
  pnlButtons.DoubleBuffered := True;
  pnlBottom.DoubleBuffered := True;
  lvServers.DoubleBuffered := True;

  SendMessage(lvServers.Handle, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_DOUBLEBUFFER, LVS_EX_DOUBLEBUFFER);

  FOldListViewWndProc := lvServers.WindowProc;
  lvServers.WindowProc := ListViewWndProc;

  FSortPending := False;
  FLastSortTick := 0;

  tmrSortThrottle := TTimer.Create(Self);
  tmrSortThrottle.Interval := 100;
  tmrSortThrottle.OnTimer := tmrSortThrottleTimer;
  tmrSortThrottle.Enabled := True;

  ApplyAppStyle(FAppStyle);

  if Length(FServers) > 0 then
    RebuildListView;

  // Background refresh timer for favorites (every 30 seconds)
  tmrFavoritesRefresh := TTimer.Create(Self);
  tmrFavoritesRefresh.Interval := 30000;
  tmrFavoritesRefresh.OnTimer := tmrFavoritesRefreshTimer;
  tmrFavoritesRefresh.Enabled := True;

  tmrAutoStart.Interval := 250;
  tmrAutoStart.Enabled := True;

  tmrAutoRefresh := TTimer.Create(Self);
  tmrAutoRefresh.Interval := 60000; // 60 seconds (1 minute)
  tmrAutoRefresh.OnTimer := tmrAutoRefreshTimer;
  tmrAutoRefresh.Enabled := FAutoRefresh;
end;

procedure TFormMain.ListViewWndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_ERASEBKGND then
  begin
    Msg.Result := 1;
    Exit;
  end;
  FOldListViewWndProc(Msg);
end;

function TFormMain.IsDarkTheme: Boolean;
begin
  Result := SameText(FAppStyle, 'Windows10 Dark') or (Pos('dark', LowerCase(FAppStyle)) > 0);
end;

procedure TFormMain.ApplyAppStyle(const StyleName: string);
begin
  FAppStyle := StyleName;
  if IsDarkTheme then
  begin
    if not TStyleManager.TrySetStyle('Windows10 Dark') then
      if FileExists('Windows10Dark.vsf') then
        TStyleManager.SetStyle(TStyleManager.LoadFromFile('Windows10Dark.vsf'));
    lvServers.Color := $001C1C1C;
  end
  else
  begin
    if not TStyleManager.TrySetStyle('Windows10') then
      if FileExists('Windows10.vsf') then
        TStyleManager.SetStyle(TStyleManager.LoadFromFile('Windows10.vsf'));
    lvServers.Color := clWhite;
  end;
  SendMessage(lvServers.Handle, LVM_SETEXTENDEDLISTVIEWSTYLE, LVS_EX_DOUBLEBUFFER, LVS_EX_DOUBLEBUFFER);
  lvServers.Invalidate;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  if Assigned(tmrFavoritesRefresh) then
  begin
    tmrFavoritesRefresh.Enabled := False;
    tmrFavoritesRefresh.Free;
    tmrFavoritesRefresh := nil;
  end;

  if Assigned(tmrSortThrottle) then
  begin
    tmrSortThrottle.Enabled := False;
    tmrSortThrottle.Free;
    tmrSortThrottle := nil;
  end;

  if Assigned(lvServers) and Assigned(FOldListViewWndProc) then
    lvServers.WindowProc := FOldListViewWndProc;

  if Assigned(tmrAutoRefresh) then
  begin
    tmrAutoRefresh.Enabled := False;
    tmrAutoRefresh.Free;
    tmrAutoRefresh := nil;
  end;

  tmrAutoStart.Enabled := False;
  FIsStopping := True;

  if Assigned(FMultiMasterThread) then
  begin
    FMultiMasterThread.OnBatch := nil;
    FMultiMasterThread.OnStatus := nil;
    FMultiMasterThread.OnFinished := nil;
    FMultiMasterThread.Terminate;
  end;

  if Assigned(FInfoThread) then
  begin
    FInfoThread.OnServerUpdate := nil;
    FInfoThread.OnStatus := nil;
    FInfoThread.OnFinished := nil;
    FInfoThread.Terminate;
  end;

  if Assigned(FFavInfoThread) then
  begin
    FFavInfoThread.OnServerUpdate := nil;
    FFavInfoThread.OnStatus := nil;
    FFavInfoThread.OnFinished := nil;
    FFavInfoThread.Terminate;
  end;

  if Assigned(FFavorites) then
  begin
    FFavorites.Free;
    FFavorites := nil;
  end;
end;

procedure TFormMain.tmrAutoStartTimer(Sender: TObject);
begin
  tmrAutoStart.Enabled := False;
  btnFetchClick(nil);
end;

procedure TFormMain.tmrAutoRefreshTimer(Sender: TObject);
begin
  if not FAutoRefresh then Exit;
  if FIsStopping then Exit;
  if (Application.ModalLevel > 0) or (Screen.ActiveForm <> Self) then Exit;
  if Assigned(FMultiMasterThread) or Assigned(FInfoThread) then Exit;

  btnFetchClick(nil);
end;

procedure TFormMain.SetWorking(IsBusy: Boolean);
begin
  btnFetch.Enabled := not IsBusy;
  btnStop.Enabled := IsBusy;
  btnClear.Enabled := not IsBusy;
  btnSettings.Enabled := not IsBusy;
end;

procedure TFormMain.btnFetchClick(Sender: TObject);
var
  k: Integer;
begin
  if Length(FMasterServers) = 0 then
  begin
    ShowMessage('Master server list is empty! Open "Settings..." and add addresses.');
    Exit;
  end;

  FIsStopping := False;
  SetWorking(True);
  pbProgress.Position := 0;
  pbProgress.Max := 100;

  sbStatus.Panels[3].Text := Format(' Master Servers: %d', [Length(FMasterServers)]);
  sbStatus.Panels[0].Text := Format(' Querying %d master servers (%d threads)...',
    [Length(FMasterServers), FThreadCount]);

  // 1. Immediately create and launch A2S worker pool (streaming consumer)
  FInfoThread := TA2SInfoThread.Create(
    FTimeoutMs, FThreadCount,
    OnServerInfoUpdate, OnWorkerStatus, OnInfoFinished
  );

  // Enqueue any existing servers (including favorites) for in-place re-polling!
  for k := 0 to High(FServers) do
    FInfoThread.EnqueueServer(k, FServers[k]);

  // 2. Immediately create and launch Multi-Master query thread (streaming producer)
  FMultiMasterThread := TMultiMasterQueryThread.Create(
    FMasterServers, FGameFilters, FRegionByte, FLimitCount,
    OnMasterBatch, OnMasterStatus, OnMasterFinished
  );
end;

function TFormMain.FindItemByServerIndex(Index: Integer): TListItem;
var
  i: Integer;
  Candidate: TListItem;
begin
  Result := nil;
  if (Index >= 0) and (Index < Length(FServerToItem)) then
  begin
    Candidate := FServerToItem[Index];
    if (Candidate <> nil) and (NativeInt(Candidate.Data) = Index) then
    begin
      Result := Candidate;
      Exit;
    end;
  end;

  for i := 0 to lvServers.Items.Count - 1 do
  begin
    if NativeInt(lvServers.Items[i].Data) = Index then
    begin
      Result := lvServers.Items[i];
      if (Index >= 0) and (Index < Length(FServerToItem)) then
        FServerToItem[Index] := Result;
      Exit;
    end;
  end;
end;

procedure TFormMain.RebuildListView;
var
  i: Integer;
  Item: TListItem;
  ShouldShow: Boolean;
  Key: string;
begin
  lvServers.Items.BeginUpdate;
  try
    lvServers.Items.Clear;
    SetLength(FServerToItem, Length(FServers));
    for i := 0 to High(FServers) do
    begin
      FServerToItem[i] := nil;
      FServers[i].IsFavorite := IsFavorite(FServers[i].IP, FServers[i].Port);

      if FServers[i].IsFavorite then
        ShouldShow := True
      else if FServers[i].Responded then
        ShouldShow := not (FHideEmpty and (FServers[i].Players = 0))
      else
        ShouldShow := not FHideUnresponsive;

      if ShouldShow then
      begin
        Key := Format('%s:%d', [FServers[i].IP, FServers[i].Port]);
        Item := lvServers.Items.Add;
        if FServers[i].IsFavorite then
          Item.Caption := Format('★ %d', [lvServers.Items.Count])
        else
          Item.Caption := IntToStr(lvServers.Items.Count);
        Item.Data := Pointer(NativeInt(i));
        Item.SubItems.Add(Key);
        Item.SubItems.Add(FServers[i].Name);
        Item.SubItems.Add(FServers[i].Map);
        if FServers[i].Responded then
        begin
          Item.SubItems.Add(Format('%d / %d', [FServers[i].Players, FServers[i].MaxPlayers]));
          Item.SubItems.Add(Format('%d ms', [FServers[i].Ping]));
        end
        else
        begin
          Item.SubItems.Add('-');
          Item.SubItems.Add('-');
        end;
        Item.SubItems.Add(FServers[i].Folder);
        Item.SubItems.Add(FServers[i].Game);
        Item.SubItems.Add(FServers[i].MasterServer);
        FServerToItem[i] := Item;
      end;
    end;

    ApplySort;
  finally
    lvServers.Items.EndUpdate;
  end;

  sbStatus.Panels[1].Text := Format(' Servers: %d (in list: %d)', [Length(FServers), lvServers.Items.Count]);
end;

procedure TFormMain.OnMasterBatch(const Servers: TServerArray);
var
  i, j, ExistingIdx: Integer;
  Item: TListItem;
  Key: string;
begin
  if FIsStopping then Exit;

  lvServers.Items.BeginUpdate;
  try
    for i := 0 to High(Servers) do
    begin
      Key := Format('%s:%d', [Servers[i].IP, Servers[i].Port]);
      ExistingIdx := -1;

      // Deduplicate: check if this IP:Port was already received
      for j := 0 to High(FServers) do
      begin
        if (FServers[j].Port = Servers[i].Port) and (FServers[j].IP = Servers[i].IP) then
        begin
          ExistingIdx := j;
          Break;
        end;
      end;

      if ExistingIdx >= 0 then
      begin
        // Server exists: append new master server tag if not already listed
        if Pos(Servers[i].MasterServer, FServers[ExistingIdx].MasterServer) = 0 then
        begin
          FServers[ExistingIdx].MasterServer := FServers[ExistingIdx].MasterServer + ', ' + Servers[i].MasterServer;
          Item := FindItemByServerIndex(ExistingIdx);
          if (Item <> nil) and (Item.SubItems.Count > 7) then
            Item.SubItems[7] := FServers[ExistingIdx].MasterServer;
        end;
      end
      else
      begin
        // Add new unique server
        ExistingIdx := Length(FServers);
        SetLength(FServers, ExistingIdx + 1);
        FServers[ExistingIdx] := Servers[i];
        FServers[ExistingIdx].IsFavorite := IsFavorite(Servers[i].IP, Servers[i].Port);
        if Length(FServerToItem) < Length(FServers) then
          SetLength(FServerToItem, Length(FServers));
        FServerToItem[ExistingIdx] := nil;

        // If favorite or not hiding unresponsive servers, show placeholder right away
        if FServers[ExistingIdx].IsFavorite or not FHideUnresponsive then
        begin
          Item := lvServers.Items.Add;
          if FServers[ExistingIdx].IsFavorite then
            Item.Caption := Format('★ %d', [lvServers.Items.Count])
          else
            Item.Caption := IntToStr(lvServers.Items.Count);
          Item.Data := Pointer(NativeInt(ExistingIdx));
          Item.SubItems.Add(Key);                           // SubItems[0] = IP:Port
          Item.SubItems.Add(Servers[i].Name);              // SubItems[1] = Name
          Item.SubItems.Add(Servers[i].Map);               // SubItems[2] = Map
          Item.SubItems.Add('-');                          // SubItems[3] = Players
          Item.SubItems.Add('...');                        // SubItems[4] = Ping (actively querying)
          Item.SubItems.Add(Servers[i].Folder);            // SubItems[5] = Mod
          Item.SubItems.Add(Servers[i].Game);              // SubItems[6] = Game
          Item.SubItems.Add(Servers[i].MasterServer);      // SubItems[7] = MasterServer
          FServerToItem[ExistingIdx] := Item;
        end;

        // STREAMING: Immediately enqueue newly found server into A2S worker pool!
        if Assigned(FInfoThread) then
          FInfoThread.EnqueueServer(ExistingIdx, Servers[i]);
      end;
    end;
  finally
    lvServers.Items.EndUpdate;
  end;

  if not FHideUnresponsive then
    RequestSort;

  sbStatus.Panels[1].Text := Format(' Servers: %d (in list: %d)', [Length(FServers), lvServers.Items.Count]);
end;

procedure TFormMain.OnWorkerStatus(const StatusText: string; Progress, Total: Integer);
begin
  sbStatus.Panels[0].Text := ' ' + StatusText;
  if Total > 0 then
  begin
    pbProgress.Max := Total;
    pbProgress.Position := Progress;
  end;
end;

procedure TFormMain.OnMasterStatus(const StatusText: string; Progress, Total: Integer);
begin
  if FRespondedCount = 0 then
    sbStatus.Panels[0].Text := ' ' + StatusText;
end;

procedure TFormMain.OnMasterFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
begin
  FMultiMasterThread := nil;

  if FIsStopping then
    Exit;

  // Signal the A2S worker pool that master servers finished sending new servers
  if Assigned(FInfoThread) then
    FInfoThread.SetMasterScanFinished;

  if (Length(FServers) = 0) and not Success then
  begin
    SetWorking(False);
    pbProgress.Position := 0;
    sbStatus.Panels[0].Text := ' Master server error: ' + ErrorMsg;
  end;
end;

procedure TFormMain.OnServerInfoUpdate(Index: Integer; const Server: TServerInfo);
var
  Item: TListItem;
  ShouldShow: Boolean;
  Key: string;
begin
  if (Index < 0) or (Index >= Length(FServers)) then Exit;

  FServers[Index] := Server;
  FServers[Index].IsFavorite := IsFavorite(Server.IP, Server.Port);

  if Server.Responded then
  begin
    Inc(FRespondedCount);
    sbStatus.Panels[2].Text := Format(' Responded: %d', [FRespondedCount]);
  end;

  if FServers[Index].IsFavorite then
    ShouldShow := True
  else if Server.Responded then
    ShouldShow := not (FHideEmpty and (Server.Players = 0))
  else
    ShouldShow := not FHideUnresponsive;

  Item := FindItemByServerIndex(Index);

  if ShouldShow then
  begin
    if Item = nil then
    begin
      Key := Format('%s:%d', [Server.IP, Server.Port]);
      Item := lvServers.Items.Add;
      if FServers[Index].IsFavorite then
        Item.Caption := Format('★ %d', [lvServers.Items.Count])
      else
        Item.Caption := IntToStr(lvServers.Items.Count);
      Item.Data := Pointer(NativeInt(Index));
      Item.SubItems.Add(Key);
      Item.SubItems.Add(Server.Name);
      Item.SubItems.Add(Server.Map);
      if Server.Responded then
      begin
        Item.SubItems.Add(Format('%d / %d', [Server.Players, Server.MaxPlayers]));
        Item.SubItems.Add(Format('%d ms', [Server.Ping]));
      end
      else
      begin
        Item.SubItems.Add('-');
        Item.SubItems.Add('-');
      end;
      Item.SubItems.Add(Server.Folder);
      Item.SubItems.Add(Server.Game);
      Item.SubItems.Add(Server.MasterServer);
      if Index < Length(FServerToItem) then
        FServerToItem[Index] := Item;
    end
    else
    begin
      if FServers[Index].IsFavorite and (Pos('★', Item.Caption) = 0) then
        Item.Caption := '★ ' + Item.Caption;

      if Item.SubItems[1] <> Server.Name then Item.SubItems[1] := Server.Name;
      if Item.SubItems[2] <> Server.Map then Item.SubItems[2] := Server.Map;
      if Server.Responded then
      begin
        var S1: string := Format('%d / %d', [Server.Players, Server.MaxPlayers]);
        if Item.SubItems[3] <> S1 then Item.SubItems[3] := S1;
        var S2: string := Format('%d ms', [Server.Ping]);
        if Item.SubItems[4] <> S2 then Item.SubItems[4] := S2;
      end
      else
      begin
        if Item.SubItems[3] <> '-' then Item.SubItems[3] := '-';
        if Item.SubItems[4] <> '-' then Item.SubItems[4] := '-';
      end;
      if Item.SubItems[5] <> Server.Folder then Item.SubItems[5] := Server.Folder;
      if Item.SubItems[6] <> Server.Game then Item.SubItems[6] := Server.Game;
      if Item.SubItems[7] <> Server.MasterServer then Item.SubItems[7] := Server.MasterServer;
    end;
  end
  else
  begin
    if Item <> nil then
    begin
      Item.Delete;
      if Index < Length(FServerToItem) then
        FServerToItem[Index] := nil;
    end;
  end;

  // Throttled live sorting without screen flicker
  RequestSort;

  sbStatus.Panels[1].Text := Format(' Servers: %d (in list: %d)', [Length(FServers), lvServers.Items.Count]);
end;

procedure TFormMain.OnInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
begin
  FInfoThread := nil;
  SetWorking(False);
  pbProgress.Position := 0;

  DoApplySort;

  sbStatus.Panels[1].Text := Format(' Servers: %d (in list: %d)', [Length(FServers), lvServers.Items.Count]);
  sbStatus.Panels[2].Text := Format(' Responded: %d', [FRespondedCount]);
  sbStatus.Panels[0].Text := Format(' Scan completed. Responded: %d of %d (in list: %d).',
    [FRespondedCount, Length(FServers), lvServers.Items.Count]);
end;

procedure TFormMain.ApplySortIndex(Index: Integer);
begin
  FSortIndex := Index;
  case FSortIndex of
    0: begin FSortColumn := 5; FSortAscending := True; end;  // Ping: ascending (lowest ping on top)
    1: begin FSortColumn := 4; FSortAscending := False; end; // Players: descending (highest on top)
    2: begin FSortColumn := 2; FSortAscending := True; end;  // Name: A-Z
    3: begin FSortColumn := 3; FSortAscending := True; end;  // Map: A-Z
    4: begin FSortColumn := 6; FSortAscending := True; end;  // Mod / Folder: A-Z
    5: begin FSortColumn := 1; FSortAscending := True; end;  // IP:Port
    6: begin FSortColumn := 8; FSortAscending := True; end;  // Master Server: A-Z
  else
    FSortColumn := 5;
    FSortAscending := True;
  end;
end;

procedure TFormMain.RequestSort;
var
  NowTick: UInt64;
begin
  FSortPending := True;
  NowTick := GetTickCount64;
  if NowTick - FLastSortTick >= 200 then
    DoApplySort;
end;

procedure TFormMain.tmrSortThrottleTimer(Sender: TObject);
begin
  if FSortPending and (GetTickCount64 - FLastSortTick >= 200) then
    DoApplySort;
end;

procedure TFormMain.DoApplySort;
begin
  if lvServers.Items.Count <= 1 then
  begin
    FSortPending := False;
    Exit;
  end;

  FSortPending := False;
  FLastSortTick := GetTickCount64;

  lvServers.CustomSort(nil, FSortColumn);
  RenumberList;
end;

procedure TFormMain.ApplySort;
begin
  DoApplySort;
end;

procedure TFormMain.RenumberList;
var
  i: Integer;
  S: string;
  IsFav: Boolean;
begin
  for i := 0 to lvServers.Items.Count - 1 do
  begin
    IsFav := IsItemFavorite(lvServers.Items[i]);
    if IsFav then
      S := Format('★ %d', [i + 1])
    else
      S := IntToStr(i + 1);

    if lvServers.Items[i].Caption <> S then
      lvServers.Items[i].Caption := S;
  end;
end;

procedure TFormMain.lvServersColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FSortColumn = Column.Index then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := Column.Index;
    if FSortColumn = 4 then
      FSortAscending := False
    else
      FSortAscending := True;
  end;

  case FSortColumn of
    5: FSortIndex := 0; // Ping
    4: FSortIndex := 1; // Players
    2: FSortIndex := 2; // Name
    3: FSortIndex := 3; // Map
    6: FSortIndex := 4; // Mod
    1: FSortIndex := 5; // IP
    8: FSortIndex := 6; // Master
  end;

  ApplySort;
end;

procedure TFormMain.lvServersCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  Fav1, Fav2: Boolean;
  S1, S2: string;
  P1, P2: Integer;
  N1, N2: Integer;
  SpacePos: Integer;
begin
  // Favorites are ALWAYS pinned to the top!
  Fav1 := IsItemFavorite(Item1);
  Fav2 := IsItemFavorite(Item2);
  if Fav1 and not Fav2 then
  begin
    Compare := -1;
    Exit;
  end;
  if Fav2 and not Fav1 then
  begin
    Compare := 1;
    Exit;
  end;

  case Data of
    0:
    begin
      S1 := Item1.Caption;
      if Pos('★', S1) > 0 then
        S1 := Trim(StringReplace(S1, '★', '', [rfReplaceAll]));
      S2 := Item2.Caption;
      if Pos('★', S2) > 0 then
        S2 := Trim(StringReplace(S2, '★', '', [rfReplaceAll]));

      N1 := StrToIntDef(S1, 0);
      N2 := StrToIntDef(S2, 0);
      Compare := N1 - N2;
      if not FSortAscending then
        Compare := -Compare;
      Exit;
    end;
    4: // Players
    begin
      N1 := -1;
      N2 := -1;
      if (Item1.SubItems.Count > 3) and (Item1.SubItems[3] <> '-') then
      begin
        S1 := Item1.SubItems[3];
        P1 := Pos('/', S1);
        if P1 > 0 then
          N1 := StrToIntDef(Trim(Copy(S1, 1, P1 - 1)), -1)
        else
          N1 := StrToIntDef(Trim(S1), -1);
      end;
      if (Item2.SubItems.Count > 3) and (Item2.SubItems[3] <> '-') then
      begin
        S2 := Item2.SubItems[3];
        P2 := Pos('/', S2);
        if P2 > 0 then
          N2 := StrToIntDef(Trim(Copy(S2, 1, P2 - 1)), -1)
        else
          N2 := StrToIntDef(Trim(S2), -1);
      end;

      if (N1 = -1) and (N2 = -1) then
        Compare := 0
      else if N1 = -1 then
        Compare := 1
      else if N2 = -1 then
        Compare := -1
      else
      begin
        Compare := N1 - N2;
        if not FSortAscending then
          Compare := -Compare;
      end;
      Exit;
    end;
    5: // Ping
    begin
      N1 := 999999;
      N2 := 999999;
      if (Item1.SubItems.Count > 4) and (Item1.SubItems[4] <> '-') then
      begin
        S1 := Item1.SubItems[4];
        SpacePos := Pos(' ', S1);
        if SpacePos > 0 then
          N1 := StrToIntDef(Trim(Copy(S1, 1, SpacePos - 1)), 999999)
        else
          N1 := StrToIntDef(Trim(S1), 999999);
      end;
      if (Item2.SubItems.Count > 4) and (Item2.SubItems[4] <> '-') then
      begin
        S2 := Item2.SubItems[4];
        SpacePos := Pos(' ', S2);
        if SpacePos > 0 then
          N2 := StrToIntDef(Trim(Copy(S2, 1, SpacePos - 1)), 999999)
        else
          N2 := StrToIntDef(Trim(S2), 999999);
      end;

      if (N1 = 999999) and (N2 = 999999) then
        Compare := 0
      else if N1 = 999999 then
        Compare := 1
      else if N2 = 999999 then
        Compare := -1
      else
      begin
        Compare := N1 - N2;
        if not FSortAscending then
          Compare := -Compare;
      end;
      Exit;
    end;
  else
    if (Item1.SubItems.Count >= Data) and (Item2.SubItems.Count >= Data) then
      Compare := CompareText(Item1.SubItems[Data - 1], Item2.SubItems[Data - 1])
    else
      Compare := 0;

    if not FSortAscending then
      Compare := -Compare;
  end;
end;

procedure TFormMain.lvServersCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  IsFav: Boolean;
begin
  DefaultDraw := True;
  IsFav := IsItemFavorite(Item);

  if cdsSelected in State then
  begin
    if IsDarkTheme then
    begin
      if IsFav then
        Sender.Canvas.Brush.Color := $004E381A
      else
        Sender.Canvas.Brush.Color := $004A3C2A;
      Sender.Canvas.Font.Color := clWhite;
    end
    else
    begin
      if IsFav then
        Sender.Canvas.Brush.Color := $00C0A860
      else
        Sender.Canvas.Brush.Color := $00D0B080;
      Sender.Canvas.Font.Color := clBlack;
    end;
  end
  else
  begin
    if IsFav then
    begin
      if IsDarkTheme then
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00262118
        else
          Sender.Canvas.Brush.Color := $001F1A12;
        Sender.Canvas.Font.Color := $00FCD34D;
      end
      else
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00FFFBEB
        else
          Sender.Canvas.Brush.Color := $00FEF3C7;
        Sender.Canvas.Font.Color := $0078350F;
      end;
    end
    else
    begin
      if IsDarkTheme then
      begin
        // Zebra striping for dark mode
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00242424
        else
          Sender.Canvas.Brush.Color := $001C1C1C;
        Sender.Canvas.Font.Color := $00F1F5F9;
      end
      else
      begin
        // Zebra striping for light mode
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00F6F7F9
        else
          Sender.Canvas.Brush.Color := clWhite;
        Sender.Canvas.Font.Color := $001E293B;
      end;
    end;
  end;
end;

procedure TFormMain.lvServersCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
  SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  PingVal, PlayersVal, SlashPos, SpacePos: Integer;
  S: string;
  Dark, IsFav: Boolean;
begin
  DefaultDraw := True;
  Dark := IsDarkTheme;
  IsFav := IsItemFavorite(Item);

  if cdsSelected in State then
  begin
    if Dark then
    begin
      if IsFav then
        Sender.Canvas.Brush.Color := $004E381A
      else
        Sender.Canvas.Brush.Color := $004A3C2A;
      Sender.Canvas.Font.Color := clWhite;
    end
    else
    begin
      if IsFav then
        Sender.Canvas.Brush.Color := $00C0A860
      else
        Sender.Canvas.Brush.Color := $00D0B080;
      Sender.Canvas.Font.Color := clBlack;
    end;
  end
  else
  begin
    if IsFav then
    begin
      if Dark then
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00262118
        else
          Sender.Canvas.Brush.Color := $001F1A12;
        Sender.Canvas.Font.Color := $00FCD34D;
      end
      else
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00FFFBEB
        else
          Sender.Canvas.Brush.Color := $00FEF3C7;
        Sender.Canvas.Font.Color := $0078350F;
      end;
    end
    else
    begin
      if Dark then
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00242424
        else
          Sender.Canvas.Brush.Color := $001C1C1C;
        Sender.Canvas.Font.Color := $00F1F5F9;
      end
      else
      begin
        if Odd(Item.Index) then
          Sender.Canvas.Brush.Color := $00F6F7F9
        else
          Sender.Canvas.Brush.Color := clWhite;
        Sender.Canvas.Font.Color := $001E293B;
      end;
    end;
  end;

  case SubItem of
    1: // IP:Port
    begin
      if Dark then
      begin
        if IsFav then
          Sender.Canvas.Font.Color := $00FDE68A
        else
          Sender.Canvas.Font.Color := $0094A3B8;
      end
      else
      begin
        if IsFav then
          Sender.Canvas.Font.Color := $0092400E
        else
          Sender.Canvas.Font.Color := $0064748B;
      end;
      if IsFav then
        Sender.Canvas.Font.Style := [fsBold]
      else
        Sender.Canvas.Font.Style := [];
    end;
    2: // Server Name
    begin
      if Dark then
      begin
        if IsFav then
          Sender.Canvas.Font.Color := $00FEF08A
        else
          Sender.Canvas.Font.Color := $00F8FAFC;
      end
      else
      begin
        if IsFav then
          Sender.Canvas.Font.Color := $0078350F
        else
          Sender.Canvas.Font.Color := $000F172A;
      end;

      if IsFav or ((Item.SubItems.Count > 3) and (Item.SubItems[3] <> '-') and
         not SameText(Copy(Item.SubItems[3], 1, 2), '0 ') and
         not SameText(Copy(Item.SubItems[3], 1, 2), '0/')) then
        Sender.Canvas.Font.Style := [fsBold]
      else
        Sender.Canvas.Font.Style := [];
    end;
    3: // Map
    begin
      if Dark then
        Sender.Canvas.Font.Color := $00CBD5E1
      else
        Sender.Canvas.Font.Color := $00334155;
      Sender.Canvas.Font.Style := [];
    end;
    4: // Players (SubItems[3])
    begin
      if (Item.SubItems.Count > 3) and (Item.SubItems[3] <> '-') then
      begin
        S := Item.SubItems[3];
        SlashPos := Pos('/', S);
        if SlashPos > 0 then
          PlayersVal := StrToIntDef(Trim(Copy(S, 1, SlashPos - 1)), 0)
        else
          PlayersVal := StrToIntDef(Trim(S), 0);

        if PlayersVal > 0 then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $004ADE80 // Bright neon emerald
          else
            Sender.Canvas.Font.Color := $0015803D; // Rich dark emerald
          Sender.Canvas.Font.Style := [fsBold];
        end
        else
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0064748B
          else
            Sender.Canvas.Font.Color := $0094A3B8;
          Sender.Canvas.Font.Style := [];
        end;
      end;
    end;
    5: // Ping (SubItems[4])
    begin
      if (Item.SubItems.Count > 4) and (Item.SubItems[4] <> '-') then
      begin
        S := Item.SubItems[4];
        SpacePos := Pos(' ', S);
        if SpacePos > 0 then
          PingVal := StrToIntDef(Trim(Copy(S, 1, SpacePos - 1)), 999999)
        else
          PingVal := StrToIntDef(Trim(S), 999999);

        Sender.Canvas.Font.Style := [fsBold];
        if PingVal < 50 then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $004ADE80 // Bright emerald
          else
            Sender.Canvas.Font.Color := $0016A34A; // Emerald green
        end
        else if PingVal < 100 then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0022D3EE // Cyan
          else
            Sender.Canvas.Font.Color := $000284C7; // Blue
        end
        else if PingVal < 150 then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $00FBBF24 // Amber
          else
            Sender.Canvas.Font.Color := $00D97706; // Amber
        end
        else if PingVal < 999999 then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $00F87171 // Coral red
          else
            Sender.Canvas.Font.Color := $00DC2626; // Red
        end
        else
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0064748B
          else
            Sender.Canvas.Font.Color := $0094A3B8;
          Sender.Canvas.Font.Style := [];
        end;
      end;
    end;
    6: // Mod (SubItems[5])
    begin
      if Item.SubItems.Count > 5 then
      begin
        S := LowerCase(Trim(Item.SubItems[5]));
        Sender.Canvas.Font.Style := [fsBold];
        if S = 'valve' then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0038BDF8 // Sky blue
          else
            Sender.Canvas.Font.Color := $000284C7;
        end
        else if S = 'cstrike' then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0034D399 // Mint
          else
            Sender.Canvas.Font.Color := $00059669;
        end
        else if S = 'ag' then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $00C084FC // Purple
          else
            Sender.Canvas.Font.Color := $007C3AED;
        end
        else if S = 'gearbox' then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $00FB923C // Orange
          else
            Sender.Canvas.Font.Color := $00C2410C;
        end
        else if S = 'dod' then
        begin
          if Dark then
            Sender.Canvas.Font.Color := $00A3E635 // Lime
          else
            Sender.Canvas.Font.Color := $004D7C0F;
        end
        else
        begin
          if Dark then
            Sender.Canvas.Font.Color := $0094A3B8
          else
            Sender.Canvas.Font.Color := $0064748B;
        end;
      end;
    end;
    7: // Game (SubItems[6])
    begin
      if Dark then
        Sender.Canvas.Font.Color := $0094A3B8
      else
        Sender.Canvas.Font.Color := $0064748B;
      Sender.Canvas.Font.Style := [];
    end;
    8: // MasterServer (SubItems[7])
    begin
      if Dark then
        Sender.Canvas.Font.Color := $007DD3FC // Light Cyan / Sky
      else
        Sender.Canvas.Font.Color := $000369A1; // Ocean blue
      Sender.Canvas.Font.Style := [];
    end;
  end;
end;

procedure TFormMain.btnStopClick(Sender: TObject);
begin
  FIsStopping := True;

  if Assigned(FMultiMasterThread) then
  begin
    FMultiMasterThread.OnBatch := nil;
    FMultiMasterThread.OnStatus := nil;
    FMultiMasterThread.OnFinished := nil;
    FMultiMasterThread.Terminate;
    FMultiMasterThread := nil;
  end;

  if Assigned(FInfoThread) then
  begin
    FInfoThread.OnServerUpdate := nil;
    FInfoThread.OnStatus := nil;
    FInfoThread.OnFinished := nil;
    FInfoThread.Terminate;
    FInfoThread := nil;
  end;

  if Assigned(FFavInfoThread) then
  begin
    FFavInfoThread.OnServerUpdate := nil;
    FFavInfoThread.OnStatus := nil;
    FFavInfoThread.OnFinished := nil;
    FFavInfoThread.Terminate;
    FFavInfoThread := nil;
  end;

  SetWorking(False);
  pbProgress.Position := 0;
  sbStatus.Panels[0].Text := ' Stopped by user.';
end;

procedure TFormMain.btnSettingsClick(Sender: TObject);
var
  Dlg: TFormSettings;
begin
  Dlg := TFormSettings.Create(Self);
  try
    Dlg.edtHL.Text := FHLPath;
    Dlg.edtCS.Text := FCSPath;
    Dlg.SetMasterServers(FMasterServers);
    Dlg.SetGameFilters(FGameFilters);
    Dlg.SetThreadCount(FThreadCount);
    Dlg.SetTimeoutMs(FTimeoutMs);
    Dlg.SetRegionByte(FRegionByte);
    Dlg.SetLimitCount(FLimitCount);
    Dlg.SetHideEmpty(FHideEmpty);
    Dlg.SetHideUnresponsive(FHideUnresponsive);
    Dlg.SetAutoRefresh(FAutoRefresh);
    Dlg.SetAppStyle(FAppStyle);
    Dlg.SetSortIndex(FSortIndex);

    if Dlg.ShowModal = mrOk then
    begin
      FHLPath := Trim(Dlg.edtHL.Text);
      FCSPath := Trim(Dlg.edtCS.Text);
      FMasterServers := Dlg.GetMasterServers;
      FGameFilters := Dlg.GetGameFilters;
      FThreadCount := Dlg.GetThreadCount;
      FTimeoutMs := Dlg.GetTimeoutMs;
      FRegionByte := Dlg.GetRegionByte;
      FLimitCount := Dlg.GetLimitCount;
      FHideEmpty := Dlg.GetHideEmpty;
      FHideUnresponsive := Dlg.GetHideUnresponsive;
      FAutoRefresh := Dlg.GetAutoRefresh;

      ApplySortIndex(Dlg.GetSortIndex);

      if not SameText(FAppStyle, Dlg.GetAppStyle) then
        ApplyAppStyle(Dlg.GetAppStyle);

      if Assigned(tmrAutoRefresh) then
        tmrAutoRefresh.Enabled := FAutoRefresh;

      SaveSettingsToRegistry;
      RebuildListView;
      ApplySort;

      sbStatus.Panels[0].Text := Format(' Settings saved (Masters: %d, Mods: %d, Threads: %d).',
        [Length(FMasterServers), Length(FGameFilters), FThreadCount]);
      sbStatus.Panels[3].Text := Format(' Master Servers: %d', [Length(FMasterServers)]);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TFormMain.btnConnectClick(Sender: TObject);
var
  Addr: string;
  ServerName, Folder, GameName: string;
  TargetExe, Dir, Ext, Cmd, GameParam: string;
  IsCS: Boolean;
  Item: TListItem;
begin
  if not Assigned(lvServers.Selected) then
  begin
    ShowMessage('Please select a server from the list to connect!');
    Exit;
  end;

  Item := lvServers.Selected;
  Addr := Trim(Item.SubItems[0]);
  ServerName := '';
  if Item.SubItems.Count > 1 then
    ServerName := Item.SubItems[1];

  Folder := '';
  if Item.SubItems.Count > 5 then
    Folder := LowerCase(Trim(Item.SubItems[5]));

  GameName := '';
  if Item.SubItems.Count > 6 then
    GameName := LowerCase(Trim(Item.SubItems[6]));

  Clipboard.AsText := 'connect ' + Addr;

  IsCS := (Folder = 'cstrike') or (Folder = 'czero') or
          (Pos('counter-strike', GameName) > 0) or (Pos('cstrike', GameName) > 0);

  if IsCS then
  begin
    TargetExe := FCSPath;
    if (TargetExe = '') or not FileExists(TargetExe) then
    begin
      if (FHLPath <> '') and FileExists(FHLPath) then
        TargetExe := FHLPath
      else
      begin
        if MessageDlg('Counter-Strike 1.6 executable is not configured.' + sLineBreak +
           'Open Settings now?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          btnSettingsClick(nil);
          TargetExe := FCSPath;
        end;

        if (TargetExe = '') or not FileExists(TargetExe) then
        begin
          ShowMessage('Connect command copied to clipboard:' + sLineBreak + 'connect ' + Addr);
          Exit;
        end;
      end;
    end;
  end
  else
  begin
    TargetExe := FHLPath;
    if (TargetExe = '') or not FileExists(TargetExe) then
    begin
      if (FCSPath <> '') and FileExists(FCSPath) then
        TargetExe := FCSPath
      else
      begin
        if MessageDlg('Half-Life executable is not configured.' + sLineBreak +
           'Open Settings now?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          btnSettingsClick(nil);
          TargetExe := FHLPath;
        end;

        if (TargetExe = '') or not FileExists(TargetExe) then
        begin
          ShowMessage('Connect command copied to clipboard:' + sLineBreak + 'connect ' + Addr);
          Exit;
        end;
      end;
    end;
  end;

  Dir := ExtractFilePath(TargetExe);
  Ext := LowerCase(ExtractFileExt(TargetExe));

  GameParam := '';
  if SameText(ExtractFileName(TargetExe), 'hl.exe') or SameText(ExtractFileName(TargetExe), 'RUN_HL.exe') then
  begin
    if IsCS then
      GameParam := '-game cstrike '
    else if (Folder <> '') and (Folder <> '-') and (Folder <> 'valve') then
      GameParam := '-game ' + Folder + ' ';
  end;

  if (Ext = '.cmd') or (Ext = '.bat') then
  begin
    Cmd := Format('/c start "" "%s" %s+connect %s', [TargetExe, GameParam, Addr]);
    ShellExecuteW(0, 'open', 'cmd.exe', PChar(Cmd), PChar(Dir), SW_SHOWNORMAL);
  end
  else
  begin
    Cmd := Format('%s+connect %s', [GameParam, Addr]);
    ShellExecuteW(0, 'open', PChar(TargetExe), PChar(Cmd), PChar(Dir), SW_SHOWNORMAL);
  end;

  sbStatus.Panels[0].Text := Format(' Launching %s (%s+connect %s - %s)',
    [ExtractFileName(TargetExe), GameParam, Addr, ServerName]);
end;

procedure TFormMain.btnCopyClick(Sender: TObject);
var
  Addr: string;
begin
  if Assigned(lvServers.Selected) then
  begin
    Addr := lvServers.Selected.SubItems[0];
    Clipboard.AsText := Addr;
    sbStatus.Panels[0].Text := ' Copied to clipboard: ' + Addr;
  end
  else
    ShowMessage('Please select a server from the list!');
end;

procedure TFormMain.btnExportClick(Sender: TObject);
var
  Lines: TStringList;
  i: Integer;
  IsCSV: Boolean;
  Item: TListItem;
  Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8: string;
begin
  if lvServers.Items.Count = 0 then
  begin
    ShowMessage('Server list is empty!');
    Exit;
  end;

  if dlgSave.Execute then
  begin
    IsCSV := SameText(ExtractFileExt(dlgSave.FileName), '.csv');
    Lines := TStringList.Create;
    try
      if IsCSV then
        Lines.Add('"#";"IP:Port";"Name";"Map";"Players";"Ping";"Folder";"Game";"MasterServer"')
      else
        Lines.Add('=== Half-Life & GoldSrc MasterServer Server List ===');

      for i := 0 to lvServers.Items.Count - 1 do
      begin
        Item := lvServers.Items[i];
        Col1 := ''; Col2 := ''; Col3 := ''; Col4 := ''; Col5 := ''; Col6 := ''; Col7 := ''; Col8 := '';
        if Item.SubItems.Count > 0 then Col1 := Item.SubItems[0];
        if Item.SubItems.Count > 1 then Col2 := Item.SubItems[1];
        if Item.SubItems.Count > 2 then Col3 := Item.SubItems[2];
        if Item.SubItems.Count > 3 then Col4 := Item.SubItems[3];
        if Item.SubItems.Count > 4 then Col5 := Item.SubItems[4];
        if Item.SubItems.Count > 5 then Col6 := Item.SubItems[5];
        if Item.SubItems.Count > 6 then Col7 := Item.SubItems[6];
        if Item.SubItems.Count > 7 then Col8 := Item.SubItems[7];

        if IsCSV then
        begin
          Lines.Add(Format('%d;"%s";"%s";"%s";"%s";"%s";"%s";"%s";"%s"', [
            i + 1,
            Col1,
            StringReplace(Col2, '"', '""', [rfReplaceAll]),
            Col3,
            Col4,
            Col5,
            Col6,
            Col7,
            Col8
          ]));
        end
        else
        begin
          Lines.Add(Format('%-4d %-22s %-30s %-14s %-8s %-8s %-10s %s', [
            i + 1,
            Col1,
            Col2,
            Col3,
            Col4,
            Col5,
            Col6,
            Col8
          ]));
        end;
      end;

      Lines.SaveToFile(dlgSave.FileName, TEncoding.UTF8);
      sbStatus.Panels[0].Text := ' Exported to: ' + dlgSave.FileName;
    finally
      Lines.Free;
    end;
  end;
end;

procedure TFormMain.btnClearClick(Sender: TObject);
var
  i, NewCount: Integer;
  NewServers: TServerArray;
begin
  NewCount := 0;
  for i := 0 to High(FServers) do
    if FServers[i].IsFavorite then
      Inc(NewCount);

  SetLength(NewServers, NewCount);
  NewCount := 0;
  for i := 0 to High(FServers) do
  begin
    if FServers[i].IsFavorite then
    begin
      NewServers[NewCount] := FServers[i];
      Inc(NewCount);
    end;
  end;

  FServers := NewServers;
  RebuildListView;
  FRespondedCount := 0;
  for i := 0 to High(FServers) do
    if FServers[i].Responded then
      Inc(FRespondedCount);

  if Length(FServers) > 0 then
    sbStatus.Panels[0].Text := ' List cleared (Favorites preserved).'
  else
    sbStatus.Panels[0].Text := ' List cleared.';
  sbStatus.Panels[1].Text := Format(' Servers: %d', [Length(FServers)]);
  sbStatus.Panels[2].Text := Format(' Responded: %d', [FRespondedCount]);
  pbProgress.Position := 0;
end;

end.
