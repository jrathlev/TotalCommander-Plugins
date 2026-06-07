object ListGotoDialog: TListGotoDialog
  Left = 227
  Top = 108
  ActiveControl = edNumber
  BorderStyle = bsDialog
  Caption = 'Line Lister'
  ClientHeight = 98
  ClientWidth = 177
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = True
  Position = poDesigned
  OnCloseQuery = FormCloseQuery
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 10
    Top = 15
    Width = 46
    Height = 13
    Caption = 'Goto line:'
  end
  object OKBtn: TButton
    Left = 10
    Top = 65
    Width = 76
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 90
    Top = 65
    Width = 76
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object edNumber: TEdit
    Left = 10
    Top = 35
    Width = 121
    Height = 21
    TabOrder = 2
  end
end
