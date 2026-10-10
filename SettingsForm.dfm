object FormSettings: TFormSettings
  Left = 200
  Top = 100
  BorderStyle = bsDialog
  Caption = 'MSMonitor Settings'
  ClientHeight = 730
  ClientWidth = 540
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 13
  object grpGames: TGroupBox
    Left = 12
    Top = 10
    Width = 516
    Height = 135
    Caption = ' Game Executables (.exe / .cmd) '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object lblHL: TLabel
      Left = 14
      Top = 22
      Width = 220
      Height = 13
      Caption = 'Half-Life 1 Executable (hl.exe, RUN_HL.exe):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblCS: TLabel
      Left = 14
      Top = 74
      Width = 240
      Height = 13
      Caption = 'Counter-Strike 1.6 Executable (hl.exe, cstrike.exe):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object edtHL: TEdit
      Left = 14
      Top = 40
      Width = 400
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object btnBrowseHL: TButton
      Left = 422
      Top = 39
      Width = 80
      Height = 23
      Caption = 'Browse...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnBrowseHLClick
    end
    object edtCS: TEdit
      Left = 14
      Top = 92
      Width = 400
      Height = 21
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object btnBrowseCS: TButton
      Left = 422
      Top = 91
      Width = 80
      Height = 23
      Caption = 'Browse...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = btnBrowseCSClick
    end
  end
  object grpMasterServers: TGroupBox
    Left = 12
    Top = 152
    Width = 250
    Height = 195
    Caption = ' Master Servers '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object lblMasterList: TLabel
      Left = 10
      Top = 20
      Width = 215
      Height = 13
      Caption = 'Servers (host:port, one per line):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object mmoMasterServers: TMemo
      Left = 10
      Top = 38
      Width = 230
      Height = 145
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object grpFilters: TGroupBox
    Left = 270
    Top = 152
    Width = 258
    Height = 195
    Caption = ' Game Filters (gamedir) '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object lblFilterList: TLabel
      Left = 10
      Top = 20
      Width = 205
      Height = 13
      Caption = 'Game mods (one per line):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object mmoGameFilters: TMemo
      Left = 10
      Top = 38
      Width = 238
      Height = 145
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object grpQuery: TGroupBox
    Left = 12
    Top = 354
    Width = 516
    Height = 135
    Caption = ' Query Settings '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    object lblThreads: TLabel
      Left = 14
      Top = 24
      Width = 150
      Height = 13
      Caption = 'Query threads (1-10 threads):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblTimeout: TLabel
      Left = 265
      Top = 24
      Width = 145
      Height = 13
      Caption = 'Query timeout (A2S_INFO):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblRegion: TLabel
      Left = 14
      Top = 76
      Width = 40
      Height = 13
      Caption = 'Region:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblLimit: TLabel
      Left = 265
      Top = 76
      Width = 145
      Height = 13
      Caption = 'Server limit per master:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cbThreads: TComboBox
      Left = 14
      Top = 42
      Width = 235
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 9
      ParentFont = False
      TabOrder = 0
      Items.Strings = (
        '1 thread'
        '2 threads'
        '3 threads'
        '4 threads'
        '5 threads'
        '6 threads'
        '7 threads'
        '8 threads'
        '9 threads'
        '10 threads (Maximum)')
    end
    object cbTimeout: TComboBox
      Left = 265
      Top = 42
      Width = 235
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 1
      Items.Strings = (
        '350 ms (Fast)'
        '600 ms (Normal)'
        '1000 ms (Deep)')
    end
    object cbRegion: TComboBox
      Left = 14
      Top = 94
      Width = 235
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 2
      Items.Strings = (
        'Worldwide (0xFF)'
        'Europe (0x03)'
        'US East (0x00)'
        'US West (0x01)'
        'Asia (0x04)')
    end
    object cbLimit: TComboBox
      Left = 265
      Top = 94
      Width = 235
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 1
      ParentFont = False
      TabOrder = 3
      Items.Strings = (
        '200 servers'
        '600 servers'
        '1000 servers'
        '3000 servers'
        'All available')
    end
  end
  object grpAppearance: TGroupBox
    Left = 12
    Top = 495
    Width = 516
    Height = 56
    Caption = ' Appearance Style '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    object lblTheme: TLabel
      Left = 14
      Top = 23
      Width = 40
      Height = 13
      Caption = 'Theme:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cbTheme: TComboBox
      Left = 140
      Top = 20
      Width = 360
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 0
      Items.Strings = (
        'Light Style (Default)'
        'Dark Style (Windows 10 Dark)')
    end
  end
  object grpFilterOptions: TGroupBox
    Left = 12
    Top = 557
    Width = 516
    Height = 120
    Caption = ' Sorting, Filtering and Auto-Refresh '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    object chkHideEmpty: TCheckBox
      Left = 14
      Top = 18
      Width = 480
      Height = 17
      Caption = 'Hide empty servers (0 players)'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 0
    end
    object chkHideUnresponsive: TCheckBox
      Left = 14
      Top = 38
      Width = 480
      Height = 17
      Caption = 'Hide unresponsive servers (query timeout)'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 1
    end
    object chkAutoRefresh: TCheckBox
      Left = 14
      Top = 58
      Width = 480
      Height = 17
      Caption = 'Automatically refresh servers in background every minute'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 2
    end
    object lblSort: TLabel
      Left = 14
      Top = 88
      Width = 65
      Height = 13
      Caption = 'List sorting:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object cbSort: TComboBox
      Left = 130
      Top = 85
      Width = 370
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemIndex = 0
      ParentFont = False
      TabOrder = 3
      Items.Strings = (
        'By ping (ascending, lowest ping first)'
        'By players (descending, highest players first)'
        'By server name (A-Z)'
        'By map (A-Z)'
        'By mod / folder (A-Z)'
        'By IP address and port'
        'By master server (A-Z)')
    end
  end
  object btnOK: TButton
    Left = 330
    Top = 688
    Width = 95
    Height = 32
    Caption = 'Save'
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancel: TButton
    Left = 433
    Top = 688
    Width = 95
    Height = 32
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
  object dlgOpen: TOpenDialog
    DefaultExt = 'exe'
    Filter = 'Executable Files (*.exe;*.cmd;*.bat)|*.exe;*.cmd;*.bat|All Files (*.*)|*.*'
    Title = 'Select Game Executable'
    Left = 250
    Top = 688
  end
end
