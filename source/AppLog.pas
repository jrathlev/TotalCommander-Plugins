unit AppLog;

interface

uses System.SysUtils;

procedure AppLogWrite(const Msg : string; const EMsg : string = '');
procedure AppLogException(const Src : string; E: Exception);

implementation

{ ------------------------------------------------------------------- }
procedure AppLogWrite(const Msg,EMsg : string);
var
  f: System.Text;
  fn: string;
begin
  fn := GetEnvironmentVariable('TEMP')+'\'+'LlError.txt';
  AssignFile(f, fn);
  {$I-}
  Append(f);
  if IOResult<>0 then Rewrite(f);
  Writeln(f, '---');
  Writeln(f, 'Date:   '+DateTimeToStr(Now));
  Writeln(f, Msg);
  if length(EMsg)>0 then Writeln(f, EMsg)
  else Writeln(f, 'Succeeded');
  CloseFile(f);
  {$I+}
  end;

procedure AppLogException(const Src : string; E: Exception);
begin
  AppLogWrite('Source: '+Src,'Exception: '+E.ClassName+', message: '+E.Message);
  end;

end.
