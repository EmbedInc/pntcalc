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
*     MATH_RAD_DEG, and MATH_DEG_RAD are the multiplication factors to convert
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
*   MEAS_P points to a reference angle measurement.  The XY coordinates of this
*   point and the remote point are known.  Now compute the absolute 0 reference
*   angle.
}
make_ref:
  dx := meas_p^.angt_pnt_p^.coor.x - pnt.coor.x; {make delta to remote point}
  dy := meas_p^.angt_pnt_p^.coor.y - pnt.coor.y;
  ang := arctan2 (dy, dx);             {make the angle to the remote point}
  pnt.ang0 :=                          {set the reference angle for this point}
    math_angle_surv(ang) + meas_p^.angt_ang;
  pnt.flags := pnt.flags + [pntcalc_pntflg_ang0_k]; {indicate ref angle set}

  if pntcalc_gflg_showcalc_k in ptc.flags then begin
    writeln ('  Point ', pnt.name.str:pnt.name.len, ' ANG0 ',
      (pnt.ang0 * math_rad_deg):7:2, ' by angle to point ',
      meas_p^.angt_pnt_p^.name.str:meas_p^.angt_pnt_p^.name.len);
    end;
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
*   Local subroutine RESOLVE_XY_2ANG (PTC, PNT, MEAS1, MEAS2)
*
*   Resolve the location of the point PNT from the two angle measurements MEAS1
*   and MEAS2.  Both measurements must be angles from other points, the XY
*   location of those points must be known, and the 0 reference angle for those
*   points known.
}
procedure resolve_xy_2ang (            {resolve loc from 2 angles from other points}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {the point to resolve location of}
  in      meas1, meas2: pntcalc_meas_t); {the angle measurements from remote points}
  val_param; internal;

var
  p1, p2: vect_2d_t;                   {start point of the two rays}
  v1, v2: vect_2d_t;                   {unit direction vectors of the two rays}
  simul: array[1..2, 1..3] of real;    {coefficients for simultaneous equations}
  smres: array[1..2] of real;          {answers from solving simultaneous equations}
  valid: boolean;                      {simultaneous equation solution is valid}

begin
  angf_pnt_vect (meas1, p1, v1);       {make start point and unit vector from point 1}
  angf_pnt_vect (meas2, p2, v2);       {make start point and unit vector from point 2}

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
  if not valid then return;

  pnt.coor.x := p1.x + smres[1]*v1.x;  {make final absolute coor of this point}
  pnt.coor.y := p1.y + smres[1]*v1.y;
  pnt.flags := pnt.flags + [pntcalc_pntflg_xy_k]; {indicate XY coor now known}
  end;
{
********************************************************************************
*
*   Local subroutine RESOLVE_XY_DISTANG (PTC, PNT, MDIST, MANG)
*
*   Resolve the location of point PNT from an angle and distance from another
*   point.  MDIST is the distance measurement from the other point, and MANG
*   the angle measurement from that point.  The XY location and reference angle
*   of the other point must be known.
}
procedure resolve_xy_distang (         {resolve loc from dist and ang from other point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {the point to resolve location of}
  in      mdist: pntcalc_meas_t;       {distance measurement to remote point}
  in      mang: pntcalc_meas_t);       {angle measurement from remote point}
  val_param; internal;

var
  p: vect_2d_t;                        {point angle and distance measured from}
  dist: real;                          {distance to remote point}
  ang: real;                           {angle measured from remote point}

begin
  p.x := mdist.distxy_pnt_p^.coor.x;   {get location measurements are from}
  p.y := mdist.distxy_pnt_p^.coor.y;
  dist := mdist.distxy_dist;           {distance to the remote point}
  ang := math_angle_math (             {angle from other point to here, math type}
    mang.angf_ang + mang.angf_pnt_p^.ang0);

  pnt.coor.x := p.x + cos(ang)*dist;   {make coordinate of this point}
  pnt.coor.y := p.y + sin(ang)*dist;
  pnt.flags := pnt.flags + [pntcalc_pntflg_xy_k]; {indicate XY coor now known}
  end;
{
********************************************************************************
*
*   Local subroutine RESOLVE_XY_2DIST (PTC, PNT, MEAS1, MEAS2)
*
*   Resolve the location of the point PNT from the two distance measurements
*   MEAS1 and MEAS2.  The point has its NEAR location set.  MEAS1 and MEAS2 must
*   be distance measurements to points that have known locations.
}
procedure resolve_xy_2dist (           {resolve loc from 2 distances to other points}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {the point to resolve location of}
  in      meas1, meas2: pntcalc_meas_t); {distance measurements to remote points}
  val_param; internal;

var
  p1, p2: vect_2d_t;                   {coordinates of the two points}
  p3: vect_2d_t;                       {projection of solution points along baseline}
  r1, r2: real;                        {the distances from each of the two points}
  vbase: vect_2d_t;                    {baseline unit vector, from P1 to P2}
  vperp: vect_2d_t;                    {unit vector perpendicular to baseline}
  dbase: real;                         {total distance between the two points}
  d1: real;                            {distance from P1 to PNT along basline}
  dperp: real;                         {distance to solution point in perp direction}
  vnear: vect_2d_t;                    {vector from P1 to NEAR point}
  m: real;                             {scratch}

begin
  p1.x := meas1.distxy_pnt_p^.coor.x;  {get coordinates of the two remote points}
  p1.y := meas1.distxy_pnt_p^.coor.y;
  p2.x := meas2.distxy_pnt_p^.coor.x;
  p2.y := meas2.distxy_pnt_p^.coor.y;

  r1 := meas1.distxy_dist;             {get the distances from each remote point}
  r2 := meas2.distxy_dist;

  vbase.x := p2.x - p1.x;              {make raw baseline vector}
  vbase.y := p2.y - p1.y;

  dbase := sqrt(sqr(vbase.x) + sqr(vbase.y)); {length of the baseline}
  if dbase < 1.0e-30 then return;      {points too close ?}
  if dbase > (r1 + r2) then return;    {the circles are apart ?}
  if r1 > (dbase + r2) then return;    {circle 1 too big to intersect circle 2 ?}
  if r2 > (dbase + r1) then return;    {circle 2 too big to intersect circle 1 ?}

  vbase.x := vbase.x / dbase;          {make baseline unit vector}
  vbase.y := vbase.y / dbase;

  vperp.x := -vbase.y;                 {make unit vector perpendicular to baseline}
  vperp.y := vbase.x;

  d1 :=                                {distance from P1 along baseline to solution points}
    (sqr(dbase) + sqr(r1) - sqr(r2)) / (2.0 * dbase);
  p3.x := p1.x + (d1 * vbase.x);       {where solution points are along the baseline}
  p3.y := p1.y + (d1 * vbase.y);

  dperp := sqr(r1) - sqr(d1);          {make perp distance to solution point in DPERP}
  if dperp < 0.0 then return;
  dperp := sqrt(dperp);

  vnear.x := pnt.near.x - p1.x;        {vector to NEAR point from P1}
  vnear.y := pnt.near.y - p1.y;
  m := (vnear.x * vperp.x) + (vnear.y * vperp.y); {NEAR projection in perp direction}

  if m >= 0.0
    then begin                         {choose the solution point in +PERP direction}
      pnt.coor.x := p3.x + (dperp * vperp.x);
      pnt.coor.y := p3.y + (dperp * vperp.y);
      end
    else begin                         {choose the solution point in -PERP direction}
      pnt.coor.x := p3.x - (dperp * vperp.x);
      pnt.coor.y := p3.y - (dperp * vperp.y);
      end
    ;
  pnt.flags := pnt.flags + [pntcalc_pntflg_xy_k]; {indicate XY location is now set}
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
*     1 - Angles are known from two or more points with known locations.  When
*         there are more than two points, the two with the angles least
*         co-linear are chosen.
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
  ii, jj: sys_int_machine_t;           {scratch integers and loop counters}
  meas1_p, meas2_p: pntcalc_meas_p_t;  {pointers to measurements for resolving location}

label
  next_meas, not_angf, not_pntang, not_dist2;

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

  resolve_xy_2ang (                    {resolve loc from 2 angles from other points}
    ptc,                               {library use state}
    pnt,                               {the point to resolve location of}
    meas1_p^, meas2_p^);               {angle measurements from known points}
  if not (pntcalc_pntflg_xy_k in pnt.flags) {unable to resolve location ?}
    then goto not_angf;

  if pntcalc_gflg_showcalc_k in ptc.flags then begin
    write ('  Point ', pnt.name.str:pnt.name.len, ' at ');
    pntcalc_show_coor (pnt.coor, pntcalc_pntflg_coor_k in pnt.flags);
    writeln (' by angles from points ',
      meas1_p^.angf_pnt_p^.name.str:meas1_p^.angf_pnt_p^.name.len, ' and ',
      meas2_p^.angf_pnt_p^.name.str:meas2_p^.angf_pnt_p^.name.len);
    end;
  return;

not_angf:                              {skip to here if can't find point from angles}
{
*   Resolve the location of this point from an angle and distance from another
*   point.
*
*   After scanning the available choices, MEAS1_P will point to the distance
*   measurement, and MEAS2_P to the angle measurement.  If there are multiple
*   choices, the one with the shortest distance will be used.
}
  meas1_p := nil;                      {init to no suitable distance measurement}

  for ii := 1 to ndisp do begin        {scan list of distances to other points}
    for jj := 1 to nangf do begin      {look for corresponding angle measurements}
      if angf[jj]^.angf_pnt_p = disp[ii]^.distxy_pnt_p then begin {angle from same point ?}
        if meas1_p = nil
          then begin                   {no previous angle/distance measurements}
            meas1_p := disp[ii];       {save pointer to distance measurement}
            meas2_p := angf[jj];       {save pointer to angle measurement}
            end
          else begin                   {prev angle/dist was found}
            if disp[ii]^.distxy_dist < meas1_p^.distxy_dist then begin {closer ?}
              meas1_p := disp[ii];     {switch to new closer angle/dist measurements}
              meas2_p := angf[jj];
              end;
            end
          ;
        end;                           {end of found angle for dist measurement}
      end;                             {back for next angle to check against dist pnt}
    end;                               {back for next distance measurement in list}
  if meas1_p = nil then goto not_pntang; {no angle/distance measurements available ?}

  resolve_xy_distang (                 {resolve loc from distance and angle}
    ptc,                               {library use state}
    pnt,                               {the point to resolve location of}
    meas1_p^,                          {distance measurement}
    meas2_p^);                         {angle measurement}
  if not (pntcalc_pntflg_xy_k in pnt.flags) {unable to resolve location ?}
    then goto not_pntang;

  if pntcalc_gflg_showcalc_k in ptc.flags then begin
    write ('  Point ', pnt.name.str:pnt.name.len, ' at ');
    pntcalc_show_coor (pnt.coor, pntcalc_pntflg_coor_k in pnt.flags);
    writeln (' by angle/dist from point ',
      meas1_p^.distxy_pnt_p^.name.str:meas1_p^.distxy_pnt_p^.name.len);
    end;
  return;

not_pntang:                            {no distance with angle measurements available}
{
*   Resolve the location of this point from distances from two other points.
*   The NEAR location of this point must be filled in.  Distances from two other
*   points results in two possible locations (intersection of two circles).  The
*   one closest to the NEAR point is used.
}
  if not (pntcalc_pntflg_nearxy_k in pnt.flags) {NEAR of this point is not known ?}
    then goto not_dist2;
  if ndisp < 2                         {not at least 2 distances availble ?}
    then goto not_dist2;

  {***** WARNING *****
  *
  *   Picking the best pair of distances to use when more than 2 are available
  *   has not been implemented yet.
  *
  ***** END WARNING *****}

  meas1_p := disp[1];                  {select the two distance measurements to use}
  meas2_p := disp[2];

  resolve_xy_2dist (                   {resolve loc from 2 distances to other points}
    ptc,                               {library use state}
    pnt,                               {the point to resolve location of}
    meas1_p^, meas2_p^);               {distance measurements to two known points}
  if not (pntcalc_pntflg_xy_k in pnt.flags) {unable to resolve location ?}
    then goto not_dist2;

  if pntcalc_gflg_showcalc_k in ptc.flags then begin
    write ('  Point ', pnt.name.str:pnt.name.len, ' at ');
    pntcalc_show_coor (pnt.coor, pntcalc_pntflg_coor_k in pnt.flags);
    writeln (' by distance from points ',
      meas1_p^.distxy_pnt_p^.name.str:meas1_p^.distxy_pnt_p^.name.len,
      ' and ',
      meas2_p^.distxy_pnt_p^.name.str:meas2_p^.distxy_pnt_p^.name.len);
    end;
  return;

not_dist2:                             {can't use distances from two other points}







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
      if pntcalc_calc_point (ptc, pnt_p^) then begin {this point updated ?}
        changed := true;
        end;
      pnt_p := pnt_p^.next_p;          {to next point in the list}
      end;                             {back to do this new point}

    if not changed then exit;          {no change, done all that is possible ?}
    end;                               {back for another iteration}
  end;
