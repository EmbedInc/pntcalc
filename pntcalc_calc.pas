{   Calculate point values from measurements.
}
module pntcalc_calc;
define pntcalc_calc_point;
define pntcalc_calc_points;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Local subroutine RESOLVE_ANG0 (PTC, PNT)
*
*   Try to resolve the 0 reference angle for point PNT.
*
*   Algorithm
*
*     Deriving a reference angle requires:
*
*       1 - The XY coordinate of this point to be known.
*
*       2 - A ANGT measurement with REF flag set, to a point with its XY
*           coordinate known.
}
procedure resolve_ang0 (               {try to resolve 0 reference angle}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to attempt to update}
  val_param; internal;

var
  meas_p: pntcalc_meas_p_t;            {pointer to current measurement}
  dx, dy: real;
  ang: real;

label
  next_meas, make_ref;

begin
  if not (pntcalc_pntflg_xy_k in pnt.flags) {XY of this point not known ?}
    then return;

  meas_p := pnt.meas_p;                {init to first measurement in list}
  while meas_p <> nil do begin         {scan the list of measurements}
    if meas_p^.measty <> pntcalc_measty_angt_k {not angle to other point ?}
      then goto next_meas;
    if not meas_p^.angt_ref            {not an angle reference measurement ?}
      then goto next_meas;
    if not (pntcalc_pntflg_xy_k in meas_p^.angt_pnt_p^.flags)
      then goto next_meas;             {other point XY not known ?}
    goto make_ref;                     {this meas works, go make ref angle}
next_meas:                             {go on to next measurement in the list}
    meas_p := meas_p^.next_p;          {to next measurement for this point}
    end;                               {back to check out this new measurement}
  return;                              {didn't find a suitable measurement}
{
*   MEAS_P points to a reference angle measurement.  This XY coordinates of this
*   point and the remote point are known.  Now compute the absolute 0 reference
*   angle.
}
make_ref:
  dx := meas_p^.angt_pnt_p^.coor.x - pnt.coor.x; {make delta to remote point}
  dy := meas_p^.angt_pnt_p^.coor.y - pnt.coor.y;
  ang := arctan2 (dy, dx);             {make the angle to the remote point}
  pnt.ang0 := ang + meas_p^.angt_ang;  {set the reference angle for this point}
  pnt.flags := pnt.flags + [pntcalc_pntflg_ang0_k]; {indicate ref angle set}
  end;
{
********************************************************************************
*
*   Local subroutine RESOLVE_XY (PTC, PNT)
*
*   Try to resolve the XY absolute position of point PNT.
}
procedure resolve_xy (                 {try to resolve XY position}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to attempt to update}
  val_param; internal;

begin
  end;
{
********************************************************************************
*
*   Function PNTCALC_CALC_POINT (PTC, PNT)
*
*   Attempt to resolve values for the point PNT that can be calculated from the
*   measurements.  The funtion returns TRUE iff any changes are made to the
*   point.
}
function pntcalc_calc_point (          {attempt to calculate absolute values for a point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t)        {the point to attempt to update}
  :boolean;                            {changes were made}
  val_param;

var
  flgold: pntcalc_pntflg_t;            {flags before attempts to resolve values}

begin
  pntcalc_calc_point := false;         {init to no change made}
  flgold := pnt.flags;                 {save flags before attempts to resolve}

  if not (pntcalc_pntflg_xy_k in pnt.flags) {XY location not resolved yet ?}
      then begin
    resolve_xy (ptc, pnt);             {try to resolve it}
    end;

  if not (pntcalc_pntflg_ang0_k in pnt.flags) {ref angle not resolved yet ?}
      then begin
    resolve_ang0 (ptc, pnt);           {try to resolve it}
    end;

  if pnt.flags = flgold then return;   {no changes were made ?}
  pntcalc_calc_point := true;          {indicate changes were made}

  if pntcalc_gflg_showcalc_k in ptc.flags then begin {show calculation progress ?}
    flgold := pnt.flags - flgold;      {set of flags that were added}
    write ('  Point "', pnt.name.str:pnt.name.len, '"');
    if pntcalc_pntflg_xy_k in flgold then begin
      write (' AT ');
      pntcalc_show_coor (pnt.coor, pntcalc_pntflg_coor_k in pnt.flags);
      end;
    if pntcalc_pntflg_ang0_k in flgold then begin
      write (' ANG0 ', (pnt.ang0 * math_rad_deg):7:2);
      end;
    writeln;
    end;
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_CALC_POINTS (PTC, STAT)
*
*   Calculate absolute point values from the measurements to the extent
*   possible.
}
procedure pntcalc_calc_points (        {attempt to calculate absolute values for all points}
  in out  ptc: pntcalc_t;              {library use state}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  pnt_p: pntcalc_point_p_t;            {pointer to the current point}
  niter: sys_int_machine_t;            {1-N number of current iteration}
  changed: boolean;                    {something was changed this pass}

begin
  sys_error_none (stat);               {init to no error}

  niter := 0;                          {init iteration number}
  while true do begin                  {back here each new iteration}
    niter := niter + 1;                {make the 1-N number of this iteration}
    if pntcalc_gflg_showcalc_k in ptc.flags then begin {show calculations ?}
      writeln ('Iteration ', niter);
      end;
    changed := false;                  {init to nothing changed this iteration}

    pnt_p := ptc.pnt_p;                {init to first point in the list}
    while pnt_p <> nil do begin        {scan the list of points}
      changed := changed or            {try to calculate parameters for this point}
        pntcalc_calc_point (ptc, pnt_p^);
      pnt_p := pnt_p^.next_p;          {to next point in the list}
      end;                             {back to do this new point}

    if not changed then exit;          {no change, done all that is possible ?}
    end;                               {back for another iteration}
  end;
