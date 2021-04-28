{   Program SURVEY_SL
*
*   Write SLIDE program .INS.SL file with the point locations resulting from a
*   .PNTS input file.
}
program survey_sl;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'vect.ins.pas';
%include 'pntcalc.ins.pas';
%include 'builddate.ins.pas';

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

var
  fnam_in,                             {input file name}
  fnam_out:                            {output file name}
    %include '(cog)lib/string_treename.ins.pas';
  iname_set: boolean;                  {TRUE if the input file name already set}
  oname_set: boolean;                  {TRUE if the output file name already set}
  conn: file_conn_t;                   {connection to the output file}
  ptc: pntcalc_t;                      {PNTCALC library use state}
  pnt_p: pntcalc_point_p_t;            {pointer to the current data point}
  obuf:                                {one line output buffer}
    %include '(cog)lib/string132.ins.pas';

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, parm_bad, done_opts, next_pnt;
{
********************************************************************************
*
*   Start of main routine.
}
begin
{
*   Initialize before reading the command line.
}
  string_cmline_init;                  {init for reading the command line}
  iname_set := false;                  {no input file name specified}
  oname_set := false;                  {no output file name specified}
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  if (opt.len >= 1) and (opt.str[1] <> '-') then begin {implicit pathname token ?}
    if not iname_set then begin        {input file name not set yet ?}
      string_copy (opt, fnam_in);      {set input file name}
      iname_set := true;               {input file name is now set}
      goto next_opt;
      end;
    if not oname_set then begin        {output file name not set yet ?}
      string_copy (opt, fnam_out);     {set output file name}
      oname_set := true;               {output file name is now set}
      goto next_opt;
      end;
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_conflict', msg_parm, 1);
    end;
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-IN -OUT',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -IN filename
}
1: begin
  if iname_set then begin              {input file name already set ?}
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_conflict', msg_parm, 1);
    end;
  string_cmline_token (opt, stat);
  string_copy (opt, fnam_in);
  iname_set := true;
  end;
{
*   -OUT filename
}
2: begin
  if oname_set then begin              {output file name already set ?}
    sys_msg_parm_vstr (msg_parm[1], opt);
    sys_message_bomb ('string', 'cmline_opt_conflict', msg_parm, 1);
    end;
  string_cmline_token (opt, stat);
  string_copy (opt, fnam_out);
  oname_set := true;
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}

  if not iname_set then begin
    sys_message_bomb ('string', 'cmline_input_fnam_missing', nil, 0);
    end;

  if not oname_set then begin          {output file name not set, make default ?}
    string_generic_fnam (fnam_in, '.pnts', fnam_out); {generic leafname of input}
    end;
{
*   Get and process the input data.
}
  pntcalc_lib_new (util_top_mem_context, ptc, stat); {open the PNTCALC library}
  sys_error_abort (stat, '', '', nil, 0);

  pntcalc_read_file (ptc, fnam_in, stat); {read the data from the input file}
  sys_error_abort (stat, '', '', nil, 0);

  pntcalc_calc_points (ptc, stat);     {resolve computable parameters}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Write the ".ins.sl" output file.
}
  file_open_write_text (               {open the output file}
    fnam_out, '.ins.sl',               {file name and mandatory suffix}
    conn,                              {returned connection to the file}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  pnt_p := ptc.pnt_p;                  {init to first pointer in the list}
  while pnt_p <> nil do begin          {scan the list of data points}
    if not (pntcalc_pntflg_xy_k in pnt_p^.flags) {XY of this point not known ?}
      then goto next_pnt;
    string_vstring (obuf, 'var new '(0), -1); {init output line with fixed part}
    string_append (obuf, pnt_p^.name); {point name becomes variable name}
    string_appends (obuf, ' Coor2d '); {variable's data type}
    string_f_fp_free (parm, pnt_p^.coor.x, 6); {make X string}
    string_append (obuf, parm);
    string_append1 (obuf, ' ');
    string_f_fp_free (parm, pnt_p^.coor.y, 6); {make Y string}
    string_append (obuf, parm);
    file_write_text (                  {write output line to output file}
      obuf,                            {line to write}
      conn,                            {connection to the file}
      stat);
    sys_error_abort (stat, '', '', nil, 0);
next_pnt:                              {done with this point, on to next}
    pnt_p := pnt_p^.next_p;            {advance to next point in the list}
    end;                               {back to process this new point}

  file_close (conn);                   {close the output file}
{
*   Clean up and leave.
}
  pntcalc_lib_end (ptc, stat);
  sys_error_abort (stat, '', '', nil, 0);
  end.
