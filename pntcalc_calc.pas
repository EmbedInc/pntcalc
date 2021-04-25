{   Calculate point values from measurements.
*
*   About angles
*
*     This software is meant to handle surveying data, measured with instruments
*     like transits.  These generally use compass-style angles.  0 degrees is
*     north, straight ahead, or to some reference other angles are relative to.
*     Positive angles are then clockwise from that, when viewed from above.
*
*     In math, 0 is usually in the +X direction, with positive angles
*     counter-clockwise from that when viewed from to +Z axis.  This differs
*     from survey angles by a 90 degree shift in the reference and a sign
*     change.
*
*     This software stores angles as survey angles, in radians.  The constants
*     MATCH_RAD_DEG, and MATH_DEG_RAD are the multiplication factors to convert
*     from radians to degrees, and degrees to radians, respsectively.  The
*     functions MATH_ANGLE_MATH and MATH_ANGLE_SURV can be used to convert
*     between math and survey angles.
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
*   Local subroutine ANGF_PNT_VECT (MEAS, PNT, VECT)
*
*   Compute the starting point and unit vector indicated by the measurement
*   MEAS.  The measurement must of an angle from a point, the 0 reference angle
*   for the point known, and the XY location of that point known.  PNT and VECT
*   are returned the ray indicated by the angle measurement.  PNT is the absolue
*   XY starting coordinate, and VECT the 2D unit vector implied by the angle.
}
procedure angf_pnt_vect (              {compute ray from ANGF measurement}
  in      meas: pntcalc_meas_t;        {ANGF measurement, ANG0 and XY known}
  out     pnt: vect_2d_t;              {2D ray starting point}
  out     vect: vect_2d_t);            {2D ray unit vector}
  val_param; internal;

var
  pnt_p: pntcalc_point_p_t;            {pointer to the point angle measured from}
  ang: real;                           {absolute math angle}

begin
  pnt_p := meas.angf_pnt_p;            {get pointer to the point angle measured from}

  pnt.x := pnt_p^.coor.x;              {return the ray starting point}
  pnt.y := pnt_p^.coor.y;

  ang := math_angle_math (             {make absolute angle, convert to math type}
    meas.angf_ang + pnt_p^.ang0);
  vect.x := cos(ang);                  {make the ray unit vector}
  vect.y := sin(ang);
  end;
{
********************************************************************************
*
*   Local subroutine RESOLVE_XY (PTC, PNT)
*
*   Try to resolve the XY absolute position of point PNT.  There are several
*   cases where the absolute position of the current point (PNT) can be
*   determined:
*
*     1 - Angles are known from two more more points with known location.  When
*         there are more than two points, the two with the angle least co-linear
*         are chosen.
*
*     2 - An angle and distance are known from another point with known
*         location.
*
*     3 - The distance is known from two or more points with known location, and
*         the NEAR location of this point is filled in.
*
*     4 - Three or more angles are available to other points with known
*         position.  This is not implemented yet.
}
procedure resolve_xy (                 {try to resolve XY position}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to attempt to update}
  val_param; internal;

const
  meas_list_max = 8;                   {max measurement we can save in a list}

type
  meas_list_t =                        {list of measurements}
    array [1..meas_list_max] of pntcalc_meas_p_t;

var
  meas_p: pntcalc_meas_p_t;            {pointer to current measurement}
  angf: meas_list_t;                   {list of angles from other known points}
  nangf: sys_int_machine_t;            {number of entries in ANGF list}
  disp: meas_list_t;                   {list of distances to other known points}
  ndisp: sys_int_machine_t;            {number of entries in DISP list}
  pnt_p: pntcalc_point_p_t;            {pointer to a remote point}
  meas1_p, meas2_p: pntcalc_meas_p_t;  {pointers to measurements for resolving location}
  p1, p2: vect_2d_t;                   {scratch XY coordinates}
  v1, v2: vect_2d_t;                   {scratch 2D vectors}
  simul: array[1..2, 1..3] of real;    {coefficients for simultaneous equations}
  smres: array[1..2] of real;          {answers from solving simultaneous equations}
  valid: boolean;                      {simultaneous equation solution is valid}

label
  next_meas, not_angf;

begin
{
*   Build the lists according to the measurements related to this point.  The
*   following lists are created:
*
*     ANGF  -  Measurements of angles from other points.  The XY locations and
*       the 0 reference angles of the other points are known.
*
*     DISP  -  Measurements of distances to other points.  The XY locations of
*       the other points is known.
}
  nangf := 0;                          {init number of angles from known points}
  ndisp := 0;                          {init number of distances to known points}

  meas_p := pnt.meas_p;                {init to first measurement in the list}
  while meas_p <> nil do begin         {scan the list of measurement for this point}
    case meas_p^.measty of             {what kind of measurement is this one ?}

pntcalc_measty_angt_k: begin           {angle from here to another point}
  end;

pntcalc_measty_angf_k: begin           {angle to here from another point}
  pnt_p := meas_p^.angf_pnt_p;         {get pointer to the other point}
  if not (pntcalc_pntflg_xy_k in pnt_p^.flags) {location of other point not known ?}
    then goto next_meas;
  if not (pntcalc_pntflg_ang0_k in pnt_p^.flags) {angles have no reference ?}
    then goto next_meas;
  if nangf >= meas_list_max            {no room in list ?}
    then goto next_meas;
  nangf := nangf + 1;                  {count one more entry in the list}
  angf[nangf] := meas_p;               {save this measurement in the list}
  end;

pntcalc_measty_distxy_k: begin         {distance to another point}
  pnt_p := meas_p^.distxy_pnt_p;       {get pointer to the other point}
  if not (pntcalc_pntflg_xy_k in pnt_p^.flags) {location of other point not known ?}
    then goto next_meas;
  if ndisp >= meas_list_max            {no room in list ?}
    then goto next_meas;
  ndisp := ndisp + 1;                  {count one more entry in the list}
  disp[ndisp] := meas_p;               {save this measurement in the list}
  end;

      end;                             {end of measurement type cases}
next_meas:                             {done with this measurement, on to next}
    meas_p := meas_p^.next_p;          {to next measurement in the list}
    end;                               {back to check out this new measurement}
{
*   The ANGF and DISP lists have been set.
*
*   Resolve the location of this point from two or more angles from other
*   points.
}
  if nangf < 2 then goto not_angf;     {not enough points angles are known from ?}

  meas1_p := angf[1];                  {init to use the first two angles}
  meas2_p := angf[2];

  {***** WARNING *****
  *
  *   Picking the best pair of angles to use when more than two are available is
  *   not implemented yet.
  *
  ***** END WARNING *****}

  {
  *   Resolve the location of this points from the two angle measurements
  *   pointed to by MEAS1_P and MEAS2_P.  Both measurements are angles from
  *   other points.  The XY location and the 0 reference angles of those points
  *   are known.
  }
  angf_pnt_vect (meas1_p^, p1, v1);    {make start point and unit vector from point 1}
  angf_pnt_vect (meas2_p^, p2, v2);    {make start point and unit vector from point 2}

  simul[1, 1] := v1.x;                 {fill in simultaneous equation coefficients}
  simul[1, 2] := -v2.x;
  simul[1, 3] := p2.x - p1.x;
  simul[2, 1] := v1.y;
  simul[2, 2] := -v2.y;
  simul[2, 3] := p2.y - p1.y;
  math_simul (                         {solve the simultaneous equations}
    2,                                 {number of equations (and unknowns)}
    simul,                             {array of coefficients}
    smres,                             {returned results}
    valid);                            {TRUE when results are valid}
  if not valid then goto not_angf;

  pnt.coor.x := p1.x + smres[1]*v1.x;  {make final absolute coor of this point}
  pnt.coor.y := p1.y + smres[1]*v1.y;
  pnt.flags := pnt.flags + [pntcalc_pntflg_xy_k]; {indicate XY coor now known}
  return;

not_angf:                              {skip to here if can't find point from angles}







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
