unit MSCliRunner;

interface

uses
  Winapi.Windows, Winapi.Winsock2, System.SysUtils, System.Classes, HLMasterProtocol;

procedure RunCliMode;

implementation

function AttachConsole(dwProcessId: DWORD): BOOL; stdcall; external kernel32 name 'AttachConsole';

const
  ATTACH_PARENT_PROCESS = DWORD(-1);

procedure ConsolePrint(const S: string);
var
  HOut: THandle;
  Mode: DWORD;
  CharsWritten: DWORD;
  Utf8Bytes: TBytes;
  BytesWritten: DWORD;
begin
  HOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if (HOut = 0) or (HOut = INVALID_HANDLE_VALUE) then
    Exit;

  if GetConsoleMode(HOut, Mode) then
  begin
    // Real console: native Unicode output
    WriteConsoleW(HOut, PChar(S), DWORD(Length(S)), CharsWritten, nil);
  end
  else
  begin
    // Pipe / redirected stdout: UTF-8 bytes
    Utf8Bytes := TEncoding.UTF8.GetBytes(S);
    if Length(Utf8Bytes) > 0 then
      WriteFile(HOut, Utf8Bytes[0], DWORD(Length(Utf8Bytes)), BytesWritten, nil);
  end;
end;

procedure ConsolePrintln(const S: string = '');
begin
  ConsolePrint(S + sLineBreak);
end;

procedure PrintHelp;
begin
  ConsolePrintln('');
  ConsolePrintln('Half-Life & GoldSrc MasterServer Monitor (CLI Mode)');
  ConsolePrintln('========================================================================');
  ConsolePrintln('Использование:');
  ConsolePrintln('  msmonitor.exe -cli [параметры] [хост[:порт]] [фильтр]');
  ConsolePrintln('');
  ConsolePrintln('Параметры:');
  ConsolePrintln('  -host:<адрес[:порт]>   Адрес MasterServer (по умолчанию: ms.cs16.net:27010)');
  ConsolePrintln('  -filter:<фильтр>       Фильтр игры: valve, cstrike, ag, gearbox, dod, tfc');
  ConsolePrintln('  -limit:<число>         Максимальное количество серверов (по умолчанию: 30)');
  ConsolePrintln('  -threads:<1..10>       Количество потоков опроса (до 10 потоков, по умолчанию: 10)');
  ConsolePrintln('  -region:<код>          Код региона (0xFF - весь мир, 0x03 - Европа)');
  ConsolePrintln('  -timeout:<мс>          Таймаут опроса A2S (по умолчанию: 350 мс)');
  ConsolePrintln('  -help, -h, -?          Показать эту справку');
  ConsolePrintln('');
  ConsolePrintln('Примеры:');
  ConsolePrintln('  msmonitor.exe -cli');
  ConsolePrintln('  msmonitor.exe -cli masterserver.csboost.eu:27010 cstrike');
  ConsolePrintln('  msmonitor.exe -cli -threads:10 -timeout:350 -limit:50');
  ConsolePrintln('========================================================================');
  ConsolePrintln('');
end;

type
  TConsoleWorkerSync = class
  public
    FMasterFinished: Boolean;
    FMasterSuccess: Boolean;
    FMasterError: string;
    FMasterCount: Integer;

    FInfoFinished: Boolean;
    FInfoTotal: Integer;

    FServers: TServerArray;
    FActiveServers: TServerArray;

    procedure OnMasterBatch(const Servers: TServerArray);
    procedure OnWorkerStatus(const StatusText: string; Progress, Total: Integer);
    procedure OnMasterFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);

    procedure OnServerUpdate(Index: Integer; const Server: TServerInfo);
    procedure OnInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
  end;

procedure TConsoleWorkerSync.OnMasterBatch(const Servers: TServerArray);
var
  OldLen, i: Integer;
begin
  OldLen := Length(FServers);
  SetLength(FServers, OldLen + Length(Servers));
  for i := 0 to High(Servers) do
    FServers[OldLen + i] := Servers[i];
end;

procedure TConsoleWorkerSync.OnWorkerStatus(const StatusText: string; Progress, Total: Integer);
begin
  ConsolePrint(#13 + ' ' + StatusText);
end;

procedure TConsoleWorkerSync.OnMasterFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
begin
  FMasterFinished := True;
  FMasterSuccess := Success;
  FMasterError := ErrorMsg;
  FMasterCount := TotalCount;
  ConsolePrintln('');
end;

procedure TConsoleWorkerSync.OnServerUpdate(Index: Integer; const Server: TServerInfo);
var
  Len: Integer;
begin
  if (Index >= 0) and (Index < Length(FServers)) then
    FServers[Index] := Server;

  if Server.Responded then
  begin
    Len := Length(FActiveServers);
    SetLength(FActiveServers, Len + 1);
    FActiveServers[Len] := Server;
  end;
end;

procedure TConsoleWorkerSync.OnInfoFinished(TotalCount: Integer; Success: Boolean; const ErrorMsg: string);
begin
  FInfoFinished := True;
  FInfoTotal := TotalCount;
  ConsolePrintln('');
end;

procedure RunCliMode;
var
  Host: string;
  Port: Word;
  Filter: string;
  Region: Byte;
  Limit: Integer;
  TimeoutMs: Integer;
  Threads: Integer;
  ColonPos, i: Integer;
  SVal, Param: string;
  PositionalArgs: TStringList;
  Sync: TConsoleWorkerSync;
  MasterThread: TMasterQueryThread;
  InfoThread: TA2SInfoThread;
  ExistingStdOut: THandle;
begin
  ExistingStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if (ExistingStdOut = 0) or (ExistingStdOut = INVALID_HANDLE_VALUE) then
  begin
    if not AttachConsole(ATTACH_PARENT_PROCESS) then
      AllocConsole;
  end;

  if FindCmdLineSwitch('help') or FindCmdLineSwitch('h') or FindCmdLineSwitch('?') then
  begin
    PrintHelp;
    Exit;
  end;

  // Defaults
  Host := 'ms.cs16.net:27010';
  Port := 27010;
  Filter := '\gamedir\valve';
  Region := $FF;
  Limit := 30;
  TimeoutMs := 350;
  Threads := 10;

  // Parse positional arguments
  PositionalArgs := TStringList.Create;
  try
    for i := 1 to ParamCount do
    begin
      Param := ParamStr(i);
      if (Param <> '') and not CharInSet(Param[1], ['-', '/']) then
        PositionalArgs.Add(Param);
    end;

    if PositionalArgs.Count >= 1 then
      Host := PositionalArgs[0];

    if PositionalArgs.Count >= 2 then
    begin
      Filter := PositionalArgs[1];
      if (Filter <> '') and (Filter[1] <> '\') then
        Filter := '\gamedir\' + Filter;
    end;

    if PositionalArgs.Count >= 3 then
      Limit := StrToIntDef(PositionalArgs[2], Limit);
  finally
    PositionalArgs.Free;
  end;

  // Named switches
  if FindCmdLineSwitch('host', SVal) and (SVal <> '') then
    Host := SVal;

  if FindCmdLineSwitch('filter', SVal) and (SVal <> '') then
  begin
    Filter := SVal;
    if (Filter <> '') and (Filter[1] <> '\') then
      Filter := '\gamedir\' + Filter;
  end;

  if FindCmdLineSwitch('limit', SVal) and (SVal <> '') then
    Limit := StrToIntDef(SVal, Limit);

  if FindCmdLineSwitch('threads', SVal) and (SVal <> '') then
    Threads := StrToIntDef(SVal, Threads);

  if FindCmdLineSwitch('region', SVal) and (SVal <> '') then
    Region := Byte(StrToIntDef(SVal, Integer(Region)));

  if FindCmdLineSwitch('timeout', SVal) and (SVal <> '') then
    TimeoutMs := StrToIntDef(SVal, TimeoutMs);

  if Threads < 1 then Threads := 1;
  if Threads > 10 then Threads := 10;

  // If CS 1.6 filter is chosen with default hl1.master.direct, switch to csboost
  if (Pos('cstrike', LowerCase(Filter)) > 0) and SameText(Host, 'hl1.master.direct:27010') then
    Host := 'masterserver.csboost.eu:27010';

  // Parse Host:Port
  ColonPos := Pos(':', Host);
  if ColonPos > 0 then
  begin
    Port := Word(StrToIntDef(Copy(Host, ColonPos + 1, MaxInt), Integer(Port)));
    Host := Copy(Host, 1, ColonPos - 1);
  end;

  ConsolePrintln('');
  ConsolePrintln('=======================================================================================');
  ConsolePrintln('     Half-Life & GoldSrc MasterServer Monitor (Unified CLI Engine)');
  ConsolePrintln('=======================================================================================');
  ConsolePrintln(Format('Мастер-сервер: %s:%d | Фильтр: "%s" | Лимит: %d | Таймаут: %d мс | Потоков: %d',
    [Host, Port, Filter, Limit, TimeoutMs, Threads]));
  ConsolePrintln('---------------------------------------------------------------------------------------');

  Sync := TConsoleWorkerSync.Create;
  try
    SetLength(Sync.FServers, 0);
    SetLength(Sync.FActiveServers, 0);
    Sync.FMasterFinished := False;
    Sync.FInfoFinished := False;

    // 1. Query Master Server
    MasterThread := TMasterQueryThread.Create(
      Host, Port, Region, Filter, Limit,
      Sync.OnMasterBatch, Sync.OnWorkerStatus, Sync.OnMasterFinished
    );

    while not Sync.FMasterFinished do
    begin
      CheckSynchronize(20);
      Sleep(10);
    end;
    CheckSynchronize(50);

    if not Sync.FMasterSuccess or (Length(Sync.FServers) = 0) then
    begin
      ConsolePrintln('Серверы не найдены (Мастер-сервер вернул пустой список).');
      Exit;
    end;

    ConsolePrintln(Format('Получено серверов: %d. Мультипоточный опрос A2S (%d потоков)...',
      [Length(Sync.FServers), Threads]));
    ConsolePrintln('---------------------------------------------------------------------------------------');

    // 2. Query A2S Server Info with multithreaded worker pool (up to 10 threads)
    InfoThread := TA2SInfoThread.Create(
      Sync.FServers, TimeoutMs, Threads,
      Sync.OnServerUpdate, Sync.OnWorkerStatus, Sync.OnInfoFinished
    );

    while not Sync.FInfoFinished do
    begin
      CheckSynchronize(20);
      Sleep(10);
    end;
    CheckSynchronize(50);

    // 3. Sort active servers by Ping
    if Length(Sync.FActiveServers) > 1 then
      QuickSortServersByPing(Sync.FActiveServers, 0, High(Sync.FActiveServers));

    ConsolePrintln('---------------------------------------------------------------------------------------');
    ConsolePrintln(Format('%-4s %-22s %-30s %-14s %-9s %s', ['#', 'IP:Port', 'Имя сервера', 'Карта', 'Игроки', 'Пинг']));
    ConsolePrintln('---------------------------------------------------------------------------------------');

    for i := 0 to High(Sync.FActiveServers) do
    begin
      ConsolePrintln(Format('%-4d %-22s %-30s %-14s %-9s %d ms', [
        i + 1,
        Format('%s:%d', [Sync.FActiveServers[i].IP, Sync.FActiveServers[i].Port]),
        Copy(Sync.FActiveServers[i].Name, 1, 28),
        Copy(Sync.FActiveServers[i].Map, 1, 13),
        Format('%d/%d', [Sync.FActiveServers[i].Players, Sync.FActiveServers[i].MaxPlayers]),
        Sync.FActiveServers[i].Ping
      ]));
    end;

    if Length(Sync.FActiveServers) < Length(Sync.FServers) then
      ConsolePrintln(Format('(%d серверов не ответили на запрос A2S)',
        [Length(Sync.FServers) - Length(Sync.FActiveServers)]));

    ConsolePrintln('=======================================================================================');
    ConsolePrintln(Format('Завершено. Активных серверов: %d из %d (отсортировано по пингу).',
      [Length(Sync.FActiveServers), Length(Sync.FServers)]));
    ConsolePrintln('');

  finally
    Sync.Free;
  end;
end;

end.
