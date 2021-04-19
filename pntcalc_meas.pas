{   Manipulation of measurement descriptors.
}
module pntcalc_meas;
define pntcalc_meas_new;
define pntcalc_meas_link;
define pntcalc_meas_add;
define pntcalc_meas_set_ang;
define pntcalc_meas_set_distxy;
define pntcalc_meas_add_ang;
define pntcalc_meas_add_distxy;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_NEW (PTC, MEAS_P)
*
*   Create a new measurement descriptor, initialize it, and return MEAS_P
*   pointing to it.
}
procedure pntcalc_meas_new (           {create and initialize new measurement descriptor}
  in out  ptc: pntcalc_t;              {library use state}
  out     meas_p: pntcalc_meas_p_t);   {returned pointer to the new measurement}
  val_param;

begin
  util_mem_grab (                      {allocate memory for the descriptor}
    sizeof(meas_p^), ptc.mem_p^, false, meas_p);

  meas_p^.next_p := nil;               {initialize the descriptor}
  meas_p^.measty := pntcalc_measty_none_k;
  end;
{
********************************************************************************
*
*   Subroutine PNTCLAC_MEAS_LINK (PTC, PNT, MEAS)
*
*   Add the measurement descriptor MEAS to the list of measurements for the
*   point PNT.
}
procedure pntcalc_meas_link (          {link measurement to a particular point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to link the measurement to}
  in out  meas: pntcalc_meas_t);       {measurement to add to the point}
  val_param;

begin
  meas.next_p := pnt.meas_p;           {point to rest of measurements list}
  pnt.meas_p := addr(meas);            {new descriptor is now at start of list}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_ADD (PTC, PNT, MEAS_P)
*
*   Create a new measurement descriptor, initialize it, add it to the point PNT,
*   and return MEAS_P pointing to the new descriptor.
}
procedure pntcalc_meas_add (           {create and init measurement, add to point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to add the measurement to}
  out     meas_p: pntcalc_meas_p_t);   {returned pointer to the new measurement}
  val_param;

begin
  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement}
  pntcalc_meas_link (ptc, pnt, meas_p^); {add the measurement to the point}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_SET_ANG (PTC, MEAS, PNT, ANG)
*
*   Set the measurement MEAS to be the angle to point PNT.  ANG is the angle in
*   radians, relative to the 0 angle of the point the measurement was taken
*   from.
}
procedure pntcalc_meas_set_ang (       {set measurement of angle to another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  meas: pntcalc_meas_t;        {the measurement to set}
  var     pnt: pntcalc_point_t;        {point to which angle was measured}
  in      ang: real);                  {angle, radians, rel to PNT 0 ref ang}
  val_param;

begin
  meas.measty := pntcalc_measty_ang_k; {this is an angle measurement}
  meas.ang_pnt_p := addr(pnt);         {identify the remote point}
  meas.ang_ang := ang;                 {save the angle value}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_SET_DISTXY (PTC, MEAS, PNT, DIST)
*
*   Set the measurement MEAS to be the distance to point PNT.  The distance DIST
*   is measured in the XY plane.  Put another way, DIST is the project of the
*   distance onto the XY plane.
}
procedure pntcalc_meas_set_distxy (    {set measurement of XY plane distance to a point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  meas: pntcalc_meas_t;        {the measurement to set}
  var     pnt: pntcalc_point_t;        {point to which distance was measured}
  in      dist: real);                 {distance to the remote point}
  val_param;

begin
  meas.measty := pntcalc_measty_distxy_k; {this is a XY distance measurment}
  meas.distxy_pnt_p := addr(pnt);      {identify the remote point}
  meas.distxy_dist := dist;            {save the distance value}
  end;
{
********************************************************************************
*
*   Subroutine PTNCALC_MEAS_ADD_ANG (PTC, PNT, PNT2, ANG)
*
*   Add and angle measurement to the point PNT.  PNT2 is the remote point to
*   which the angle was measured.  ANG is in radians, and relative to the 0
*   angle of point PNT.
}
procedure pntcalc_meas_add_ang (       {add angle measurement from another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to add the measurement to}
  var     pnt2: pntcalc_point_t;       {point to which angle is measured}
  in      ang: real);                  {angle to PNT2, radians, rel to PNT 0 ref ang}
  val_param;

var
  meas_p: pntcalc_meas_p_t;            {pointer to the new measurement descriptor}

begin
  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement descriptor}
  pntcalc_meas_set_ang (ptc, meas_p^, pnt2, ang); {fill in the measurement}
  pntcalc_meas_link (ptc, pnt, meas_p^); {add the measurment to the point}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_ADD_DISTXY (PTC, PNT, PNT2, DIST)
*
*   Add the distance measurement between points PNT and PNT2 to both points.
*   DIST is the distance projected onto the XY plane.
}
procedure pntcalc_meas_add_distxy (    {add distance in XY plane to another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt, pnt2: pntcalc_point_t;  {points distance measured between}
  in      dist: real);                 {distance between the points}
  val_param;

var
  meas_p: pntcalc_meas_p_t;            {pointer to newly created measurement}

begin
  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement}
  pntcalc_meas_set_distxy (ptc, meas_p^, pnt2, dist); {fill in the measurement}
  pntcalc_meas_link (ptc, pnt, meas_p^); {add the measurement to point PNT}

  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement}
  pntcalc_meas_set_distxy (ptc, meas_p^, pnt, dist); {fill in the measurement}
  pntcalc_meas_link (ptc, pnt2, meas_p^); {add the measurement to point PNT2}
  end;
