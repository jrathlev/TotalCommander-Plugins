(* Delphi Unit
   Settings dialog for LineLister
   ==============================

   LineLister is a Total Commander Lister plugin

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   May 2026

   last modified: June 2026
   *)

unit ListLineSettings;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls;

const
  VertBar = '|';

type
  TLLSettingsDialog = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Label1: TLabel;
    edFilesize: TEdit;
    paFileSize: TPanel;
    btDelete: TButton;
    paFileTypes: TPanel;
    cbSelected: TCheckBox;
    lbTypes: TListBox;
    Label2: TLabel;
    btAdd: TButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btDeleteClick(Sender: TObject);
    procedure btAddClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    function Execute (var MaxSize: integer; var ExtInclude : string; var UseInclude : boolean) : boolean;
  end;

implementation

{$R *.dfm}

uses Vcl.Dialogs, MsgDialogs;

procedure TLLSettingsDialog.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  n : integer;
begin
  if (ModalResult=mrOK) then begin
    if not TryStrToInt(edFileSize.Text,n) then begin
      ErrorDialog('Invalid number');
      CanClose:=false;
      end;
    if not CanClose then with edFileSize do begin
      SelectAll; SetFocus;
      end;
    end;
  end;

procedure TLLSettingsDialog.FormCreate(Sender: TObject);
begin
  lbTypes.Items.Delimiter:=VertBar;
  end;

procedure TLLSettingsDialog.FormShow(Sender: TObject);
var
  R : TRect;
begin
  GetWindowRect(Screen.ActiveForm.Handle, R);
  Left := R.Left + ((R.Right - R.Left) div 2) - (Width div 2);
  Top := R.Top + ((R.Bottom - R.Top) div 2) - (Height div 2);
  end;

procedure TLLSettingsDialog.btAddClick(Sender: TObject);
var
  s : string;
begin
  s:='';
  if InputQuery('Add file type','File extension:',s) then begin
    lbTypes.Items.Add(s);
    end;
  end;

procedure TLLSettingsDialog.btDeleteClick(Sender: TObject);
var
  n : integer;
begin
  with lbTypes do if ItemIndex>=0 then begin
    n:=ItemIndex;
    Items.Delete(n);
    if n>= Count then n:=Count-1;
    ItemIndex:=n;
    end;
  end;

function TLLSettingsDialog.Execute (var MaxSize: integer; var ExtInclude : string;
                                    var UseInclude : boolean) : boolean;
const
  MB = 1024*1024;
begin
  edFilesize.Text:=IntToStr(MaxSize div MB);
  cbSelected.Checked:=UseInclude;
  lbTypes.Items.DelimitedText:=ExtInclude;
  if ShowModal=mrOK then begin
    MaxSize:=StrToInt(edFilesize.Text)*MB;
    UseInclude:=cbSelected.Checked;
    ExtInclude:=lbTypes.Items.DelimitedText;
    end;
  end;

end.
