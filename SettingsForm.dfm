object FormSettings: TFormSettings
  Left = 200
  Top = 100
  BorderStyle = bsDialog
  Caption = 'Настройки MSMonitor'
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
    Caption = ' Исполняемые файлы игр (.exe / .cmd) '
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
      Width = 230
      Height = 13
      Caption = 'Клиент Half-Life 1 (hl.exe, RUN_HL.exe):'
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
      Width = 243
      Height = 13
      Caption = 'Клиент Counter-Strike 1.6 (hl.exe, cstrike.exe):'
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
      Caption = 'Обзор...'
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
      Caption = 'Обзор...'
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
    Caption = ' Список MasterServer '
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
      Caption = 'Серверы (host:port, по одному на строку):'
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
    Caption = ' Фильтры игр (gamedir) '
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
      Caption = 'Моды игр (по одному на строку):'
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
    Caption = ' Параметры опроса '
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
      Width = 149
      Height = 13
      Caption = 'Потоки опроса (1-10 потоков):'
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
      Width = 144
      Height = 13
      Caption = 'Таймаут опроса (A2S_INFO):'
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
      Width = 41
      Height = 13
      Caption = 'Регион:'
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
      Caption = 'Лимит серверов на мастер:'
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
        '1 поток'
        '2 потока'
        '3 потока'
        '4 потока'
        '5 потоков'
        '6 потоков'
        '7 потоков'
        '8 потоков'
        '9 потоков'
        '10 потоков (Максимум)')
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
        '350 мс (Быстрый)'
        '600 мс (Обычный)'
        '1000 мс (Глубокий)')
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
        'Весь мир (0xFF)'
        'Европа (0x03)'
        'США Восток (0x00)'
        'США Запад (0x01)'
        'Азия (0x04)')
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
        '200 серверов'
        '600 серверов'
        '1000 серверов'
        '3000 серверов'
        'Все доступные')
    end
  end
  object grpAppearance: TGroupBox
    Left = 12
    Top = 495
    Width = 516
    Height = 56
    Caption = ' Стиль оформления интерфейса '
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
      Width = 110
      Height = 13
      Caption = 'Тема оформления:'
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
        'Светлый стиль (по умолчанию)'
        'Темный стиль (Windows 10 Dark)')
    end
  end
  object grpFilterOptions: TGroupBox
    Left = 12
    Top = 557
    Width = 516
    Height = 120
    Caption = ' Сортировка, фильтрация и автообновление '
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
      Caption = 'Скрывать пустые серверы (0 игроков)'
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
      Caption = 'Скрывать не ответившие серверы (таймаут опроса)'
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
      Caption = 'Автоматический переопрос серверов в фоне каждую минуту'
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
      Width = 100
      Height = 13
      Caption = 'Сортировка списка:'
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
        'По пингу (по возрастанию, меньше - выше)'
        'По игрокам (по убыванию, больше - выше)'
        'По названию сервера (А-Я)'
        'По карте (А-Я)'
        'По моду / папке (А-Я)'
        'По IP адресу и порту'
        'По мастер-серверу (А-Я)')
    end
  end
  object btnOK: TButton
    Left = 330
    Top = 688
    Width = 95
    Height = 32
    Caption = 'Сохранить'
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
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 7
  end
  object dlgOpen: TOpenDialog
    DefaultExt = 'exe'
    Filter = 'Исполняемые файлы (*.exe;*.cmd;*.bat)|*.exe;*.cmd;*.bat|Все файлы (*.*)|*.*'
    Title = 'Выберите исполняемый файл игры'
    Left = 250
    Top = 688
  end
end
