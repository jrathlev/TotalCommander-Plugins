(* Delphi Unit
   LineLister search dialog
   ========================

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

unit ListFindDlg;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.Dialogs;

{
Find text:          Suchen nach:
Whole words only    nur ganze Wörter
Case sensitive      Groß-/&Kleinschreibung
Search backwards    Rückwärts suchen
}
type
  TListFindDialog = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Label1: TLabel;
    cbWhole: TCheckBox;
    cbBackwards: TCheckBox;
    cbCaseSensitive: TCheckBox;
    edFindText: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen }
    FIniName : string;
  public
    { Public-Deklarationen }
    procedure LoadHistory (const AIniName : string);
    procedure SaveHistory;
    procedure AddToHistory (History : TStrings; const hs : string; MaxCount : integer);
    function Execute (var SearchString : string; var SearchOptions : TFindOptions) : boolean;
  end;

implementation

{$R *.dfm}

uses System.IniFiles;

const
  IniSect = 'Find';
  iniHist = 'History';

procedure TListFindDialog.FormCreate(Sender: TObject);
begin
  FIniName:='';
  end;

procedure TListFindDialog.FormShow(Sender: TObject);
var
  R : TRect;
begin
  GetWindowRect(Screen.ActiveForm.Handle, R);
  Left := R.Left + ((R.Right - R.Left) div 2) - (Width div 2);
  Top := R.Top + ((R.Bottom - R.Top) div 2) - (Height div 2);
  end;

procedure TListFindDialog.LoadHistory (const AIniName : string);
var
  i : integer;
  s : string;
begin
  FIniName:=AIniName;
  if FileExists(AIniName) then with TMemIniFile.Create(AIniName) do begin
    edFindText.Clear;
    if SectionExists(IniSect) then begin
      for i:=1 to edFindText.DropDownCount do begin
        s:=ReadString(IniSect,IniHist+IntToStr(i),'');
        if length(s)>0 then edFindText.Items.Add(s);
        end;
      end;
    with edFindText do begin
      if Items.Count>0 then ItemIndex:=0;
//      if (Items.Count<=1) then Style:=csSimple else Style:=csDropDown;
      end;
    Free;
    end;
  end;

procedure TListFindDialog.SaveHistory; // (const IniName : string);
var
  i,n : integer;
  s : string;
  sl : TStringList;
begin
  if length(FIniName)>0 then with TMemIniFile.Create(FIniName) do begin
    sl:=TStringList.Create;
    for i:=1 to edFindText.DropDownCount do begin
      s:=ReadString(IniSect,IniHist+IntToStr(i),'');
      if length(s)>0 then sl.Add(s);   // read saved values
      end;
    EraseSection (IniSect);
    with edFindText do for i:=Items.Count downto 1 do begin  // merge with new values
      AddToHistory (sl,Items[i-1],DropDownCount);
      end;
    n:=sl.Count;
    with edFindText do if n>DropDownCount then n:=DropDownCount;
    for i:=1 to n do begin
      WriteString(IniSect,IniHist+IntToStr(i),sl[i-1]);
      end;
    sl.Free;
    UpdateFile;
    Free;
    end;
  end;

procedure TListFindDialog.AddToHistory (History : TStrings; const hs : string; MaxCount : integer);
var
  n : integer;
begin
  if length(hs)>0 then with History do begin
    n:=IndexOf(hs);
    if n<0 then begin
      if Count>=MaxCount then Delete(Count-1);
      Insert (0,hs);
      end
    else begin
      if n>0 then Move (n,0);
      Strings[0]:=hs;  // update string anyway, e.g. if case was changed
      end;
    end;
  end;

function TListFindDialog.Execute (var SearchString : string; var SearchOptions : TFindOptions) : boolean;
begin
  cbWhole.Checked:=frWholeWord in SearchOptions;
  cbCaseSensitive.Checked:=frMatchCase in SearchOptions;
  ActiveControl:=edFindText;
  cbBackwards.Checked:=not (frDown in SearchOptions);
  with edFindText do begin
//    if (Items.Count>1) then Style:=csDropDown else Style:=csSimple;
    Text:=SearchString;
    SelectAll;
    end;
  Result:=ShowModal=mrOK;
  if Result then begin
    SearchOptions:=[];
    if cbWhole.Checked then include(SearchOptions,frWholeWord);
    if cbCaseSensitive.Checked then include(SearchOptions,frMatchCase);
    if not cbBackwards.Checked then include(SearchOptions,frDown);
    SearchString:=edFindText.Text;
    AddToHistory (edFindText.Items,SearchString,edFindText.DropDownCount);
    end;
  end;

end.
