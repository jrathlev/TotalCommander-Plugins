(* Delphi project file
   Svg viewer project file
   =======================

   SvgViewer is a Total Commander Lister plugin
   Features:
   -  Display SVG images

   Supported keys:
   F2 : reload text
   Esc : close

   F1, F4, .., F12, numbers and letters are redirected to caller

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   The program uses routines from the following packages
     SVGIconImageList package by Ethea - https://ethea.it/docs/svgiconimagelist
     Image32 library by Angus Johnson - https://angusj.com/image32/Docs/_Body.htm

   April 2026

   last modified: May 2026
   *)

library SvgViewer;

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  AppLog in 'AppLog.pas',
  SvgViewerMain in 'SvgViewerMain.pas' {frmMain};

{$IFDEF WIN32}
  {$E wlx}
{$ELSE}
  {$E wlx64}
{$ENDIF}
{$R *.res}
{$R image.res}

const
  lc_copy=1;
  lc_newparams=2;
  lc_selectall=3;
  lc_setpercent=4;

  lcp_wraptext=1;
  lcp_fittowindow=2;
  lcp_ansi=4;
  lcp_ascii=8;
  lcp_variable=12;
  lcp_forceshow=16;
  lcp_fitlargeronly=32;
  lcp_center=64;
  lcp_darkmode=128;
  lcp_darkmodenative=256;

  lcs_findfirst=1;
  lcs_matchcase=2;
  lcs_wholewords=4;
  lcs_backwards=8;

  itm_percent=$FFFE;
  itm_fontstyle=$FFFD;
  itm_wrap=$FFFC;
  itm_fit=$FFFB;
  itm_next=$FFFA;
  itm_center=$FFF9;
  itm_focus=$FFF8;

  LISTPLUGIN_OK=0;
  LISTPLUGIN_ERROR=1;

  cDetectString: AnsiString = 'EXT="SVG"';

  BusyClose: boolean = false;

type
  TListDefaultParamStruct = record
    size,
    PluginInterfaceVersionLow,
    PluginInterfaceVersionHi:longint;
    DefaultIniName:array[0..MAX_PATH-1] of AnsiChar;
  end;
  pListDefaultParamStruct=^TListDefaultParamStruct;

procedure ListGetDetectString(DetectString: PAnsiChar; MaxLen: integer); stdcall;
begin
  StrLCopy(DetectString,PAnsiChar(cDetectString),MaxLen);
  end;

function ListLoadW(ParentWin: HWND; FileToLoad : PWideChar; ShowFlags: integer): HWND; stdcall;
var
  fn: string;
begin
  Result:= 0;
  if BusyClose then exit;
  try
    fn:=WideString(FileToLoad);
    Result:=TfrmMain.PluginShow(ParentWin,fn);
  except
    on E: Exception do
    begin
      AppLogException('ListLoad',E);
      raise;
      end;
    end;
  end;

function ListLoad(ParentWin: HWND; FileToLoad : PAnsiChar; ShowFlags: integer): HWND; stdcall;
begin
  Result:= ListLoadW(ParentWin,PWideChar(WideString(FileToLoad)),ShowFlags);
  end;

procedure ListCloseWindow(ListerWin: HWND); stdcall;
begin
  if BusyClose then exit;
  BusyClose:= true;
  try
    TfrmMain.PluginHide(ListerWin);
  except
    on E: Exception do
    begin
      AppLogException('ListCloseWindow',E);
      raise;
      end;
    end;
  DestroyWindow(ListerWin);
  BusyClose:= false;
  end;

exports
  ListGetDetectString,
  ListLoad,
  ListLoadW,
  ListCloseWindow;

end.
