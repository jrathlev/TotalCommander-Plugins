object LLSettingsDialog: TLLSettingsDialog
  Left = 227
  Top = 108
  BorderStyle = bsDialog
  Caption = 'LineLister settings'
  ClientHeight = 170
  ClientWidth = 329
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = True
  Position = poDesigned
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object OKBtn: TButton
    Left = 240
    Top = 105
    Width = 76
    Height = 26
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 240
    Top = 135
    Width = 76
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object paFileSize: TPanel
    Left = 215
    Top = 10
    Width = 106
    Height = 56
    BevelOuter = bvNone
    TabOrder = 3
    object Label1: TLabel
      Left = 5
      Top = 5
      Width = 86
      Height = 13
      Caption = 'Maximum file size:'
    end
    object Label2: TLabel
      Left = 85
      Top = 30
      Width = 14
      Height = 13
      Caption = 'MB'
    end
    object edFilesize: TEdit
      Left = 5
      Top = 25
      Width = 71
      Height = 21
      TabOrder = 0
    end
  end
  object paFileTypes: TPanel
    Left = 5
    Top = 10
    Width = 201
    Height = 151
    BevelOuter = bvNone
    TabOrder = 2
    object cbSelected: TCheckBox
      Left = 5
      Top = 5
      Width = 171
      Height = 17
      Caption = 'Show only selected file types'
      TabOrder = 0
    end
    object lbTypes: TListBox
      Left = 5
      Top = 30
      Width = 191
      Height = 86
      Columns = 4
      ItemHeight = 13
      TabOrder = 1
    end
    object btDelete: TButton
      Left = 105
      Top = 125
      Width = 91
      Height = 26
      Caption = 'Delete'
      TabOrder = 3
      OnClick = btDeleteClick
    end
    object btAdd: TButton
      Left = 5
      Top = 125
      Width = 91
      Height = 26
      Caption = 'Add'
      TabOrder = 2
      OnClick = btAddClick
    end
  end
end
