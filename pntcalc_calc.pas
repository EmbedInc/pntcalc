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
}
procedure resolve_ang0 (               {try to resolve 0 reference angle}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to attempt to update}
  val_param; internal;

begin
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

  if not (pntcalc_pntflg_ang0_k in pnt.flags) {ref angle not resolved yet ?}
      then begin
    resolve_ang0 (ptc, pnt);           {try to resolve it}
    end;

  if not (pntcalc_pntflg_xy_k in pnt.flags) {XY location not resolved yet ?}
      then begin
    resolve_xy (ptc, pnt);             {try to resolve it}
    end;

  if pnt.flags = flgold then return;   {no changes were made ?}
  pntcalc_calc_point := true;          {indicate changes were made}

  if pntcalc_gflg_showcalc_k in ptc.flags then begin {show calculation progress ?}
    flgold := pnt.flags - flgold;      {set of flags that were added}
    write ('  Point "', pnt.name.str:pnt.name.len, '"');
    if pntcalc_pntflg_xy_k in flgold then begin
      write (' XY');
      end;
    if pntcalc_pntflg_ang0_k in flgold then begin
      write (' ANG0');
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
