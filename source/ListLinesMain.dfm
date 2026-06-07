object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'FrmMain'
  ClientHeight = 336
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object sbProperties: TStatusBar
    Left = 0
    Top = 310
    Width = 635
    Height = 26
    Panels = <
      item
        Text = 'Settings'
        Width = 150
      end
      item
        Width = 300
      end
      item
        Width = 1000
      end
      item
        Width = 300
      end>
    OnMouseDown = sbPropertiesMouseDown
  end
  object FindDialog: TFindDialog
    OnFind = FindDialogFind
    Left = 440
    Top = 65
  end
end
