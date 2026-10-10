object FormMain: TFormMain
  Left = 150
  Top = 100
  Caption = 'Half-Life & GoldSrc MasterServer Monitor'
  ClientHeight = 620
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pnlButtons: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = True
    TabOrder = 0
    object btnFetch: TButton
      Left = 10
      Top = 6
      Width = 145
      Height = 32
      Caption = 'Опросить серверы'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnFetchClick
    end
    object btnStop: TButton
      Left = 160
      Top = 6
      Width = 85
      Height = 32
      Caption = 'Остановить'
      Enabled = False
      TabOrder = 1
      OnClick = btnStopClick
    end
    object btnFavorite: TButton
      Left = 250
      Top = 6
      Width = 115
      Height = 32
      Caption = '★ В избранное'
      TabOrder = 2
      OnClick = btnFavoriteClick
    end
    object btnConnect: TButton
      Left = 370
      Top = 6
      Width = 105
      Height = 32
      Caption = 'Подключиться'
      TabOrder = 3
      OnClick = btnConnectClick
    end
    object btnCopy: TButton
      Left = 480
      Top = 6
      Width = 125
      Height = 32
      Caption = 'Копировать IP:Port'
      TabOrder = 4
      OnClick = btnCopyClick
    end
    object btnSettings: TButton
      Left = 610
      Top = 6
      Width = 105
      Height = 32
      Caption = 'Настройки...'
      TabOrder = 5
      OnClick = btnSettingsClick
    end
    object btnExport: TButton
      Left = 720
      Top = 6
      Width = 85
      Height = 32
      Caption = 'Экспорт...'
      TabOrder = 6
      OnClick = btnExportClick
    end
    object btnClear: TButton
      Left = 810
      Top = 6
      Width = 75
      Height = 32
      Caption = 'Очистить'
      TabOrder = 7
      OnClick = btnClearClick
    end
  end
  object lvServers: TListView
    Left = 0
    Top = 44
    Width = 980
    Height = 532
    Align = alClient
    Columns = <
      item
        Caption = '#'
        Width = 40
      end
      item
        Caption = 'IP:Порт'
        Width = 145
      end
      item
        Caption = 'Название сервера'
        Width = 260
      end
      item
        Caption = 'Карта'
        Width = 110
      end
      item
        Caption = 'Игроки'
        Width = 65
      end
      item
        Caption = 'Пинг'
        Width = 65
      end
      item
        Caption = 'Мод'
        Width = 70
      end
      item
        Caption = 'Игра'
        Width = 85
      end
      item
        Caption = 'Мастер-сервер'
        Width = 140
      end>
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    GridLines = True
    MultiSelect = True
    RowSelect = True
    ParentFont = False
    PopupMenu = pmServers
    TabOrder = 1
    ViewStyle = vsReport
    OnColumnClick = lvServersColumnClick
    OnCompare = lvServersCompare
    OnCustomDrawItem = lvServersCustomDrawItem
    OnCustomDrawSubItem = lvServersCustomDrawSubItem
    OnDblClick = btnConnectClick
    OnSelectItem = lvServersSelectItem
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 576
    Width = 980
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = True
    TabOrder = 2
    object pbProgress: TProgressBar
      Left = 0
      Top = 0
      Width = 980
      Height = 14
      Align = alTop
      TabOrder = 0
    end
    object sbStatus: TStatusBar
      Left = 0
      Top = 14
      Width = 980
      Height = 30
      Panels = <
        item
          Text = ' Готов к работе.'
          Width = 430
        end
        item
          Text = ' Серверов: 0'
          Width = 150
        end
        item
          Text = ' Ответили: 0'
          Width = 150
        end
        item
          Text = ' Мастер-серверов: 0'
          Width = 240
        end>
    end
  end
  object dlgSave: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Текстовый файл (*.txt)|*.txt|Файл CSV (*.csv)|*.csv|Все файлы (*.*)|*.*'
    Left = 400
    Top = 250
  end
  object tmrAutoStart: TTimer
    Enabled = True
    Interval = 250
    OnTimer = tmrAutoStartTimer
    Left = 500
    Top = 250
  end
  object pmServers: TPopupMenu
    Left = 320
    Top = 250
    object miFavorite: TMenuItem
      Caption = '★ Добавить / Удалить из избранного'
      OnClick = btnFavoriteClick
    end
    object miSep1: TMenuItem
      Caption = '-'
    end
    object miConnect: TMenuItem
      Caption = 'Подключиться к серверу'
      OnClick = btnConnectClick
    end
    object miCopy: TMenuItem
      Caption = 'Копировать IP:Порт'
      OnClick = btnCopyClick
    end
    object miSep2: TMenuItem
      Caption = '-'
    end
    object miRefreshOne: TMenuItem
      Caption = 'Опросить выбранный сервер'
      OnClick = miRefreshOneClick
    end
  end
end
