{   Reading data from input stream.
}
module pntcalc_read;
define pntcalc_read_file;
%include 'pntcalc2.ins.pas';
%include 'hier.ins.pas';
{
********************************************************************************
*
*   Local subroutine GET_COOR (RD, COOR, Z, STAT)
*
*   Read a coordinate that can be either 2D (X and Y) or 3D (X, Y, and Z).  The
*   coordinate is returned in COOR.  Z is set to TRUE if a Z component was
*   specified.  If not, Z is set to false and the Z component of COOR is not
*   altered.  COOR is not altered when returning with error.
}
procedure get_coor (                   {get XY or XYZ coordinate}
  in out  rd: hier_read_t;             {hierarchy reading state}
  out     coor: vect_3d_t;             {returned coordinate}
  out     z: boolean;                  {Z coordinate was provided}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  cx, cy, cz: real;                    {coordinate components}

begin
  hier_read_fp (rd, cx, stat);         {get X component}
  if sys_error(stat) then return;

  hier_read_fp (rd, cy, stat);         {get Y component}
  if sys_error(stat) then return;

  z := false;                          {init to Z component not supplied}
  hier_read_fp (rd, cz, stat);         {try to get Z coordinate}
  if sys_error(stat)
    then begin                         {didn't get Z coordinate}
      if not hier_check_noparm (stat) then return; {other than no parameter error ?}
      end
    else begin                         {got Z coordinate}
      z := true;                       {indicate Z coordinate was supplied}
      end
    ;

  coor.x := cx;                        {return the result}
  coor.y := cy;
  if z then begin
    coor.z := cz;
    end;
  end;
{
********************************************************************************
*
*   Local subroutine CMD_POINT_AT (PTC, RD, PNT, STAT)
*
*   Process a POINT > AT command.  PNT is the point indicated by the POINT
*   command.  The keyword of the AT command has just been read.
}
procedure cmd_point_at (               {process command POINT > AT}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  pnt: pntcalc_point_t;        {the point being modified}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  using_z: boolean;                    {Z component of coordinate is in use}

begin
  if pntcalc_pntflg_coor_k in pnt.flags then begin {abs coor already set ?}
    sys_stat_set (pntcalc_subsys_k, pntcalc_stat_prevcoor_k, stat);
    hier_err_line_file (rd, stat);
    return;
    end;
  if pntcalc_pntflg_xy_k in pnt.flags then begin {XY coor already set ?}
    sys_stat_set (pntcalc_subsys_k, pntcalc_stat_prevxy_k, stat);
    hier_err_line_file (rd, stat);
    return;
    end;

  get_coor (rd, pnt.coor, using_z, stat); {get the 2D or 3D coordinate}
  if sys_error(stat) then return;

  if not hier_read_eol (rd, stat) then return; {verify end of command line}

  pnt.flags := pnt.flags + [pntcalc_pntflg_xy_k];
  if using_z then begin                {Z component was supplied ?}
    pnt.flags := pnt.flags + [pntcalc_pntflg_coor_k];
    end;
  end;
{
********************************************************************************
*
*   Local subroutine CMD_POINT_NEAR (PTC, RD, PNT, STAT)
*
*   Process a POINT > NEAR command.  PNT is the point indicated by the POINT
*   command.  The keyword of the NEAR command has just been read.
}
procedure cmd_point_near (             {process command POINT > NEAR}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  pnt: pntcalc_point_t;        {the point being modified}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  using_z: boolean;                    {Z component of coordinate is in use}

begin
  get_coor (rd, pnt.near, using_z, stat); {get the 2D or 3D coordinate}
  if sys_error(stat) then return;

  if not hier_read_eol (rd, stat) then return; {verify end of command line}

  pnt.flags := pnt.flags + [pntcalc_pntflg_nearxy_k];
  if using_z
    then begin                         {full XYZ was given}
      pnt.flags := pnt.flags + [pntcalc_pntflg_nearxyz_k];
      end
    else begin                         {only XY was given}
      pnt.flags := pnt.flags - [pntcalc_pntflg_nearxyz_k];
      end
    ;
  end;
{
********************************************************************************
*
*   Local subroutine CMD_POINT_ANGREF (PTC, RD, PNT, STAT)
*
*   Process a POINT > ANGREF command.  PNT is the point indicated by the POINT
*   command.  The keyword of the ANGREF command has just been read.
}
procedure cmd_point_angref (           {process command POINT > ANGREF}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  pnt: pntcalc_point_t;        {the point being modified}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  ang: real;                           {angle, radians}

begin
  if pntcalc_pntflg_ang0_k in pnt.flags then begin {ref angle already set ?}
    sys_stat_set (pntcalc_subsys_k, pntcalc_stat_prevrefa_k, stat);
    hier_err_line_file (rd, stat);
    return;
    end;

  hier_read_angle (rd, ang, stat);     {get the angle into ANG}
  if sys_error(stat) then return;
  if not hier_read_eol (rd, stat) then return; {extra tokens on command line ?}

  pnt.ang0 := ang;                     {set the zero reference angle for this point}
  pnt.flags := pnt.flags + [pntcalc_pntflg_ang0_k];
  end;
{
********************************************************************************
*
*   Local subroutine CMD_POINT_ANGLE (PTC, RD, PNT, STAT)
*
*   Process a POINT > ANGLE command.  PNT is the point indicated by the POINT
*   command.  The keyword of the ANGLE command has just been read.  The command
*   syntax is:
*
*     ANGLE name angle [REF]
}
procedure cmd_point_angle (            {process command POINT > ANGLE}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  pnt: pntcalc_point_t;        {the point being modified}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  ang: real;                           {angle measurement, radians}
  name: string_var32_t;                {name of point angle is measured to}
  ref: boolean;                        {use this measurement to determine reference angle}
  rpnt_p: pntcalc_point_p_t;           {pointer to remote point angle measured to}

begin
  name.max := size_char(name.str);     {init local var string}
{
*   Read the command.
}
  if not hier_read_tk_req (rd, name, stat) {get the remote point name into NAME}
    then return;

  hier_read_angle (rd, ang, stat);     {get the angle measurement into ANG}
  if sys_error(stat) then return;

  ref := false;                        {init to not use this measurement for ref angle}
  case hier_read_keyw_pick (rd, 'REF', stat) of {which optional keyword ?}
-1: ;                                  {no keyword, not an error}
1:  begin                              {REF}
      ref := true;
      end;
otherwise                              {bad keyword}
    return;                            {return with error, STAT already set}
    end;

  if not hier_read_eol (rd, stat) then return; {nothing more allowed on command line}
{
*   Process the command.  The variables NAME, ANGLE, and REF are set.
}
  pntcalc_pnt_get (ptc, name, rpnt_p); {get pointer to the remote point}
  pntcalc_meas_add_ang (ptc, pnt, rpnt_p^, ang, ref); {log the measurements}
  end;
{
********************************************************************************
*
*   Local subroutine CMD_POINT_DISTXY (PTC, RD, PNT, STAT)
*
*   Process a POINT > DISTXY command.  PNT is the point indicated by the POINT
*   command.  The keyword of the DISTXY command has just been read.  The command
*   syntax is:
*
*     DISTXY name dist
}
procedure cmd_point_distxy (           {process command POINT > DISTXY}
  in out  ptc: pntcalc_t;              {library use state}
  in out  rd: hier_read_t;             {hierarchy reading state}
  in out  pnt: pntcalc_point_t;        {the point being modified}
  in out  stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  name: string_var32_t;                {name of point angle is measured to}
  dist: real;                          {the measured distance}
  rpnt_p: pntcalc_point_p_t;           {pointer to remote point angle measured to}

begin
  name.max := size_char(name.str);     {init local var string}
{
*   Read the command.
}
  if not hier_read_tk_req (rd, name, stat) {get the remote point name into NAME}
    then return;

  hier_read_fp (rd, dist, stat);       {get the distance to the remote point}
  if sys_error(stat) then return;

  if not hier_read_eol (rd, stat) then return; {nothing more allowed on command line}
{
*   Process the command.  The variables NAME and DIST are all set.
}
  pntcalc_pnt_get (ptc, name, rpnt_p); {get pointer to the remote point}

  pntcalc_meas_add_distxy (ptc, pnt, rpnt_p^, dist, stat);
  if sys_error(stat) then begin        {error adding distance measurement ?}
    hier_err_line_file (rd, stat);     {add line number and file name}
    end;
  end;
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
  pnt_p: pntcalc_point_p_t;            {pointer to the point being modified}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (rd, name, stat) then return; {get the point name}
  if not hier_read_eol (rd, stat) then return; {nothing else allowed in this line}
  pntcalc_pnt_get (ptc, name, pnt_p);  {get pointer to the point being modified}

  hier_read_block_start (rd);          {down into POINT command block}
  while hier_read_line (rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (rd,      {which POINT subcommand ?}
      'AT NEAR ANGREF ANGLE DISTXY',
      stat) of

1:    begin                            {AT x y [z]}
        cmd_point_at (ptc, rd, pnt_p^, stat);
        end;

2:    begin                            {NEAR x y [z]}
        cmd_point_near (ptc, rd, pnt_p^, stat);
        end;

3:    begin                            {ANGREF angle}
        cmd_point_angref (ptc, rd, pnt_p^, stat);
        end;

4:    begin                            {ANGLE name angle [REF]}
        cmd_point_angle (ptc, rd, pnt_p^, stat);
        end;

5:    begin                            {DISTXY name dist}
        cmd_point_distxy (ptc, rd, pnt_p^, stat);
        end;

      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
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
    fnam, '.pnts',                     {file name and suffixes}
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
