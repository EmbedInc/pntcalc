{   Reading data from input stream.
}
module pntcalc_read;
define pntcalc_read_file;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Local subroutine CMD_POINT (PTC, RD, STAT)
*
*   Process the POINT command.  The command keyword has just been read.
}
procedure cmd_point (                  {process POINT command}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  name: string_var32_t;                {name of the point being defined}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk (rd, name) then return; {get the point name}
  if not hier_read_eol (rd, stat) then return; {nothing else allowed in this line}
  hier_read_block_start (rd);          {down into POINT command block}

  while hier_read_line (rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (rd,      {which POINT subcommand ?}
      'AT ANGREF ANGLE DISTXY',
      stat) of

1:    begin                            {AT x y [z]}
        end;

2:    begin                            {ANGREF angle}
        end;

3:    begin                            {ANGLE name angle [REF]}
        end;

4:    begin                            {DISTXY name dist}
        end;

      end;                             {end of subcommand cases}
    end;                               {back to get next subcommand}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_READ_FILE (PTC, FNAM, STAT)
*
*   Read data from the file FNAM.  The protocol is described in the PNTCALC_FILE
*   doc file.
}
procedure pntcalc_read_file (          {read input from file}
  in out  ptc: pntcalc_t;              {library use state}
  in      fnam: univ string_var_arg_t; {file name}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  rd: hier_read_t;                     {state for reading hierarchy data from file}
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  abort;

begin
  hier_read_open (                     {init for reading hierarcy data from the file}
    fnam, '',                          {file name and suffixes}
    rd,                                {returned hierarchy reading state}
    stat);
  if sys_error(stat) then return;

  while hier_read_line (rd, stat) do begin {read the top level commands}
    case hier_read_keyw_pick (rd,      {which command ?}
      'POINT',
      stat) of

1:    begin                            {POINT name}
        cmd_point (ptc, rd, stat);
        end;

      end;                             {end of command name cases}
    if sys_error(stat) then goto abort;
    end;                               {back for next top level input line}

abort:                                 {skip to here on error with RD open, STAT all set}
  if sys_error(stat)
    then begin                         {STAT is already indicating an error}
      hier_read_close (rd, stat2);
      end
    else begin                         {no error so far}
      hier_read_close (rd, stat);
      end
    ;
  end;
