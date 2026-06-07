(* Delphi Unit
   LineLister goto line dialog
   ===========================

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

unit ListGotoDlg;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

type
  TListGotoDialog = class(TForm)
    Label1: TLabel;
    OKBtn: TButton;
    CancelBtn: TButton;
    edNumber: TEdit;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen }
    FMax : integer;
  public
    { Public-Deklarationen }
    function Execute (MaxLines : integer; var LineNr : integer) : boolean;
  end;

implementation

{$R *.dfm}

uses MsgDialogs;

procedure TListGotoDialog.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  n : integer;
begin
  if (ModalResult=mrOK) then begin
    if TryStrToInt(edNumber.Text,n) then begin
      if (n<=0) or (n>FMax) then begin
        ErrorDialog(Format('The valid range is between 1 and %u',[FMax]));
        CanClose:=false;
        end;
      end
    else begin
      ErrorDialog('Invalid number');
      CanClose:=false;
      end;
    if not CanClose then with edNumber do begin
      SelectAll; SetFocus;
      end;
    end;
  end;

procedure TListGotoDialog.FormShow(Sender: TObject);
var
  R : TRect;
begin
  GetWindowRect(Screen.ActiveForm.Handle, R);
  Left := R.Left + ((R.Right - R.Left) div 2) - (Width div 2);
  Top := R.Top + ((R.Bottom - R.Top) div 2) - (Height div 2);
  end;

function TListGotoDialog.Execute (MaxLines : integer; var LineNr : integer) : boolean;
begin
  ActiveControl:=edNumber;
  with edNumber do begin
    Text:=IntToStr(LineNr);
    SelectAll;
    end;
  FMax:=MaxLines;
  Result:=ShowModal=mrOk;
  if Result then LineNr:=StrToInt(edNumber.Text);
  end;

end.
