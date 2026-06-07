(* Delphi Unit
   LineLister main form
   ====================

   LineLister is a Total Commander Lister plugin

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

unit ListLinesMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  ListFindDlg, ListGotoDlg, ListLineSettings;

type
  TLinkMemo = class(TMemo)
  private
    FLinkedMemo: TLinkMemo;
    procedure WMVScroll(var Message: TMessage); message WM_VSCROLL;
    procedure DoScroll(var Message: TMessage);
    procedure DoWheel(ScrollPos : integer);
  protected
    procedure WndProc(var WinMsg: TMessage); override;
  public
    property LinkedMemo: TLinkMemo read FLinkedMemo write FLinkedMemo;
  end;

  TFrmMain = class(TForm)
    FindDialog: TFindDialog;
    sbProperties: TStatusBar;
    procedure FindDialogFind(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbPropertiesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
  private
    { Private-Deklarationen }
    memText,memNumbers : TLinkMemo;
    FListerWindow : HWND;
    FFileName : string;
    FFileSize : int64;
    FOptions : TFindOptions;
    ListFindDialog: TListFindDialog;
    ListGotoDialog: TListGotoDialog;
    LLSettingsDialog: TLLSettingsDialog;
    VisibleLines,
    NumDigits : integer;
    procedure Find (Reverse : boolean = false);
    function LoadText (fs : TStream; enc : TEncoding) : boolean;
    procedure ReLoadText (const AFileName : string);
    procedure MemoChange(Sender: TObject);
    procedure ShowLine;
  public
    { Public-Deklarationen }
    constructor CreateParented(AParentWindow: HWND);
    class function PluginShow(AParentWin: HWND; const AFileName: string): HWND;
    class function PluginHide(AListerWin: HWND): HWND;
    procedure FindPrompt (const SearchString : string);
    procedure DoFind (const SearchString : string; SearchOptions : TFindOptions);
    procedure GotoLine;
  end;

procedure LoadFromIni (const AIniName : string);

var
  ListerIniName : string = '';
  MaxSize : integer = 8*1024*1024;
  IncludeExt : string = 'pas|asm|a51|h|cpp|log';
  ExcludeExt : string = 'rtf|doc';
  UseInclude : boolean = false;

implementation

{$R *.dfm}

uses System.Math, System.StrUtils, System.Character, System.WideStrUtils,
  System.Masks, System.IniFiles,
  MsgDialogs, AppLog;

const
  CfgSect = 'Config';
  IniSize = 'MaxSize';
  IniIncl = 'Include';
  IniUse  = 'UseInclude';

procedure TLinkMemo.DoScroll(var Message: TMessage);
var
  saveLinkedMemo  : TLinkMemo;
begin
  saveLinkedMemo:=FLinkedMemo;
  try
    FLinkedMemo := nil;
    Perform(Message.Msg, Message.WParam, Message.LParam);
  finally
    FLinkedMemo := saveLinkedMemo;
    end;
  end;

procedure TLinkMemo.WMVScroll(var Message: TMessage);
begin
  inherited;
  if FLinkedMemo <> nil then
    FLinkedMemo.DoScroll(Message);
  end;

procedure TLinkMemo.DoWheel(ScrollPos : integer);
var
  saveLinkedMemo  : TLinkMemo;
begin
  saveLinkedMemo:=FLinkedMemo;
  try
    FLinkedMemo := nil;
    Perform(WM_VSCROLL,MAKEWPARAM(SB_THUMBPOSITION,ScrollPos),0);
  finally
    FLinkedMemo := saveLinkedMemo;
    end;
  end;

procedure TLinkMemo.WndProc(var WinMsg: TMessage);
var
  scrollInfo : TScrollInfo;
begin
  inherited;
  with WinMsg do begin
    if Msg=WM_MOUSEWHEEL then begin
      if FLinkedMemo <> nil then begin
        with scrollInfo do begin
          cbSize:=SizeOf(scrollInfo);
          fMask:=SIF_POS;
          end;
        if GetScrollInfo(Handle,SB_VERT,scrollInfo) then
          FLinkedMemo.DoWheel(scrollInfo.nPos);
        end;
      end;
    end;
  end;

{ ------------------------------------------------------------------- }
procedure LoadFromIni (const AIniName : string);
begin
  ListerIniName:=AIniName;
  with TMemIniFile.Create(ListerIniName) do begin
    MaxSize:=ReadInteger(CfgSect,IniSize,MaxSize);
    IncludeExt:=ReadString(CfgSect,IniIncl,IncludeExt);
    UseInclude:=ReadBool(CfgSect,IniUse,UseInclude);
    Free;
    end;
  end;

function LongFileSize (const FileName : string) : int64;
var
  FileData : TWin32FileAttributeData;
begin
  if GetFileAttributesEx(PChar(FileName),GetFileExInfoStandard,@FileData) then
    Result:=Int64(FileData.nFileSizeLow) or Int64(FileData.nFileSizeHigh shl 32)
  else Result:=0;
  end;

function GroupDigits (const s : string) : string;
var
  i : integer;
  Sep : char;
const
  Group = 3;
begin
  Result:=s;
  Sep:=FormatSettings.ThousandSeparator; // Sep:=#$A0;
  i:=length(Result);
  while (i>Group) do begin
    dec(i,Group); Insert(Sep,Result,i+1);
    end;
  end;

function GetVisibleLines(const Memo: TMemo): Integer;
Var
  OldFont: HFont;
  DC: THandle;
  TextMetric: TTextMetric;
begin
  Result := 0;
  DC := GetDC(Memo.Handle);
  try
    OldFont := SelectObject(DC, Memo.Font.Handle);
    try
      GetTextMetrics(DC, TextMetric);
      Result := (Memo.ClientRect.Bottom - Memo.ClientRect.Top) div
               (TextMetric.tmHeight + TextMetric.tmExternalLeading);
    finally
      SelectObject(DC, OldFont);
    end;
  finally
    ReleaseDC(Memo.Handle, DC);
    end;
  end;

{ ------------------------------------------------------------------- }
constructor TfrmMain.CreateParented (AParentWindow : HWND);
begin
  inherited CreateParented(AParentWindow);
  FListerWindow:=AParentWindow;
  memText:=TLinkMemo.Create(self);
  memNumbers:=TLinkMemo.Create(self);
  with memNumbers do begin
    Parent:=self;
    Name:='memNumbers';
    Text:='';
    Align:=alLeft;
    LinkedMemo:=memText;
    Left:=0; Top:=0; Width:=21;
    BorderStyle:=bsNone;
    Color:=clMenu;
    ReadOnly:=true;
    TabStop:=false;
    AlignWithMargins:=true;
    with Margins do begin
      Left:=5; Top:=0;
      Right:=5; Bottom:=0;
      end;
    HideSelection:=false;
    end;
  with memText do begin
    Parent:=self;
    Name:='memText';
    Align:=alClient;
    LinkedMemo:=memNumbers;
    BorderStyle:=bsNone;
    ScrollBars:=ssVertical;
    WordWrap:=False;
    with Font do begin
      Name:='Courier New';
      Size:=10;
      end;
    ReadOnly:=true;
    OnClick:=MemoChange;
    end;
  memNumbers.Font:=memText.Font;
  ListFindDialog:=TListFindDialog.Create(self);
  ListFindDialog.LoadHistory(ListerIniName);
  ListGotoDialog:=TListGotoDialog.Create(self);
  LLSettingsDialog:=TLLSettingsDialog.Create(self);
  end;

procedure TFrmMain.MemoChange(Sender: TObject);
var
  n : integer;
begin
  n:=memText.CaretPos.y;
  with memNumbers do begin
    SelStart:=Perform(EM_LINEINDEX,n,0); SelLength:=NumDigits;
    end;
  end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  with TMemIniFile.Create(ListerIniName) do begin
    WriteInteger(CfgSect,IniSize,MaxSize);
    WriteString(CfgSect,iniIncl,IncludeExt);
    WriteBool(CfgSect,IniUse,UseInclude);
    UpdateFile;
    Free;
    end;
  ListFindDialog.SaveHistory;
  FreeAndNil(ListFindDialog);
  FreeAndNil(ListGotoDialog);
  FreeAndNil(LLSettingsDialog);
  memNumbers.Free; memText.Free;
  end;

{ ------------------------------------------------------------------- }
function SearchMemo(Memo: TMemo; const SearchString : String;
                    Options : TFindOptions;
                    Reverse : boolean = false) : Boolean;
var
  Buffer, P : PChar;
  Size,no,nl : integer;

  function FindOptionsToSearchOptions (FOptions : TFindOptions) : TStringSearchOptions;
  begin
    Result:=[];
    if (frDown in FOptions) xor Reverse then Include(Result,soDown);
    if frMatchCase in FOptions then Include(Result,soMatchCase);
    if frWholeWord in FOptions then Include(Result,soWholeWord);
    end;

begin
  Result := False;
  if (Length(SearchString) = 0) then Exit;
  Size := Memo.GetTextLen;
  if (Size = 0) then Exit;
  Buffer := StrAlloc(Size + 1);
  try
    Memo.GetTextBuf(Buffer, Size + 1);
    P := SearchBuf(Buffer, Size, Memo.SelStart, Memo.SelLength, SearchString, FindOptionsToSearchOptions(Options));
    if P <> nil then with memo do begin
      SelStart:= P - Buffer;     // Number of line has to be subtracted to get right value for SelStart ???
      SelLength := Length(SearchString);
      Result := True;
    end;
  finally
    StrDispose(Buffer);
  end;
end;

function GetWord (Memo: TMemo) : string;
var
  ia,ie,n : integer;
begin
  with Memo do begin
    if SelLength>0 then Result:=SelText
    else begin
      n:=SelStart+1; ia:=n; ie:=n+1;
      while (ia>1) and Text[ia].IsLetterOrDigit do dec(ia);
      while (ie<length(Text)) and Text[ie].IsLetterOrDigit do inc(ie);
      Result:=Trim(copy(Text,ia+1,ie-ia-1));
      end;
    end;
  end;

{ ------------------------------------------------------------------- }
procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift=[]) then begin
    if (Key=VK_F1) then begin
      InfoDialog(CenterPos,'Total Commander Lister plugin'+sLineBreak+
        'Text lister with line numbers'+sLineBreak+'(c) 2026 Dr. J. Rathlev');
      Key:=0;
      end
    else if (Key=VK_F2) then begin
      ReLoadText(FFilename);
      Key:=0;
      end
    else if (Key=VK_F3) then begin
      if FindDialog.FindText.IsEmpty then // FindPrompt(GetWord(memText))
        PostMessage(FListerWindow,WM_KEYDOWN,VK_F5,0)
      else Find(false);
      Key:=0;
      end
    else if (Key in [VK_F1..VK_F12]) or
        ((Key in [Ord('1')..Ord('8'), Ord('A')..Ord('W')])) then begin
      PostMessage(FListerWindow,WM_KEYDOWN,Key,0);
      Key:= 0;
      end
    else if (Key=VK_ESCAPE) then begin
      PostMessage(FListerWindow,WM_CLOSE,0,0);
      Key:=0;
      end;
    end
  else if (Shift=[ssCtrl]) then begin
    if (Key=Ord('A')) then begin
      memText.SelectAll;
      Key:= 0;
      end
    else if (Key=Ord('F')) then begin
//      if memText.SelLength>0 then DoFind(memText.SelText,FOptions)
//      else
      FindPrompt(GetWord(memText));
//      else PostMessage(FListerWindow,WM_KEYDOWN,VK_F7,0);
      Key:= 0;
      end
    else if (Key=Ord('G')) then begin  // goto line
      GotoLine;
      Key:= 0;
      end
    else if (Key=Ord('C')) then begin
      PostMessage(FListerWindow,WM_KEYDOWN,Key,VK_CONTROL);
      Key:= 0;
      end
    else if (Key=VK_HOME) then begin
      with memText do begin
        SelStart:=Perform(EM_LINEINDEX,0,0);
        Perform(EM_SCROLLCARET,0,0);
        end;
      Key:= 0;
      end
    else if (Key=VK_END) then begin
      with memText do begin
        SelStart:=Perform(EM_LINEINDEX,Lines.Count-1,0);
        Perform(EM_SCROLLCARET,0,0);
        end;
      Key:= 0;
      end
    end
  else if (Shift=[ssShift]) then begin
    if (Key=VK_F3) then begin
      if FindDialog.FindText.IsEmpty then PostMessage(FListerWindow,WM_KEYDOWN,VK_F7,0)
      else Find(true);
      Key:= 0;
      end;
    end;
  end;

procedure TFrmMain.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  MemoChange(Sender)
  end;

procedure TFrmMain.FormResize(Sender: TObject);
begin
  VisibleLines:=GetVisibleLines(memText);
  end;

{ ------------------------------------------------------------------- }
procedure TFrmMain.ShowLine;
var
  n,no,nl : integer;
const
  lDist = 3;
begin
  with memText do begin
    Perform(EM_SCROLLCARET,0,0);
    no:=Perform(EM_GETFIRSTVISIBLELINE,0,0);  // 1st visible line
    nl:=Perform(EM_LINEFROMCHAR,SelStart,0);  // line with search text
    if (nl<no+LDist) then n:=no-LDist-nl
    else if nl>no+VisibleLines-LDist then n:=VisibleLines-LDist
    else n:=0;
    Perform(EM_LINESCROLL,0,n);
    Perform(WM_MOUSEWHEEL,0,0);
    end;
  end;

procedure TFrmMain.FindDialogFind(Sender: TObject);
begin
  Find;
  end;

procedure TFrmMain.Find (Reverse : boolean);

  function CursorPos : TPoint;
  begin
    GetCursorPos(Result);
    end;

begin
  with FindDialog do
    if not SearchMemo(memText,FindText,Options,Reverse) then begin
      if length(FindText)>0 then ErrorDialog(CenterPos,Format('"%s" not found!',[FindText]))
      end
    else ShowLine; // Perform(EM_SCROLLCARET,0,0);
  end;

procedure TFrmMain.FindPrompt (const SearchString : string);
var
  s : string;
begin
  s:=SearchString;
  if ListFindDialog.Execute(s,FOptions) then with FindDialog do begin
    FindText:=s;
    Options:=FOptions;
    Find;
    end;
  memText.SetFocus;
  end;

procedure TFrmMain.DoFind (const SearchString : string; SearchOptions : TFindOptions);
begin
  FOptions:=SearchOptions;
  with FindDialog do begin
    FindText:=SearchString;
    Options:=SearchOptions;
    end;
  Find;
  end;

procedure TFrmMain.GotoLine;
var
  n : integer;
begin
  with memText do begin
    n:=CaretPos.y+1;
    if ListGotoDialog.Execute(Lines.Count,n) then begin
      SelStart:=Perform(EM_LINEINDEX,n-1,0);
      ShowLine;
//      Perform(EM_SCROLLCARET,0,0);
      SetFocus;
      end;
    end;
  end;

{ ------------------------------------------------------------------- }
function CheckFile (const AFileName : string; var FSize : int64) : boolean;
var
  i : integer;
  se : string;
  sl : TStringList;
begin
//  Result:=FileExists(AFileName);
  fSize:=LongFileSize(AFileName);
  if (FSize=0) or (FSize>MaxSize) then Result:=false
  else begin
    Result:=false;
    sl:=TStringList.Create;
    sl.Delimiter:=VertBar;
    se:=ExtractFileExt(AFileName);
    Delete(se,1,1);
    with sl do if UseInclude then begin
      DelimitedText:=IncludeExt;
      for i:=0 to Count-1 do if MatchesMask(se,Strings[i]) then begin
        Result:=true; Break;
        end;
      end
    else begin
      DelimitedText:=ExcludeExt;
      for i:=0 to Count-1 do if MatchesMask(se,Strings[i]) then Break;
      if i>=Count then Result:=true;
      end;
    sl.Free;
    end
  end;

function OpenStream (const AFileName : string; var fs : TFileStream) : boolean;
begin
  Result:=true;
  try
    fs:=TFileStream.Create(AFileName,fmOpenRead or fmShareDenyNone);
  except
    on E: Exception do begin
      AppLogException(Format('Open file "%s!',[AFileName]),E);
      Exit(false);
      end;
    end;
  end;

function CheckForText (fs : TStream; var enc : TEncoding) : boolean;
const
  MaxLen = 8192;
var
  i,n,k : integer;
  br  : boolean;
  buf : array of AnsiChar;
  bom8,bomu : TBytes;
begin
  Result:=false;
  enc:=nil; //TEncoding.Default;
  try
    SetLength(buf,MaxLen);
    n:=fs.Read(buf[0],MaxLen);
    SetLength(buf,n+1);
    buf[n]:=#0;
  except
    Exit;
    end;
  fs.Position:=0;
  bom8:=TEncoding.UTF8.GetPreamble;
  bomu:=TEncoding.Unicode.GetPreamble;
  Result:=CompareMem(@buf[0],@bomu[0],length(bomu))
    or CompareMem(@buf[0],@bom8[0],length(bom8));
  if not Result then begin
    Result:=IsUTF8String(RawByteString(buf));
    if Result then enc:=TEncoding.UTF8
    else if (n>10) then begin
      k:=0; br:=false;
      for i:=0 to n-1 do begin
        Br:=(buf[i]=#0) or (buf[i]=#$FF);
        if Br then Break
        else if (buf[i]>#$7F) then inc(k);
        end;
      if br then Result:=false
      else Result:=k<(n div 10);
      end;
    end;
  end;

function TFrmMain.LoadText (fs : TStream; enc : TEncoding) : boolean;
var
  i : integer;
  s : string;
  dt : TDateTime;

  function GetEncodingName (cp : integer) : string;
  const
    CP_UTF16 = 1200;
  var
    CpInfoEx : TCPInfoEx;
  begin
     // CP_UTF16 is not supported by GetCPInfoEx
    if cp=CP_UTF16 then Result:=IntToStr(CP_UTF16)+' (UTF-16)'
    else if GetCPInfoEx(cp,0,CpInfoEx) then begin
      Result:=CPInfoEx.CodePageName;
      end
    else Result:='';
    end;

begin
  Result:=false;
  with memText.Lines do begin
    Clear;
    LoadFromStream(fs,enc);
    with sbProperties do begin
      with Panels[0] do begin
        Width:=Canvas.TextWidth(Text)+Height;
        end;
      with Panels[1] do begin
        Text:='Codepage: '+GetEncodingName(Encoding.CodePage);
        Width:=Canvas.TextWidth(Text)+Height;
        end;
      with Panels[2] do begin
        if FileAge(FFilename,dt) then s:=DateTimeToStr(dt) else s:='<unknown>';
        Text:='Date: '+s;
        Width:=Canvas.TextWidth(Text)+Height;
        end;
      Panels[3].Text:='Size: '+GroupDigits(IntToStr(FFileSize))+' byte';
      end;
//    else Text:=Format('File not found: %s',[AFileName]);
    if Count=0 then Exit;
    NumDigits:=trunc(1+log10(Count));
    if NumDigits<2 then NumDigits:=2;
    end;
  Result:=true;
  memNumbers.Width:=NumDigits*10; //GetTextWidth(Format('%.*d',[n,0]),frmMain.memText.Font);
  with memNumbers.Lines do begin
    s:='';    // faster than "Add"
    for i:=1 to memText.Lines.Count do s:=s+Format('%.*d',[NumDigits,i])+sLineBreak;
    Text:=s;
    end;
  memText.SelStart:=0;
  memText.SetFocus;
  FOptions:=[frDown];
  end;

procedure TFrmMain.ReLoadText (const AFileName : string);
var
  fs : TFileStream;
  enc : TEncoding;
  np : integer;
  scrollInfo : TScrollInfo;
begin
  if FileExists(AFileName) and OpenStream(AFileName,fs) then begin
    with memText do begin
      with scrollInfo do begin
        cbSize:=SizeOf(scrollInfo);
        fMask:=SIF_POS;
        end;
      np:=SelStart;
      GetScrollInfo(Handle,SB_VERT,scrollInfo);
      end;
    try
      if CheckForText(fs,enc) then begin
        LoadText(fs,enc);
        with memText do begin
          if Perform(EM_LINEFROMCHAR,np,0)>=Lines.Count then begin
            SelStart:=Perform(EM_LINEINDEX,Lines.Count-1,0);
            Perform(WM_VSCROLL,SB_BOTTOM,0);
            end
          else begin
            SelStart:=np;
            Perform(WM_VSCROLL,MAKEWPARAM(SB_THUMBPOSITION,ScrollInfo.nPos),0);
            end;
          end;
        end;
    finally
      fs.Free;
      end;
    end;
  end;

procedure TFrmMain.sbPropertiesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with sbProperties do if x<Panels[0].Width then
    LLSettingsDialog.Execute(MaxSize,IncludeExt,UseInclude);
  end;

{ ------------------------------------------------------------------- }
class function TfrmMain.PluginShow(AParentWin: HWND; const AFileName: string): HWND;
var
  FrmMain: TFrmMain;
  r  : TRect;
  fs : TFileStream;
  sz : int64;
  enc : TEncoding;
begin
  Result:=0;
  if CheckFile(AFileName,sz) and OpenStream(AFileName,fs) then begin
    try
      if CheckForText(fs,enc) then begin
        try
          frmMain:=TfrmMain.CreateParented(AParentWin);
          Winapi.Windows.GetClientRect(AParentWin,r);
          with frmMain do begin
            ParentWindow:=AParentWin;
            Color:=clMenu;
            Left:=r.Left;
            Top:=r.Top;
            ClientWidth:=r.Width;
            ClientHeight:=r.Height;
            BorderStyle:=bsNone;
            Visible:=true;
            FFilename:=AFilename;
            FFileSize:=sz;
            LoadText(fs,enc);
            FindDialog.FindText:='';
            MemoChange(nil);
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
    finally
      fs.Free;
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
