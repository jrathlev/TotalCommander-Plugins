(* Delphi project file
   Line Lister project file
   ========================

   LineLister is a Total Commander Lister plugin
   Features:
   - Line numbers on the left margin
   - Find dialog with automatic word selection
   - Goto line dialog

   Supported keys:
   F2 : reload text
   F3 : repeat text search
   Esc : close
   Ctrl-A : select all
        C : copy text to clipboard
        F : find text (word at cursor)
        G : goto to given line
   Shft-F3 : repeat text search backwards

   F1, F4, .., F12, numbers and letters are redirected to caller

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   April 2026

   last modified: May 2026
   *)

library LineLister;

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Dialogs,
  AppLog in 'AppLog.pas',
  ListLinesMain in 'ListLinesMain.pas' {FrmMain};

{$IFDEF WIN32}
  {$E wlx}
{$ELSE}
  {$E wlx64}
{$ENDIF}
{$R *.res}
{$R list.res}

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

  cDetectString: AnsiString = '!((EXT="RTF") | ([0]="M" & [1]="Z") | ([0]="P" & [1]="K") | '
    +'([0]="%" & [1]="P" & [2]="D" & [3]="F"))';

  BusyClose: boolean = false;
  IniName = 'LineLister.ini';

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

procedure ListSetDefaultParams(dps : pListDefaultParamStruct); stdcall;
begin
  LoadFromIni(ExtractFilePath(string(dps^.DefaultIniName))+IniName);
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

function ListSendCommand(ListWin: HWND; Command, Parameter: integer): integer; stdcall;
begin
  Result:=LISTPLUGIN_OK;
  case Command of
  lc_copy: SendMessage(ListWin,WM_COPY,0,0);
  lc_selectall: SendMessage(ListWin,EM_SETSEL,0,-1);
  else Result:=LISTPLUGIN_ERROR;
    end;
  end;

function ListSearchTextW(ListWin: HWND; SearchString: PWideChar; SearchParameter: integer): integer; stdcall;
var
  Form : TfrmMain;
  so   : TFindOptions;
begin
  Result:= LISTPLUGIN_OK;
  try
    Form:= TfrmMain(FindControl(ListWin));
    if Assigned(Form) then begin
      so:=[];
      if (SearchParameter and lcs_backwards)=0 then Include(so,frDown);
      if (SearchParameter and lcs_findfirst)=0 then Include(so,frFindNext);
      if (SearchParameter and lcs_matchcase)<>0 then Include(so,frMatchCase);
      if (SearchParameter and lcs_wholewords)<>0 then Include(so,frWholeWord);
      Form.DoFind(string(SearchString),so);
      end;
  except
    on E: Exception do
    begin
      AppLogException(string(SearchString),E);
      raise;
      end;
    end;
  end;

function ListSearchText(ListWin: HWND; SearchString: PAnsiChar; SearchParameter: integer): integer; stdcall;
begin
  Result:= ListSearchTextW(ListWin,PWideChar(WideString(SearchString)),SearchParameter);
  end;

exports
  ListGetDetectString,
  ListSetDefaultParams,
  ListLoad,
  ListLoadW,
  ListCloseWindow,
  ListSendCommand,
  ListSearchTextW,
  ListSearchText;

end.
