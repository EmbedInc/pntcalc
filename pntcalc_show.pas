{   Showing data structures and other items to standard output.
}
module pntcalc_show;
define pntcalc_show_point;
define pntcalc_show_meas;
define pntcalc_show;
%include 'pntcalc2.ins.pas';

const
  rad_deg = 180.0 / 3.14159265358979323846; {mult factor for radians to degrees}
{
********************************************************************************
*
*   Subroutine PNTCALC_SHOW_POINT (PNT, INDENT, SUB)
*
*   Show the data of the point PNT on standard output.
}
procedure pntcalc_show_point (         {show data of one point to STDOUT}
  in      pnt: pntcalc_point_t;        {the point to show}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  meas_p: pntcalc_meas_p_t;            {pointer to current measurement}
  ind: sys_int_machine_t;              {internal indentation level}
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}

  writeln ('':indent, 'Point "', pnt.name.str:pnt.name.len, '"');
  if not sub then return;

  ind := indent + 2;                   {make indentation one level down}

  if pntcalc_pntflg_nearxy_k in pnt.flags then begin {some part of near point is known ?}
    string_f_fp_free (tk, pnt.near.x, 5);
    write ('':ind, 'near (', tk.str:tk.len);
    string_f_fp_free (tk, pnt.near.y, 5);
    write (', ', tk.str:tk.len);
    if pntcalc_pntflg_nearxyz_k in pnt.flags then begin {Z is also known ?}
      string_f_fp_free (tk, pnt.near.y, 5);
      write (', ', tk.str:tk.len);
      end;
    writeln (')');
    end;

  if pntcalc_pntflg_xy_k in pnt.flags then begin {some part of abs coordinate is known ?}
    string_f_fp_free (tk, pnt.coor.x, 5);
    write ('':ind, 'at (', tk.str:tk.len);
    string_f_fp_free (tk, pnt.coor.y, 5);
    write (', ', tk.str:tk.len);
    if pntcalc_pntflg_coor_k in pnt.flags then begin {Z is also known ?}
      string_f_fp_free (tk, pnt.coor.y, 5);
      write (', ', tk.str:tk.len);
      end;
    writeln (')');
    end;

  if pntcalc_pntflg_ang0_k in pnt.flags then begin {reference angle known ?}
    string_f_fp_free (tk, pnt.ang0 * rad_deg, 5);
    writeln ('':ind, 'Ref ang ', tk.str:tk.len, ' deg');
    end;

  meas_p := pnt.meas_p;                {init to first measurement in list}
  while meas_p <> nil do begin         {back here each new measurement}
    pntcalc_show_meas (meas_p^, ind, sub);
    meas_p := meas_p^.next_p;          {to next measurement in the list}
    end;                               {back to show this new measurement}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_SHOW_MEAS (MEAS, INDENT, SUB)
*
*   Show the data of measurement MEAS on standard output.
}
procedure pntcalc_show_meas (          {show data of one measurement to STDOUT}
  in      meas: pntcalc_meas_t;        {the measurement to show}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  tk: string_var32_t;                  {scratch token}

begin
  tk.max := size_char(tk.str);         {init local var string}
  if meas.measty = pntcalc_measty_none_k then return; {no measurement here ?}

  write ('':indent, 'Measured ');
  case meas.measty of                  {what kind of measurement is this ?}

pntcalc_measty_angt_k: begin           {angle to another point}
      string_f_fp_ftn (tk, meas.angt_ang * rad_deg, 7, 2);
      write (tk.str:tk.len, ' deg to point "',
        meas.angt_pnt_p^.name.str:meas.angt_pnt_p^.name.len, '"');
      if meas.angt_ref then begin
        write (' (ref)');
        end;
      end;

pntcalc_measty_angf_k: begin           {angle to another point}
      string_f_fp_ftn (tk, meas.angf_ang * rad_deg, 7, 2);
      write (tk.str:tk.len, ' deg from point "',
        meas.angf_pnt_p^.name.str:meas.angf_pnt_p^.name.len, '"');
      end;

pntcalc_measty_distxy_k: begin         {XY distance to another point}
      string_f_fp_free (tk, meas.distxy_dist, 5);
      write ('distance ', tk.str:tk.len, ' to point "',
        meas.distxy_pnt_p^.name.str:meas.distxy_pnt_p^.name.len, '"');
      end;

otherwise
    write (' type ', ord(meas.measty));
    end;

  writeln;
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_SHOW (PTC, INDENT)
*
*   Show the data in the library useage state PTC.
}
procedure pntcalc_show (               {show all the data in a lib usage}
  in      ptc: pntcalc_t;              {library use state to show data of}
  in      indent: sys_int_machine_t);  {number of spaces to indent top level lines}
  val_param;

var
  pnt_p: pntcalc_point_p_t;            {pointer to current point}
  n: sys_int_machine_t;                {number of points found}

begin
  n := 0;                              {init number of points found}
  pnt_p := ptc.pnt_p;                  {init to first point in list}
  while pnt_p <> nil do begin          {scan the list of points}
    n := n + 1;                        {count one more point found}
    pntcalc_show_point (pnt_p^, indent, true);
    pnt_p := pnt_p^.next_p;            {to next point in list}
    end;                               {back to show this new point}

  writeln ('':indent, n, ' points found');
  end;
