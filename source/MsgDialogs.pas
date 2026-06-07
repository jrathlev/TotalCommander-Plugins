(* Delphi-Unit
   Message Dialogs
   ===============
   Uses library function "CreateMessageDialog" from "Vcl.Dialogs"
   The messages are not accessible to screenreaders (use "ShowMessageDlg" instead)

   Note: Parameter "Msg" can hold a title string separated by "|"

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   July 2022
   last modified: May 2026
   *)
(* @abstract(Message Dialogs (Info, Error, Confirm))
   @author(© Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de))
   @created(July 2022)
   @lastmod(May 2026)
*)

unit MsgDialogs;

interface

uses System.SysUtils, System.Types, Vcl.Forms, Vcl.Dialogs;

{ ---------------------------------------------------------------- }
const
  VertBar = '|';

  CenterPos : TPoint = (X : -1; Y : -1);   // main form center
  ScreenPos : TPoint = (X : -1; Y : 0);    // screen center

{ ---------------------------------------------------------------- }
// MessageDlg in Bildschirmmitte (X<0) oder an Position X,Y
function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
                       Buttons: TMsgDlgButtons; DefaultButton : TMsgDlgBtn;
                       Pos : TPoint; Delay : integer;
                       AMonitor : TDefaultMonitor = dmActiveForm) : integer; overload;
function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
                       Buttons: TMsgDlgButtons;
                       const Pos : TPoint; Delay : integer;
                       AMonitor : TDefaultMonitor = dmActiveForm) : integer; overload;
function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
                       Buttons: TMsgDlgButtons) : integer; overload;
function MessageDialog(const Msg: string; DlgType: TMsgDlgType;
                       Buttons: TMsgDlgButtons) : integer; overload;
function MessageDialog(const Pos : TPoint; const Msg: string; DlgType: TMsgDlgType;
                       Buttons: TMsgDlgButtons) : integer;  overload;

function ConfirmDialog (const Title,Msg : string;
                        AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;
function ConfirmDialog (const Msg : string; DefaultButton : TMsgDlgBtn = mbYes;
                        AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;
function ConfirmDialog (const Pos : TPoint; const Msg : string; DefaultButton : TMsgDlgBtn = mbYes;
                        AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;
function ConfirmDialog (const Pos : TPoint; const Title,Msg : string;
                        AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;
function ConfirmDialog (const Pos : TPoint; const Title,Msg : string; DefaultButton : TMsgDlgBtn;
                        AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;

function ConfirmRetryDialog (const Msg : string) : boolean; overload;
function ConfirmRetryDialog (const Pos : TPoint; const Msg : string; DefaultButton : TMsgDlgBtn = mbRetry;
                       AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;


procedure InfoDialog (const Title,Msg : string; Delay : integer;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure InfoDialog (const Title,Msg : string;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure InfoDialog (const Msg : string; Delay : integer;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure InfoDialog (const Msg : string;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure InfoDialog (const Pos : TPoint; const Title,Msg : string;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure InfoDialog (const Pos : TPoint; const Msg : string;
                      AMonitor : TDefaultMonitor = dmActiveForm); overload;

procedure ErrorDialog (const Title,Msg : string; x,y : integer;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Title,Msg : string; Delay : integer;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Msg : string; Delay : integer;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Title,Msg : string;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Msg : string;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Pos : TPoint; const Title,Msg : string;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;
procedure ErrorDialog (const Pos : TPoint; const Msg : string;
                       AMonitor : TDefaultMonitor = dmActiveForm); overload;


implementation

uses Winapi.Windows, Vcl.Controls;//, WinUtils, StringUtils;

{ ---------------------------------------------------------------- }
// check if window fits to screen
procedure CheckScreenBounds (AScreen        : TScreen;
                             var ALeft,ATop : integer;
                             AWidth,AHeight : integer);
var
  mo : TMonitor;
begin
  with AScreen do begin
    mo:=MonitorFromPoint(Point(ALeft,ATop));
//    mo:=MonitorFromRect(Rect(ALeft,ATop,ALeft+AWidth,ATop+AHeight));
    with mo.WorkareaRect do begin
      if ALeft+AWidth>Right then ALeft:=Right-AWidth-20;
      if ALeft<Left then ALeft:=Left+20;
      if ATop+AHeight>Bottom then ATop:=Bottom-AHeight-30;
      if ATop<Top then ATop:=Top+20;
      end;
    end;
  end;

{ ---------------------------------------------------------------- }
// neuer Message-Dialog mit Positionsprüfung
// Delay = 0: ShowModal
//       > 0: Anzeigen und automatisch schließen nach "Delay" in s
function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
                Buttons: TMsgDlgButtons; DefaultButton : TMsgDlgBtn;
                Pos : TPoint; Delay : integer;
                AMonitor : TDefaultMonitor = dmActiveForm) : integer;
var
  w,n : integer;
  st,sm : string;
  R : TRect;
begin
  n:=System.pos(VertBar,Msg);
  if n>0 then begin
    st:=copy(Msg,1,n-1); sm:=copy(Msg,n+1,length(Msg));
    end
  else begin
    sm:=Msg; st:='';
    end;
  if not Title.IsEmpty then st:=Title;
  with CreateMessageDialog(sm,DlgType,Buttons,DefaultButton) do begin
    Scaled:=true;
    DefaultMonitor:=AMonitor;
    try
      with Pos do begin
        if Pos=ScreenPos then Position:=poScreenCenter
        else if Pos=CenterPos then begin //Position:=poOwnerFormCenter
          GetWindowRect(Screen.ActiveForm.Handle, R);
          Left := R.Left + ((R.Right - R.Left) div 2) - (Width div 2);
          Top := R.Top + ((R.Bottom - R.Top) div 2) - (Height div 2);
          end
        else begin
          CheckScreenBounds(Screen,x,y,Width,Height);
          Left:=x; Top:=y;
          end;
        end;
      if length(st)>0 then begin
        Caption:=st;
        w:=Canvas.TextWidth(st)+50;
        if w>ClientWidth then ClientWidth:=w;
        end;
      FormStyle:=fsStayOnTop;
      if Delay<=0 then Result:=ShowModal
      else begin
        Show;
        Delay:=Delay*10;
        repeat
          Application.ProcessMessages;
          Sleep(100);
          dec(Delay);
          until (Delay=0) or (ModalResult<>mrNone);
        if ModalResult=mrNone then begin
          Close;
          Result:=mrOK;
          end
        else Result:=ModalResult;
        end;
    finally
      Free;
      end;
    end;
  end;

function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
                Buttons: TMsgDlgButtons;
                const Pos : TPoint; Delay : integer;
                AMonitor : TDefaultMonitor = dmActiveForm) : integer;
var
  DefaultButton: TMsgDlgBtn;
begin
  if mbOk in Buttons then DefaultButton := mbOk else
    if mbYes in Buttons then DefaultButton := mbYes else
      DefaultButton := mbRetry;
  Result:=MessageDialog(Title,Msg,DlgType,Buttons,DefaultButton,Pos,Delay,AMonitor);
end;

function MessageDialog(const Title,Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons) : integer;
begin
  Result:=MessageDialog(Title,Msg,DlgType,Buttons,CenterPos,0);
  end;

function MessageDialog(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons) : integer;
begin
  Result:=MessageDialog('',Msg,DlgType,Buttons,CenterPos,0);
  end;

function MessageDialog (const Pos : TPoint; const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons) : integer;
begin
  Result:=MessageDialog('',Msg,DlgType,Buttons,Pos,0);
  end;

{ ---------------------------------------------------------------- }
// Bestätigung in Bildschirmmitte (X<0) oder an Position X,Y
function ConfirmDialog (const Pos : TPoint; const Title,Msg : string;
                        AMonitor : TDefaultMonitor) : boolean;
begin
  Result:=MessageDialog (Title,Msg,mtConfirmation,[mbYes,mbNo],Pos,0,AMonitor)=mrYes;
  end;

// Bestätigung auf einstellbarem Monitor
function ConfirmDialog (const Pos : TPoint; const Msg : string; DefaultButton : TMsgDlgBtn;
                        AMonitor : TDefaultMonitor) : boolean;
begin
  Result:=MessageDialog ('',Msg,mtConfirmation,[mbYes,mbNo],DefaultButton,Pos,0,AMonitor)=mrYes;
  end;

function ConfirmDialog (const Pos : TPoint; const Title,Msg : string; DefaultButton : TMsgDlgBtn;
                        AMonitor : TDefaultMonitor) : boolean;
begin
  Result:=MessageDialog (Title,Msg,mtConfirmation,[mbYes,mbNo],DefaultButton,Pos,0,AMonitor)=mrYes;
  end;

// Bestätigung in Bildschirmmitte
function ConfirmDialog (const Title,Msg : string;
                        AMonitor : TDefaultMonitor) : boolean;
begin
  Result:=ConfirmDialog(CenterPos,Title,Msg,AMonitor);
  end;

function ConfirmDialog (const Msg : string; DefaultButton : TMsgDlgBtn;
                        AMonitor : TDefaultMonitor) : boolean;
begin
  Result:=MessageDialog ('',Msg,mtConfirmation,[mbYes,mbNo],DefaultButton,CenterPos,0,AMonitor)=mrYes;
  end;

function ConfirmRetryDialog (const Msg : string) : boolean; overload;
begin
  Result:=ConfirmDialog(CenterPos,Msg);
  end;

function ConfirmRetryDialog (const Pos : TPoint; const Msg : string; DefaultButton : TMsgDlgBtn = mbRetry;
                       AMonitor : TDefaultMonitor = dmActiveForm) : boolean; overload;
begin
  Result:=MessageDialog('',Msg,mtError,[mbRetry,mbCancel],DefaultButton,Pos,0,AMonitor)=mrRetry;
  end;

// Information an Position ausgeben
procedure InfoDialog (const Pos : TPoint; const Title,Msg : string;
                      AMonitor : TDefaultMonitor);
begin
  MessageDialog (Title,Msg,mtInformation,[mbOK],Pos,0,AMonitor);
  end;

procedure InfoDialog (const Pos : TPoint; const Msg : string;
                      AMonitor : TDefaultMonitor);
begin
  InfoDialog(Pos,'',Msg,AMonitor);
  end;

// Information in Bildschirmmitte ausgeben
procedure InfoDialog (const Title,Msg : string;
                      AMonitor : TDefaultMonitor);
begin
  InfoDialog(CenterPos,Title,Msg,AMonitor);
  end;

// Information in Bildschirmmitte ausgeben und für Delay s anzeigen
procedure InfoDialog (const Title,Msg : string; Delay : integer;
                      AMonitor : TDefaultMonitor);
begin
  MessageDialog (Title,Msg,mtInformation,[mbOK],CenterPos,Delay,AMonitor);
  end;

procedure InfoDialog (const Msg : string; Delay : integer;
                      AMonitor : TDefaultMonitor);
begin
  InfoDialog('',Msg,Delay,AMonitor);
  end;

procedure InfoDialog (const Msg :string;
                      AMonitor : TDefaultMonitor);
begin
  InfoDialog(CenterPos,'',Msg,AMonitor);
  end;

// Fehlermeldung an Position ausgeben
procedure ErrorDialog (const Title,Msg : string; x,y : integer;
                       AMonitor : TDefaultMonitor);
begin
  MessageDialog (Title,Msg,mtError,[mbOK],Point(x,y),0,AMonitor);
  end;

procedure ErrorDialog (const Pos : TPoint; const Title,Msg : string;
                       AMonitor : TDefaultMonitor);
begin
  MessageDialog (Title,Msg,mtError,[mbOK],Pos,0,AMonitor);
  end;

procedure ErrorDialog (const Pos : TPoint; const Msg : string;
                       AMonitor : TDefaultMonitor);
begin
  ErrorDialog(Pos,'',Msg,AMonitor);
  end;

// Fehlermeldung in Bildschirmmitte ausgeben und für Delay s anzeigen
procedure ErrorDialog (const Title,Msg : string; Delay : integer;
                       AMonitor : TDefaultMonitor);
begin
  MessageDialog (Title,Msg,mtError,[mbOK],CenterPos,Delay,AMonitor);
  end;

procedure ErrorDialog (const Msg : string; Delay : integer;
                       AMonitor : TDefaultMonitor);
begin
  ErrorDialog(CenterPos,'',Msg,AMonitor);
  end;

// Fehlermeldung in Bildschirmmitte ausgeben
procedure ErrorDialog (const Title,Msg : string;
                       AMonitor : TDefaultMonitor);
begin
  ErrorDialog(CenterPos,Title,Msg,AMonitor);
  end;

procedure ErrorDialog (const Msg : string;
                       AMonitor : TDefaultMonitor);
begin
  ErrorDialog(CenterPos,'',Msg,AMonitor);
  end;

end.
