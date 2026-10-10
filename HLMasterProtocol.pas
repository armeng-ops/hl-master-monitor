unit HLMasterProtocol;

interface

uses
  Winapi.Windows, Winapi.Winsock2, System.SysUtils, System.Classes, System.SyncObjs;

type
  TServerInfo = record
    IP: string;
    Port: Word;
    Name: string;
    Map: string;
    Folder: string;
    Game: string;
    Players: Byte;
    MaxPlayers: Byte;
    Bots: Byte;
    Ping: Integer;
    Responded: Boolean;
    MasterServer: string;
    IsFavorite: Boolean;
  end;

  TServerArray = array of TServerInfo;

  TBatchEvent = procedure(const Servers: TServerArray) of object;
  TServerUpdateEvent = procedure(Index: Integer; const Server: TServerInfo) of object;
  TStatusEvent = procedure(const StatusText: string; Progress, Total: Integer) of object;
  TFinishedEvent = procedure(TotalCount: Integer; Success: Boolean; const ErrorMsg: string) of object;

  // Single Master Query Thread (backwards compatibility / single target)
  TMasterQueryThread = class(TThread)
  private
    FHost: string;
    FPort: Word;
    FRegion: Byte;
    FFilter: string;
    FMaxServers: Integer;
    FOnBatch: TBatchEvent;
    FOnStatus: TStatusEvent;
    FOnFinished: TFinishedEvent;

    FSyncBatch: TServerArray;
    FSyncStatus: string;
    FSyncProgress, FSyncTotal: Integer;
    FSyncCount: Integer;
    FSyncSuccess: Boolean;
    FSyncError: string;

    procedure DoSyncBatch;
    procedure DoSyncStatus;
    procedure DoSyncFinished;
  protected
    procedure Execute; override;
  public
    constructor Create(const Host: string; Port: Word; Region: Byte;
      const Filter: string; MaxServers: Integer;
      OnBatch: TBatchEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);

    property OnBatch: TBatchEvent read FOnBatch write FOnBatch;
    property OnStatus: TStatusEvent read FOnStatus write FOnStatus;
    property OnFinished: TFinishedEvent read FOnFinished write FOnFinished;
  end;

  // Multi-Master Query Thread: queries all master servers concurrently for multiple game filters
  TMultiMasterQueryThread = class(TThread)
  private
    FMasterServers: TArray<string>;
    FFilters: TArray<string>;
    FRegion: Byte;
    FMaxServersPerMaster: Integer;
    FOnBatch: TBatchEvent;
    FOnStatus: TStatusEvent;
    FOnFinished: TFinishedEvent;

    FCritSec: TCriticalSection;
    FTotalDiscovered: Integer;

    FSyncBatch: TServerArray;
    FSyncStatus: string;
    FSyncProgress, FSyncTotal: Integer;
    FSyncTotalCount: Integer;
    FSyncSuccess: Boolean;
    FSyncError: string;

    procedure DoSyncBatch;
    procedure DoSyncStatus;
    procedure DoSyncFinished;

    procedure ReportBatch(const Batch: TServerArray);
    procedure ReportStatus(const StatusText: string; Progress, Total: Integer);
  protected
    procedure Execute; override;
  public
    constructor Create(const MasterServers: TArray<string>; const Filters: TArray<string>;
      Region: Byte; MaxServersPerMaster: Integer;
      OnBatch: TBatchEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);
    destructor Destroy; override;

    property OnBatch: TBatchEvent read FOnBatch write FOnBatch;
    property OnStatus: TStatusEvent read FOnStatus write FOnStatus;
    property OnFinished: TFinishedEvent read FOnFinished write FOnFinished;
  end;

  // Thread to poll servers for A2S_INFO using worker pool (supports real-time streaming)
  TA2SInfoThread = class(TThread)
  private
    FTimeoutMs: Integer;
    FWorkerCount: Integer;
    FOnServerUpdate: TServerUpdateEvent;
    FOnStatus: TStatusEvent;
    FOnFinished: TFinishedEvent;

    FQueue: array of record
      Index: Integer;
      Server: TServerInfo;
    end;
    FQueueHead: Integer;
    FQueueLock: TCriticalSection;
    FQueueEvent: THandle;
    FMasterScanFinished: Boolean;

    FWorkers: array of TThread;
    FSuccessCount: Integer;
    FProcessedCount: Integer;
    FTotalEnqueued: Integer;

    FCritSec: TCriticalSection;
    FSyncIndex: Integer;
    FSyncServer: TServerInfo;
    FSyncStatus: string;
    FSyncProgress, FSyncTotal: Integer;

    procedure DoSyncServerUpdate;
    procedure DoSyncStatus;
    procedure DoSyncFinished;

    function DequeueItem(var OutIndex: Integer; var OutServer: TServerInfo): Boolean;
    procedure ReportServerUpdate(Index: Integer; const Server: TServerInfo);
    procedure ReportProgress;
  protected
    procedure Execute; override;
  public
    constructor Create(TimeoutMs: Integer; WorkerCount: Integer;
      OnServerUpdate: TServerUpdateEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent); overload;
    constructor Create(const Servers: TServerArray; TimeoutMs: Integer; WorkerCount: Integer;
      OnServerUpdate: TServerUpdateEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent); overload;
    destructor Destroy; override;

    procedure Terminate; reintroduce;
    procedure EnqueueServer(Index: Integer; const Server: TServerInfo);
    procedure SetMasterScanFinished;

    property OnServerUpdate: TServerUpdateEvent read FOnServerUpdate write FOnServerUpdate;
    property OnStatus: TStatusEvent read FOnStatus write FOnStatus;
    property OnFinished: TFinishedEvent read FOnFinished write FOnFinished;
  end;

function DecodeSmartString(const RawBytes: TBytes): string;
function ReadNullString(const Buf: array of Byte; BufLen: Integer; var Offset: Integer): string;
procedure QuickSortServersByPing(var Arr: TServerArray; L, R: Integer);

const
  BUILTIN_HL_SERVERS: array[0..59] of record
    IP: string;
    Port: Word;
  end = (
    (IP: '94.112.253.15'; Port: 27015),
    (IP: '78.152.169.100'; Port: 27016),
    (IP: '91.211.118.48'; Port: 27021),
    (IP: '185.255.92.172'; Port: 27015),
    (IP: '46.174.48.48'; Port: 27221),
    (IP: '91.211.118.150'; Port: 27021),
    (IP: '45.235.98.235'; Port: 27045),
    (IP: '5.161.189.195'; Port: 27015),
    (IP: '5.178.100.149'; Port: 27015),
    (IP: '45.236.90.136'; Port: 27015),
    (IP: '45.235.98.247'; Port: 27060),
    (IP: '51.68.190.91'; Port: 27015),
    (IP: '5.20.156.199'; Port: 27015),
    (IP: '216.146.26.113'; Port: 27016),
    (IP: '45.235.98.234'; Port: 27030),
    (IP: '195.20.246.242'; Port: 27018),
    (IP: '45.83.244.193'; Port: 27015),
    (IP: '89.144.30.2'; Port: 27015),
    (IP: '45.235.98.235'; Port: 27065),
    (IP: '192.223.30.68'; Port: 27015),
    (IP: '62.31.247.181'; Port: 27015),
    (IP: '45.235.98.48'; Port: 27031),
    (IP: '31.131.249.77'; Port: 27012),
    (IP: '78.141.193.110'; Port: 27015),
    (IP: '4.222.17.223'; Port: 27015),
    (IP: '45.145.224.44'; Port: 27015),
    (IP: '94.181.174.35'; Port: 27018),
    (IP: '45.235.98.234'; Port: 27035),
    (IP: '31.131.249.69'; Port: 27018),
    (IP: '1.34.127.6'; Port: 27014),
    (IP: '74.91.113.16'; Port: 27015),
    (IP: '185.40.76.56'; Port: 27015),
    (IP: '94.102.19.30'; Port: 27001),
    (IP: '94.102.19.30'; Port: 27015),
    (IP: '195.20.246.242'; Port: 27016),
    (IP: '187.127.10.46'; Port: 27015),
    (IP: '74.91.115.100'; Port: 27015),
    (IP: '45.236.90.136'; Port: 27017),
    (IP: '162.248.92.2'; Port: 27015),
    (IP: '62.80.247.69'; Port: 27019),
    (IP: '5.20.156.199'; Port: 27016),
    (IP: '45.235.98.76'; Port: 27018),
    (IP: '193.124.112.56'; Port: 27015),
    (IP: '82.208.17.102'; Port: 27015),
    (IP: '82.208.17.105'; Port: 27015),
    (IP: '193.84.90.16'; Port: 27015),
    (IP: '193.84.90.16'; Port: 27016),
    (IP: '109.248.249.49'; Port: 27015),
    (IP: '195.181.164.88'; Port: 27015),
    (IP: '195.181.164.88'; Port: 27016),
    (IP: '193.26.217.5'; Port: 27015),
    (IP: '193.26.217.5'; Port: 27016),
    (IP: '193.26.217.7'; Port: 27015),
    (IP: '176.57.170.21'; Port: 27015),
    (IP: '176.57.170.21'; Port: 27016),
    (IP: '212.22.93.116'; Port: 27015),
    (IP: '212.22.93.116'; Port: 27016),
    (IP: '46.174.48.48'; Port: 27015),
    (IP: '46.174.48.49'; Port: 27015),
    (IP: '46.174.52.27'; Port: 27015)
  );

implementation

function DecodeSmartString(const RawBytes: TBytes): string;
var
  Len, WLen: Integer;
  P: PAnsiChar;
  Clean: string;
  i: Integer;
  IsAscii: Boolean;
begin
  Result := '';
  Len := Length(RawBytes);
  if Len = 0 then
    Exit;

  IsAscii := True;
  for i := 0 to Len - 1 do
  begin
    if RawBytes[i] >= 128 then
    begin
      IsAscii := False;
      Break;
    end;
  end;

  if IsAscii then
  begin
    SetString(Result, PAnsiChar(@RawBytes[0]), Len);
  end
  else
  begin
    P := PAnsiChar(@RawBytes[0]);

    // 1. Valid UTF-8 check
    WLen := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, P, Len, nil, 0);
    if WLen > 0 then
    begin
      SetLength(Result, WLen);
      MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, P, Len, PChar(Result), WLen);
    end
    else
    begin
      // 2. Fallback to CP1251
      WLen := MultiByteToWideChar(1251, 0, P, Len, nil, 0);
      if WLen > 0 then
      begin
        SetLength(Result, WLen);
        MultiByteToWideChar(1251, 0, P, Len, PChar(Result), WLen);
      end
      else
      begin
        // 3. Fallback to ANSI CP_ACP
        WLen := MultiByteToWideChar(CP_ACP, 0, P, Len, nil, 0);
        if WLen > 0 then
        begin
          SetLength(Result, WLen);
          MultiByteToWideChar(CP_ACP, 0, P, Len, PChar(Result), WLen);
        end
        else
          SetString(Result, PAnsiChar(@RawBytes[0]), Len);
      end;
    end;
  end;

  // Clean GoldSrc control codes
  Clean := '';
  for i := 1 to Length(Result) do
  begin
    if Ord(Result[i]) >= 32 then
      Clean := Clean + Result[i];
  end;
  Result := Trim(Clean);
end;

function ReadNullString(const Buf: array of Byte; BufLen: Integer; var Offset: Integer): string;
var
  StartPos: Integer;
  RawBytes: TBytes;
  Len: Integer;
begin
  Result := '';
  StartPos := Offset;
  while (Offset < BufLen) and (Buf[Offset] <> 0) do
    Inc(Offset);

  Len := Offset - StartPos;
  if Len > 0 then
  begin
    SetLength(RawBytes, Len);
    Move(Buf[StartPos], RawBytes[0], Len);
    Result := DecodeSmartString(RawBytes);
  end;

  if Offset < BufLen then
    Inc(Offset);
end;

procedure QuickSortServersByPing(var Arr: TServerArray; L, R: Integer);
var
  i, j, Pivot: Integer;
  Temp: TServerInfo;
begin
  if L >= R then Exit;
  i := L;
  j := R;
  Pivot := Arr[(L + R) div 2].Ping;

  while i <= j do
  begin
    while Arr[i].Ping < Pivot do Inc(i);
    while Arr[j].Ping > Pivot do Dec(j);
    if i <= j then
    begin
      Temp := Arr[i];
      Arr[i] := Arr[j];
      Arr[j] := Temp;
      Inc(i);
      Dec(j);
    end;
  end;

  if L < j then QuickSortServersByPing(Arr, L, j);
  if i < R then QuickSortServersByPing(Arr, i, R);
end;

{ TMasterQueryThread }

constructor TMasterQueryThread.Create(const Host: string; Port: Word;
  Region: Byte; const Filter: string; MaxServers: Integer;
  OnBatch: TBatchEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);
var
  ColonPos: Integer;
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FHost := Host;
  FPort := Port;

  ColonPos := Pos(':', FHost);
  if ColonPos > 0 then
  begin
    FPort := Word(StrToIntDef(Copy(FHost, ColonPos + 1, MaxInt), Integer(FPort)));
    FHost := Copy(FHost, 1, ColonPos - 1);
  end;

  FRegion := Region;
  FFilter := Filter;
  FMaxServers := MaxServers;
  FOnBatch := OnBatch;
  FOnStatus := OnStatus;
  FOnFinished := OnFinished;
end;

procedure TMasterQueryThread.DoSyncBatch;
begin
  if Assigned(FOnBatch) and not Terminated then
    FOnBatch(FSyncBatch);
end;

procedure TMasterQueryThread.DoSyncStatus;
begin
  if Assigned(FOnStatus) and not Terminated then
    FOnStatus(FSyncStatus, FSyncProgress, FSyncTotal);
end;

procedure TMasterQueryThread.DoSyncFinished;
begin
  if Assigned(FOnFinished) and not Terminated then
    FOnFinished(FSyncCount, FSyncSuccess, FSyncError);
end;

procedure TMasterQueryThread.Execute;
var
  WSA: TWSAData;
  Sock: TSocket;
  MasterAddr: sockaddr_in;
  HostEnt: PHostEnt;
  SeedIP: string;
  SeedPort: Word;
  ReqBuf: TBytes;
  RecvBuf: array[0..8191] of Byte;
  RecvLen: Integer;
  TV: DWORD;
  PayloadOffset, i, LimitCount: Integer;
  CurIP: string;
  CurPort: Word;
  TotalReceived: Integer;
  PageCount: Integer;
  Batch: TServerArray;
  IsLast: Boolean;
  SeedStr: UTF8String;
  FilterStr: UTF8String;
  DummyFrom: TSockAddr;
  DummyFromLen: Integer;
  LowHost: string;
  RawAddr: u_long;
begin
  TotalReceived := 0;
  PageCount := 0;

  LowHost := LowerCase(FHost);
  if SameText(LowHost, 'hl1.master.direct') or (Pos('hl1.master', LowHost) > 0) or
     (Pos('half-life', LowHost) > 0) or (Pos('встроен', LowHost) > 0) then
  begin
    LimitCount := Length(BUILTIN_HL_SERVERS);
    if (FMaxServers > 0) and (LimitCount > FMaxServers) then
      LimitCount := FMaxServers;

    FSyncStatus := Format('Загрузка списка серверов Half-Life 1 (%d активных серверов)...', [LimitCount]);
    FSyncProgress := LimitCount;
    FSyncTotal := LimitCount;
    Synchronize(DoSyncStatus);

    SetLength(Batch, LimitCount);
    for i := 0 to LimitCount - 1 do
    begin
      Batch[i].IP := BUILTIN_HL_SERVERS[i].IP;
      Batch[i].Port := BUILTIN_HL_SERVERS[i].Port;
      Batch[i].Name := '(Ожидает опроса...)';
      Batch[i].Map := '-';
      Batch[i].Folder := 'valve';
      Batch[i].Game := 'Half-Life';
      Batch[i].Players := 0;
      Batch[i].MaxPlayers := 0;
      Batch[i].Bots := 0;
      Batch[i].Ping := -1;
      Batch[i].Responded := False;
      Batch[i].MasterServer := 'hl1.master.direct:27010';
    end;

    FSyncBatch := Batch;
    Synchronize(DoSyncBatch);

    FSyncCount := Length(Batch);
    FSyncSuccess := True;
    FSyncError := '';
    Synchronize(DoSyncFinished);
    Exit;
  end;

  SeedIP := '0.0.0.0';
  SeedPort := 0;

  if WSAStartup($0202, WSA) <> 0 then
  begin
    FSyncCount := 0;
    FSyncSuccess := False;
    FSyncError := 'Не удалось инициализировать WinSock2';
    Synchronize(DoSyncFinished);
    Exit;
  end;

  try
    Sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if Sock = INVALID_SOCKET then
    begin
      FSyncCount := 0;
      FSyncSuccess := False;
      FSyncError := 'Ошибка создания сокета UDP';
      Synchronize(DoSyncFinished);
      Exit;
    end;

    try
      TV := 2500;
      setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@TV), SizeOf(TV));

      FillChar(MasterAddr, SizeOf(MasterAddr), 0);
      MasterAddr.sin_family := AF_INET;
      MasterAddr.sin_port := htons(FPort);

      RawAddr := inet_addr(PAnsiChar(UTF8String(FHost)));
      if RawAddr <> INADDR_NONE then
        MasterAddr.sin_addr.S_addr := RawAddr
      else
      begin
        HostEnt := gethostbyname(PAnsiChar(UTF8String(FHost)));
        if (HostEnt = nil) or (HostEnt^.h_addr_list = nil) or (HostEnt^.h_addr_list^ = nil) then
        begin
          FSyncCount := 0;
          FSyncSuccess := False;
          FSyncError := 'Не удалось разрешить хост: ' + FHost;
          Synchronize(DoSyncFinished);
          Exit;
        end;
        MasterAddr.sin_addr := PInAddr(HostEnt^.h_addr_list^)^;
      end;

      while not Terminated do
      begin
        Inc(PageCount);
        FSyncStatus := Format('Запрос к MasterServer [%s:%d], страница %d...', [FHost, FPort, PageCount]);
        FSyncProgress := TotalReceived;
        FSyncTotal := FMaxServers;
        Synchronize(DoSyncStatus);

        SeedStr := UTF8String(Format('%s:%d', [SeedIP, SeedPort]));
        FilterStr := UTF8String(FFilter);

        SetLength(ReqBuf, 2 + Length(SeedStr) + 1 + Length(FilterStr) + 1);
        ReqBuf[0] := $31;
        ReqBuf[1] := FRegion;
        Move(PAnsiChar(SeedStr)^, ReqBuf[2], Length(SeedStr));
        ReqBuf[2 + Length(SeedStr)] := 0;
        if Length(FilterStr) > 0 then
          Move(PAnsiChar(FilterStr)^, ReqBuf[3 + Length(SeedStr)], Length(FilterStr));
        ReqBuf[Length(ReqBuf) - 1] := 0;

        if sendto(Sock, ReqBuf[0], Length(ReqBuf), 0, PSockAddr(@MasterAddr), SizeOf(MasterAddr)) = SOCKET_ERROR then
          Break;

        DummyFromLen := SizeOf(DummyFrom);
        RecvLen := recvfrom(Sock, RecvBuf[0], SizeOf(RecvBuf), 0, DummyFrom, DummyFromLen);
        if RecvLen <= 6 then
          Break;

        if (RecvBuf[0] <> $FF) or (RecvBuf[1] <> $FF) or
           (RecvBuf[2] <> $FF) or (RecvBuf[3] <> $FF) or
           (RecvBuf[4] <> $66) or (RecvBuf[5] <> $0A) then
          Break;

        PayloadOffset := 6;
        SetLength(Batch, 0);
        IsLast := False;

        while (PayloadOffset + 6 <= RecvLen) do
        begin
          CurIP := Format('%d.%d.%d.%d', [
            RecvBuf[PayloadOffset],
            RecvBuf[PayloadOffset + 1],
            RecvBuf[PayloadOffset + 2],
            RecvBuf[PayloadOffset + 3]
          ]);
          CurPort := Word((RecvBuf[PayloadOffset + 4] shl 8) or RecvBuf[PayloadOffset + 5]);
          Inc(PayloadOffset, 6);

          if (CurIP = '0.0.0.0') and (CurPort = 0) then
          begin
            IsLast := True;
            Break;
          end;

          SeedIP := CurIP;
          SeedPort := CurPort;

          SetLength(Batch, Length(Batch) + 1);
          Batch[High(Batch)].IP := CurIP;
          Batch[High(Batch)].Port := CurPort;
          Batch[High(Batch)].Name := '(Ожидает опроса...)';
          Batch[High(Batch)].Map := '-';
          Batch[High(Batch)].Folder := '-';
          Batch[High(Batch)].Game := '-';
          Batch[High(Batch)].Players := 0;
          Batch[High(Batch)].MaxPlayers := 0;
          Batch[High(Batch)].Bots := 0;
          Batch[High(Batch)].Ping := -1;
          Batch[High(Batch)].Responded := False;
          Batch[High(Batch)].MasterServer := Format('%s:%d', [FHost, FPort]);

          Inc(TotalReceived);
          if (FMaxServers > 0) and (TotalReceived >= FMaxServers) then
          begin
            IsLast := True;
            Break;
          end;
        end;

        if Length(Batch) > 0 then
        begin
          FSyncBatch := Batch;
          Synchronize(DoSyncBatch);
        end;

        if IsLast or (Length(Batch) = 0) then
          Break;

        Sleep(15);
      end;

      if not Terminated then
      begin
        FSyncCount := TotalReceived;
        FSyncSuccess := True;
        FSyncError := '';
        Synchronize(DoSyncFinished);
      end;

    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
end;

{ TSingleMasterWorker }

type
  TSingleMasterWorker = class(TThread)
  private
    FOwner: TMultiMasterQueryThread;
    FMasterEndpoint: string;
    FHost: string;
    FPort: Word;
    FFilters: TArray<string>;
    FRegion: Byte;
    FMaxServers: Integer;
    procedure QuerySingleFilter(const FilterName: string);
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TMultiMasterQueryThread; const MasterEndpoint: string;
      const Filters: TArray<string>; Region: Byte; MaxServers: Integer);
  end;

constructor TSingleMasterWorker.Create(AOwner: TMultiMasterQueryThread; const MasterEndpoint: string;
  const Filters: TArray<string>; Region: Byte; MaxServers: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FMasterEndpoint := MasterEndpoint;
  FFilters := Copy(Filters);
  FRegion := Region;
  FMaxServers := MaxServers;
end;

procedure TSingleMasterWorker.Execute;
var
  i, ColonPos, LimitCount: Integer;
  LowHost: string;
  Batch: TServerArray;
begin
  LowHost := LowerCase(Trim(FMasterEndpoint));
  if SameText(LowHost, 'hl1.master.direct') or (Pos('hl1.master', LowHost) > 0) or
     (Pos('half-life', LowHost) > 0) or (Pos('valve', LowHost) > 0) or (Pos('встроен', LowHost) > 0) then
  begin
    LimitCount := Length(BUILTIN_HL_SERVERS);
    if (FMaxServers > 0) and (LimitCount > FMaxServers) then
      LimitCount := FMaxServers;

    SetLength(Batch, LimitCount);
    for i := 0 to LimitCount - 1 do
    begin
      Batch[i].IP := BUILTIN_HL_SERVERS[i].IP;
      Batch[i].Port := BUILTIN_HL_SERVERS[i].Port;
      Batch[i].Name := '(Ожидает опроса...)';
      Batch[i].Map := '-';
      Batch[i].Folder := 'valve';
      Batch[i].Game := 'Half-Life';
      Batch[i].Players := 0;
      Batch[i].MaxPlayers := 0;
      Batch[i].Bots := 0;
      Batch[i].Ping := -1;
      Batch[i].Responded := False;
      Batch[i].MasterServer := 'hl1.master.direct:27010';
    end;

    FOwner.ReportBatch(Batch);
    Exit;
  end;

  ColonPos := Pos(':', FMasterEndpoint);
  if ColonPos > 0 then
  begin
    FHost := Copy(FMasterEndpoint, 1, ColonPos - 1);
    FPort := Word(StrToIntDef(Copy(FMasterEndpoint, ColonPos + 1, MaxInt), 27010));
  end
  else
  begin
    FHost := FMasterEndpoint;
    FPort := 27010;
  end;

  if Length(FFilters) = 0 then
  begin
    QuerySingleFilter('');
  end
  else
  begin
    for i := 0 to High(FFilters) do
    begin
      if Terminated or FOwner.Terminated then
        Break;
      QuerySingleFilter(Trim(FFilters[i]));
    end;
  end;
end;

procedure TSingleMasterWorker.QuerySingleFilter(const FilterName: string);
var
  Sock: TSocket;
  MasterAddr: sockaddr_in;
  HostEnt: PHostEnt;
  SeedIP: string;
  SeedPort: Word;
  ReqBuf: TBytes;
  RecvBuf: array[0..8191] of Byte;
  RecvLen: Integer;
  TV: DWORD;
  PayloadOffset: Integer;
  CurIP: string;
  CurPort: Word;
  TotalReceived: Integer;
  Batch: TServerArray;
  IsLast: Boolean;
  SeedStr: UTF8String;
  FilterStr: UTF8String;
  ActualFilter: string;
  DummyFrom: TSockAddr;
  DummyFromLen: Integer;
  RawAddr: u_long;
begin
  TotalReceived := 0;
  SeedIP := '0.0.0.0';
  SeedPort := 0;

  if FilterName = '' then
    ActualFilter := ''
  else if FilterName[1] = '\' then
    ActualFilter := FilterName
  else
    ActualFilter := '\gamedir\' + FilterName;

  Sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  if Sock = INVALID_SOCKET then
    Exit;

  try
    TV := 2500;
    setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@TV), SizeOf(TV));

    FillChar(MasterAddr, SizeOf(MasterAddr), 0);
    MasterAddr.sin_family := AF_INET;
    MasterAddr.sin_port := htons(FPort);

    RawAddr := inet_addr(PAnsiChar(UTF8String(FHost)));
    if RawAddr <> INADDR_NONE then
      MasterAddr.sin_addr.S_addr := RawAddr
    else
    begin
      HostEnt := gethostbyname(PAnsiChar(UTF8String(FHost)));
      if (HostEnt = nil) or (HostEnt^.h_addr_list = nil) or (HostEnt^.h_addr_list^ = nil) then
        Exit;
      MasterAddr.sin_addr := PInAddr(HostEnt^.h_addr_list^)^;
    end;

    while not Terminated and not FOwner.Terminated do
    begin
      SeedStr := UTF8String(Format('%s:%d', [SeedIP, SeedPort]));
      FilterStr := UTF8String(ActualFilter);

      SetLength(ReqBuf, 2 + Length(SeedStr) + 1 + Length(FilterStr) + 1);
      ReqBuf[0] := $31;
      ReqBuf[1] := FRegion;
      Move(PAnsiChar(SeedStr)^, ReqBuf[2], Length(SeedStr));
      ReqBuf[2 + Length(SeedStr)] := 0;
      if Length(FilterStr) > 0 then
        Move(PAnsiChar(FilterStr)^, ReqBuf[3 + Length(SeedStr)], Length(FilterStr));
      ReqBuf[Length(ReqBuf) - 1] := 0;

      if sendto(Sock, ReqBuf[0], Length(ReqBuf), 0, PSockAddr(@MasterAddr), SizeOf(MasterAddr)) = SOCKET_ERROR then
        Break;

      DummyFromLen := SizeOf(DummyFrom);
      RecvLen := recvfrom(Sock, RecvBuf[0], SizeOf(RecvBuf), 0, DummyFrom, DummyFromLen);
      if RecvLen <= 6 then
        Break;

      if (RecvBuf[0] <> $FF) or (RecvBuf[1] <> $FF) or
         (RecvBuf[2] <> $FF) or (RecvBuf[3] <> $FF) or
         (RecvBuf[4] <> $66) or (RecvBuf[5] <> $0A) then
        Break;

      PayloadOffset := 6;
      SetLength(Batch, 0);
      IsLast := False;

      while (PayloadOffset + 6 <= RecvLen) do
      begin
        CurIP := Format('%d.%d.%d.%d', [
          RecvBuf[PayloadOffset],
          RecvBuf[PayloadOffset + 1],
          RecvBuf[PayloadOffset + 2],
          RecvBuf[PayloadOffset + 3]
        ]);
        CurPort := Word((RecvBuf[PayloadOffset + 4] shl 8) or RecvBuf[PayloadOffset + 5]);
        Inc(PayloadOffset, 6);

        if (CurIP = '0.0.0.0') and (CurPort = 0) then
        begin
          IsLast := True;
          Break;
        end;

        SeedIP := CurIP;
        SeedPort := CurPort;

        SetLength(Batch, Length(Batch) + 1);
        Batch[High(Batch)].IP := CurIP;
        Batch[High(Batch)].Port := CurPort;
        Batch[High(Batch)].Name := '(Pending query...)';
        Batch[High(Batch)].Map := '-';
        Batch[High(Batch)].Folder := FilterName;
        Batch[High(Batch)].Game := '-';
        Batch[High(Batch)].Players := 0;
        Batch[High(Batch)].MaxPlayers := 0;
        Batch[High(Batch)].Bots := 0;
        Batch[High(Batch)].Ping := -1;
        Batch[High(Batch)].Responded := False;
        Batch[High(Batch)].MasterServer := FMasterEndpoint;

        Inc(TotalReceived);
        if (FMaxServers > 0) and (TotalReceived >= FMaxServers) then
        begin
          IsLast := True;
          Break;
        end;
      end;

      if Length(Batch) > 0 then
        FOwner.ReportBatch(Batch);

      if IsLast or (Length(Batch) = 0) then
        Break;

      Sleep(10);
    end;
  finally
    closesocket(Sock);
  end;
end;

{ TMultiMasterQueryThread }

constructor TMultiMasterQueryThread.Create(const MasterServers: TArray<string>; const Filters: TArray<string>;
  Region: Byte; MaxServersPerMaster: Integer;
  OnBatch: TBatchEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FMasterServers := Copy(MasterServers);
  FFilters := Copy(Filters);
  FRegion := Region;
  FMaxServersPerMaster := MaxServersPerMaster;
  FOnBatch := OnBatch;
  FOnStatus := OnStatus;
  FOnFinished := OnFinished;
  FCritSec := TCriticalSection.Create;
  FTotalDiscovered := 0;
end;

destructor TMultiMasterQueryThread.Destroy;
begin
  FCritSec.Free;
  inherited Destroy;
end;

procedure TMultiMasterQueryThread.DoSyncBatch;
begin
  if Assigned(FOnBatch) and not Terminated then
    FOnBatch(FSyncBatch);
end;

procedure TMultiMasterQueryThread.DoSyncStatus;
begin
  if Assigned(FOnStatus) and not Terminated then
    FOnStatus(FSyncStatus, FSyncProgress, FSyncTotal);
end;

procedure TMultiMasterQueryThread.DoSyncFinished;
begin
  if Assigned(FOnFinished) and not Terminated then
    FOnFinished(FSyncTotalCount, FSyncSuccess, FSyncError);
end;

procedure TMultiMasterQueryThread.ReportBatch(const Batch: TServerArray);
begin
  FCritSec.Enter;
  try
    FSyncBatch := Batch;
    Inc(FTotalDiscovered, Length(Batch));
    Synchronize(DoSyncBatch);
  finally
    FCritSec.Leave;
  end;
end;

procedure TMultiMasterQueryThread.ReportStatus(const StatusText: string; Progress, Total: Integer);
begin
  FCritSec.Enter;
  try
    FSyncStatus := StatusText;
    FSyncProgress := Progress;
    FSyncTotal := Total;
    Synchronize(DoSyncStatus);
  finally
    FCritSec.Leave;
  end;
end;

procedure TMultiMasterQueryThread.Execute;
var
  WSA: TWSAData;
  Workers: array of TSingleMasterWorker;
  i, ActiveCount: Integer;
begin
  if Length(FMasterServers) = 0 then
  begin
    FSyncTotalCount := 0;
    FSyncSuccess := True;
    FSyncError := '';
    Synchronize(DoSyncFinished);
    Exit;
  end;

  if WSAStartup($0202, WSA) <> 0 then
  begin
    FSyncTotalCount := 0;
    FSyncSuccess := False;
    FSyncError := 'Failed to initialize WinSock2';
    Synchronize(DoSyncFinished);
    Exit;
  end;

  try
    // Check if HL/valve filter is requested and ensure hl1.master.direct is present
    var HasHLMaster: Boolean := False;
    for i := 0 to High(FMasterServers) do
      if Pos('hl1.master', LowerCase(FMasterServers[i])) > 0 then
      begin
        HasHLMaster := True;
        Break;
      end;

    var WantsHL: Boolean := False;
    if Length(FFilters) = 0 then
      WantsHL := True
    else
    begin
      for i := 0 to High(FFilters) do
        if SameText(Trim(FFilters[i]), 'valve') or (Pos('valve', LowerCase(FFilters[i])) > 0) then
        begin
          WantsHL := True;
          Break;
        end;
    end;

    if WantsHL and not HasHLMaster then
    begin
      SetLength(FMasterServers, Length(FMasterServers) + 1);
      FMasterServers[High(FMasterServers)] := 'hl1.master.direct:27010';
    end;

    ActiveCount := Length(FMasterServers);
    SetLength(Workers, ActiveCount);

    ReportStatus(Format('Querying %d master servers in parallel...', [ActiveCount]), 0, ActiveCount);

    for i := 0 to ActiveCount - 1 do
      Workers[i] := TSingleMasterWorker.Create(Self, FMasterServers[i], FFilters, FRegion, FMaxServersPerMaster);

    // Wait for all master queries to complete
    for i := 0 to ActiveCount - 1 do
    begin
      Workers[i].WaitFor;
      Workers[i].Free;
    end;

    if not Terminated then
    begin
      FSyncTotalCount := FTotalDiscovered;
      FSyncSuccess := True;
      FSyncError := '';
      Synchronize(DoSyncFinished);
    end;
  finally
    WSACleanup;
  end;
end;

{ TA2SWorkerThread }

type
  TA2SWorkerThread = class(TThread)
  private
    FOwner: TA2SInfoThread;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TA2SInfoThread);
  end;

constructor TA2SWorkerThread.Create(AOwner: TA2SInfoThread);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
end;

procedure TA2SWorkerThread.Execute;
var
  ItemIndex: Integer;
  TargetServer: TServerInfo;
  Sock: TSocket;
  SrvAddr, FromAddr: sockaddr_in;
  FromLen: Integer;
  ReqBuf: array[0..31] of Byte;
  RecvBuf: array[0..4095] of Byte;
  RecvLen: Integer;
  TV: DWORD;
  PerfFreq, PerfStart, PerfEnd: Int64;
  Elapsed: Integer;
  Offset: Integer;
  HeaderType: Byte;
  Updated: TServerInfo;
  TimeoutVal: DWORD;
begin
  if not QueryPerformanceFrequency(PerfFreq) or (PerfFreq <= 0) then
    PerfFreq := 10000000;

  TimeoutVal := DWORD(FOwner.FTimeoutMs);
  if TimeoutVal = 0 then
    TimeoutVal := 350;

  FillChar(ReqBuf, SizeOf(ReqBuf), 0);
  Move(PAnsiChar(#$FF#$FF#$FF#$FF'TSource Engine Query'#0)^, ReqBuf[0], 25);

  while not Terminated and not FOwner.Terminated do
  begin
    if not FOwner.DequeueItem(ItemIndex, TargetServer) then
    begin
      if FOwner.FMasterScanFinished then
        Break;

      WaitForSingleObject(FOwner.FQueueEvent, 40);
      Continue;
    end;

    Updated := TargetServer;

    FillChar(SrvAddr, SizeOf(SrvAddr), 0);
    SrvAddr.sin_family := AF_INET;
    SrvAddr.sin_port := htons(Updated.Port);
    SrvAddr.sin_addr.S_addr := inet_addr(PAnsiChar(UTF8String(Updated.IP)));

    Sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if Sock <> INVALID_SOCKET then
    try
      TV := TimeoutVal;
      setsockopt(Sock, SOL_SOCKET, SO_RCVTIMEO, PAnsiChar(@TV), SizeOf(TV));

      QueryPerformanceCounter(PerfStart);
      sendto(Sock, ReqBuf[0], 25, 0, PSockAddr(@SrvAddr), SizeOf(SrvAddr));

      FromLen := SizeOf(FromAddr);
      RecvLen := recvfrom(Sock, RecvBuf[0], SizeOf(RecvBuf), 0, PSockAddr(@FromAddr)^, FromLen);
      QueryPerformanceCounter(PerfEnd);
      Elapsed := Integer(Round(((PerfEnd - PerfStart) * 1000.0) / PerfFreq));

      // Check if server replied with Challenge ($41 'A')
      if (RecvLen = 9) and (RecvBuf[0] = $FF) and (RecvBuf[1] = $FF) and
         (RecvBuf[2] = $FF) and (RecvBuf[3] = $FF) and (RecvBuf[4] = $41) and
         (FromAddr.sin_addr.S_addr = SrvAddr.sin_addr.S_addr) then
      begin
        Move(RecvBuf[5], ReqBuf[25], 4);
        QueryPerformanceCounter(PerfStart);
        sendto(Sock, ReqBuf[0], 29, 0, PSockAddr(@SrvAddr), SizeOf(SrvAddr));
        FromLen := SizeOf(FromAddr);
        RecvLen := recvfrom(Sock, RecvBuf[0], SizeOf(RecvBuf), 0, PSockAddr(@FromAddr)^, FromLen);
        QueryPerformanceCounter(PerfEnd);
        Elapsed := Integer(Round(((PerfEnd - PerfStart) * 1000.0) / PerfFreq));
      end;

      if Elapsed < 1 then
        Elapsed := 1;

      if (RecvLen > 5) and (RecvBuf[0] = $FF) and (RecvBuf[1] = $FF) and
         (RecvBuf[2] = $FF) and (RecvBuf[3] = $FF) and
         (FromAddr.sin_addr.S_addr = SrvAddr.sin_addr.S_addr) then
      begin
        HeaderType := RecvBuf[4];
        Updated.Ping := Elapsed;
        Updated.Responded := True;
        Offset := 5;

        if HeaderType = $49 then // 'I' - Standard Source / ReHLDS modern
        begin
          Inc(Offset); // skip Protocol version byte
          Updated.Name := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Map := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Folder := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Game := ReadNullString(RecvBuf, RecvLen, Offset);

          Inc(Offset, 2); // Skip AppID
          if Offset < RecvLen then
            Updated.Players := RecvBuf[Offset];
          Inc(Offset);
          if Offset < RecvLen then
            Updated.MaxPlayers := RecvBuf[Offset];
          Inc(Offset);
          if Offset < RecvLen then
            Updated.Bots := RecvBuf[Offset];
        end
        else if HeaderType = $6D then // 'm' - Classic GoldSrc info
        begin
          ReadNullString(RecvBuf, RecvLen, Offset); // Skip IP
          Updated.Name := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Map := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Folder := ReadNullString(RecvBuf, RecvLen, Offset);
          Updated.Game := ReadNullString(RecvBuf, RecvLen, Offset);

          if Offset < RecvLen then
            Updated.Players := RecvBuf[Offset];
          Inc(Offset);
          if Offset < RecvLen then
            Updated.MaxPlayers := RecvBuf[Offset];
        end;

        FOwner.ReportServerUpdate(ItemIndex, Updated);
      end
      else
      begin
        Updated.Name := '(Таймаут опроса)';
        Updated.Responded := False;
        Updated.Ping := 999999;
        FOwner.ReportServerUpdate(ItemIndex, Updated);
      end;
    finally
      closesocket(Sock);
    end;

    FOwner.ReportProgress;
  end;
end;

{ TA2SInfoThread }

constructor TA2SInfoThread.Create(TimeoutMs: Integer; WorkerCount: Integer;
  OnServerUpdate: TServerUpdateEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FTimeoutMs := TimeoutMs;
  if FTimeoutMs <= 0 then
    FTimeoutMs := 350;

  FWorkerCount := WorkerCount;
  if FWorkerCount < 1 then
    FWorkerCount := 1;
  if FWorkerCount > 10 then
    FWorkerCount := 10;

  FOnServerUpdate := OnServerUpdate;
  FOnStatus := OnStatus;
  FOnFinished := OnFinished;

  FCritSec := TCriticalSection.Create;
  FQueueLock := TCriticalSection.Create;
  FQueueEvent := CreateEvent(nil, False, False, nil);
  FMasterScanFinished := False;
  FQueueHead := 0;
  SetLength(FQueue, 0);
  SetLength(FWorkers, 0);
  FSuccessCount := 0;
  FProcessedCount := 0;
  FTotalEnqueued := 0;
end;

constructor TA2SInfoThread.Create(const Servers: TServerArray; TimeoutMs: Integer; WorkerCount: Integer;
  OnServerUpdate: TServerUpdateEvent; OnStatus: TStatusEvent; OnFinished: TFinishedEvent);
var
  i: Integer;
begin
  Create(TimeoutMs, WorkerCount, OnServerUpdate, OnStatus, OnFinished);
  for i := 0 to High(Servers) do
    EnqueueServer(i, Servers[i]);
  SetMasterScanFinished;
end;

destructor TA2SInfoThread.Destroy;
begin
  if FQueueEvent <> 0 then
    CloseHandle(FQueueEvent);
  FQueueLock.Free;
  FCritSec.Free;
  inherited Destroy;
end;

procedure TA2SInfoThread.Terminate;
var
  i: Integer;
begin
  inherited Terminate;
  SetEvent(FQueueEvent);
  FQueueLock.Enter;
  try
    for i := 0 to High(FWorkers) do
      if Assigned(FWorkers[i]) then
        FWorkers[i].Terminate;
  finally
    FQueueLock.Leave;
  end;
end;

function TA2SInfoThread.DequeueItem(var OutIndex: Integer; var OutServer: TServerInfo): Boolean;
begin
  Result := False;
  FQueueLock.Enter;
  try
    if FQueueHead < Length(FQueue) then
    begin
      OutIndex := FQueue[FQueueHead].Index;
      OutServer := FQueue[FQueueHead].Server;
      Inc(FQueueHead);
      Result := True;
    end;
  finally
    FQueueLock.Leave;
  end;
end;

procedure TA2SInfoThread.EnqueueServer(Index: Integer; const Server: TServerInfo);
var
  Len: Integer;
begin
  FQueueLock.Enter;
  try
    Len := Length(FQueue);
    SetLength(FQueue, Len + 1);
    FQueue[Len].Index := Index;
    FQueue[Len].Server := Server;
    Inc(FTotalEnqueued);
  finally
    FQueueLock.Leave;
  end;
  SetEvent(FQueueEvent);
end;

procedure TA2SInfoThread.SetMasterScanFinished;
begin
  FMasterScanFinished := True;
  SetEvent(FQueueEvent);
end;

procedure TA2SInfoThread.DoSyncServerUpdate;
begin
  if Assigned(FOnServerUpdate) and not Terminated then
    FOnServerUpdate(FSyncIndex, FSyncServer);
end;

procedure TA2SInfoThread.DoSyncStatus;
begin
  if Assigned(FOnStatus) and not Terminated then
    FOnStatus(FSyncStatus, FSyncProgress, FSyncTotal);
end;

procedure TA2SInfoThread.DoSyncFinished;
begin
  if Assigned(FOnFinished) and not Terminated then
    FOnFinished(FSuccessCount, True, '');
end;

procedure TA2SInfoThread.ReportServerUpdate(Index: Integer; const Server: TServerInfo);
begin
  if Server.Responded then
    TInterlocked.Increment(FSuccessCount);

  FCritSec.Enter;
  try
    FSyncIndex := Index;
    FSyncServer := Server;
    Synchronize(DoSyncServerUpdate);
  finally
    FCritSec.Leave;
  end;
end;

procedure TA2SInfoThread.ReportProgress;
var
  Cur, Total: Integer;
begin
  Cur := TInterlocked.Increment(FProcessedCount);
  Total := FTotalEnqueued;
  if (Cur mod 3 = 0) or (Cur >= Total) then
  begin
    FCritSec.Enter;
    try
      FSyncStatus := Format('Querying servers (A2S): %d / %d (Responded: %d)...',
        [Cur, Total, FSuccessCount]);
      FSyncProgress := Cur;
      FSyncTotal := Total;
      Synchronize(DoSyncStatus);
    finally
      FCritSec.Leave;
    end;
  end;
end;

procedure TA2SInfoThread.Execute;
var
  WSA: TWSAData;
  i: Integer;
begin
  if WSAStartup($0202, WSA) <> 0 then
  begin
    Synchronize(DoSyncFinished);
    Exit;
  end;

  try
    FQueueLock.Enter;
    try
      SetLength(FWorkers, FWorkerCount);
      for i := 0 to FWorkerCount - 1 do
        FWorkers[i] := TA2SWorkerThread.Create(Self);
    finally
      FQueueLock.Leave;
    end;

    for i := 0 to FWorkerCount - 1 do
    begin
      FWorkers[i].WaitFor;
      FWorkers[i].Free;
    end;

    FQueueLock.Enter;
    try
      SetLength(FWorkers, 0);
    finally
      FQueueLock.Leave;
    end;

    if not Terminated then
      Synchronize(DoSyncFinished);
  finally
    WSACleanup;
  end;
end;

end.
