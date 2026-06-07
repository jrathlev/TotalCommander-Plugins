object ListFindDialog: TListFindDialog
  Left = 227
  Top = 108
  ActiveControl = edFindText
  BorderStyle = bsDialog
  Caption = 'Line Lister'
  ClientHeight = 121
  ClientWidth = 375
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = True
  Position = poDesigned
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 10
    Top = 15
    Width = 47
    Height = 13
    Caption = 'Find text:'
  end
  object OKBtn: TButton
    Left = 210
    Top = 90
    Width = 76
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 290
    Top = 90
    Width = 76
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object cbWhole: TCheckBox
    Left = 10
    Top = 65
    Width = 171
    Height = 17
    Caption = 'Whole words only'
    TabOrder = 3
  end
  object cbBackwards: TCheckBox
    Left = 10
    Top = 90
    Width = 171
    Height = 17
    Caption = 'Search backwards'
    TabOrder = 4
  end
  object cbCaseSensitive: TCheckBox
    Left = 210
    Top = 65
    Width = 156
    Height = 17
    Caption = 'Case sensitive'
    TabOrder = 5
  end
  object edFindText: TComboBox
    Left = 10
    Top = 35
    Width = 356
    Height = 21
    DropDownCount = 15
    TabOrder = 2
  end
end
