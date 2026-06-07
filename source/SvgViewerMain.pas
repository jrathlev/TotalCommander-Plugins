(* Delphi Unit
   SVG viewer main form
   ====================

   SvgViewer is a Total Commander Lister plugin

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   April 2026

   last modified: June 2026
   *)

unit SvgViewerMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, SVGIconImage;

type
  TfrmMain = class(TForm)
    imgSvg: TSVGIconImage;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private-Deklarationen }
    FListerWindow : HWND;
    FFileName : string;
    procedure ReLoadImg;
  public
    { Public-Deklarationen }
    constructor CreateParented(AParentWindow: HWND);
    class function PluginShow(AParentWin: HWND; const AFileName: string): HWND;
    class function PluginHide(AListerWin: HWND): HWND;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses MsgDialogs, AppLog;

{ ------------------------------------------------------------------- }
constructor TfrmMain.CreateParented (AParentWindow : HWND);
begin
  inherited CreateParented(AParentWindow);
  FListerWindow:=AParentWindow;
  end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift=[]) then begin
    if (Key=VK_F1) then begin
      InfoDialog(CenterPos,'Total Commander Lister plugin'+sLineBreak+
        'SVG viewer'+sLineBreak+'(c) 2026 Dr. J. Rathlev'+sLineBreak+
        'The program uses routines from'+sLineBreak+
        '- SVGIconImageList package by Ethea - https://ethea.it/docs/svgiconimagelist'+sLineBreak+
        '- Image32 library by Angus Johnson - https://angusj.com/image32/Docs/_Body.htm');
      Key:=0;
      end
    else if (Key=VK_F2) then begin
      ReLoadImg;
      Key:=0;
      end
    else if (Key=VK_ESCAPE) then begin
      PostMessage(FListerWindow,WM_CLOSE,0,0);
      Key:=0;
      end;
    end;
  end;

procedure TfrmMain.ReLoadImg;
begin
  imgSvg.LoadFromFile(FFileName);
  end;

{ ------------------------------------------------------------------- }
class function TfrmMain.PluginShow(AParentWin: HWND; const AFileName: string): HWND;
var
  FrmMain: TFrmMain;
  r  : TRect;
begin
  Result:=0;
  if AnsiSameText(ExtractFileExt(AFilename),'.svg') and FileExists(AFileName) then begin
    try
      frmMain:=TfrmMain.CreateParented(AParentWin);
      Winapi.Windows.GetClientRect(AParentWin,r);
      with frmMain do begin
        ParentWindow:=AParentWin;
        Left:=r.Left;
        Top:=r.Top;
        ClientWidth:=r.Width;
        ClientHeight:=r.Height;
        BorderStyle:=bsNone;
        Visible:=true;
        FFilename:=AFilename;
        imgSvg.LoadFromFile(AFilename);
        end;
      Result:=frmMain.Handle;
      SetWindowLongPtr(Result, GWLP_USERDATA, LONG_PTR(frmMain));
  //    AppLogWrite('PluginShow'+' '+IntToStr(LONG_PTR(frmMain)));
    except
      on E: Exception do
      begin
        AppLogException('PluginShow',E);
        raise;
        end;
      end;
    end;
  end;

class function TfrmMain.PluginHide(AListerWin: HWND): HWND;
var
  Data: LONG_PTR;
  FrmMain: TFrmMain;
begin
  Result:= 0;
  Data:= GetWindowLongPtr(AListerWin, GWLP_USERDATA);
//  AppLogWrite('PluginHide'+' '+IntToStr(Data));
  if Data=0 then exit;
  frmMain:= TfrmMain(Data);
  try
//    frmMain.SaveHistory;
    frmMain.Close;
    frmMain.Free;
    SetWindowLongPtr(AListerWin, GWLP_USERDATA, 0);
  except
    on E: Exception do
    begin
      AppLogException('PluginHide',E);
      raise;
      end;
    end;
  end;

end.
