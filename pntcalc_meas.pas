{   Manipulation of measurement descriptors.
}
module pntcalc_meas;
define pntcalc_meas_add_ang;
define pntcalc_meas_add_distxy;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Local subroutine PNTCALC_MEAS_NEW (PTC, MEAS_P)
*
*   Create a new measurement descriptor, initialize it, and return MEAS_P
*   pointing to it.
}
procedure pntcalc_meas_new (           {create and initialize new measurement descriptor}
  in out  ptc: pntcalc_t;              {library use state}
  out     meas_p: pntcalc_meas_p_t);   {returned pointer to the new measurement}
  val_param; internal;

begin
  util_mem_grab (                      {allocate memory for the descriptor}
    sizeof(meas_p^), ptc.mem_p^, false, meas_p);

  meas_p^.next_p := nil;               {initialize the descriptor}
  meas_p^.measty := pntcalc_measty_none_k;
  end;
{
********************************************************************************
*
*   Local subroutine PNTCLAC_MEAS_LINK (PTC, PNT, MEAS)
*
*   Add the measurement descriptor MEAS to the list of measurements for the
*   point PNT.
}
procedure pntcalc_meas_link (          {link measurement to a particular point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to link the measurement to}
  in out  meas: pntcalc_meas_t);       {measurement to add to the point}
  val_param; internal;

begin
  meas.next_p := pnt.meas_p;           {point to rest of measurements list}
  pnt.meas_p := addr(meas);            {new descriptor is now at start of list}
  end;
{
********************************************************************************
*
*   Subroutine PTNCALC_MEAS_ADD_ANG (PTC, PNT, PNT2, ANG, REF)
*
*   Add measurements for the angle to point PNT2 measured at point PNT.  ANG is
*   in radians, and is relative to the reference angle of point PNT.  REF of
*   TRUE indicates to use this angle measurement to define the 0 reference angle
*   for point PNT.
*
*   An angle TO measurement will be added to point PNT, and an angle FROM
*   measurement to point PNT2.
}
procedure pntcalc_meas_add_ang (       {add angle measurement from another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to add the measurement to}
  var     pnt2: pntcalc_point_t;       {point to which angle is measured}
  in      ang: real;                   {angle to PNT2, radians, rel to PNT ref ang}
  in      ref: boolean);               {use this measurement to get reference angle}
  val_param;

var
  meas_p: pntcalc_meas_p_t;            {pointer to the new measurement descriptor}

begin
  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement descriptor}
  meas_p^.measty := pntcalc_measty_angt_k; {this is angle to another point}
  meas_p^.angt_pnt_p := addr(pnt2);    {identify the remote point}
  meas_p^.angt_ang := ang;             {the measured angle}
  meas_p^.angt_ref := ref;             {whether this defines the reference angle}
  pntcalc_meas_link (ptc, pnt, meas_p^); {add the measurment to this point}

  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement descriptor}
  meas_p^.measty := pntcalc_measty_angf_k; {this is angle from another point}
  meas_p^.angf_pnt_p := addr(pnt);     {the point the angle was measured from}
  meas_p^.angf_ang := ang;             {the measured angle}
  pntcalc_meas_link (ptc, pnt2, meas_p^); {add the measurment to the remote point}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_MEAS_ADD_DISTXY (PTC, PNT, PNT2, DIST, STAT)
*
*   Add the distance measurement between points PNT and PNT2 to both points.
*   DIST is the distance projected onto the XY plane.
}
procedure pntcalc_meas_add_distxy (    {add distance in XY plane to another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt, pnt2: pntcalc_point_t;  {points distance measured between}
  in      dist: real;                  {distance between the points}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  meas_p: pntcalc_meas_p_t;            {pointer to newly created measurement}

begin
  sys_error_none (stat);               {init to no error encountered}
{
*   Check for distance between these two points already defined.
}
  meas_p := pnt.meas_p;                {init to first measurement in list}
  while meas_p <> nil do begin         {scan the list}
    if                                 {same thing as previously measured ?}
        (meas_p^.measty = pntcalc_measty_distxy_k) and {XY distance measurement ?}
        (meas_p^.distxy_pnt_p = addr(pnt2)) {between same two points ?}
        then begin
      if dist = meas_p^.distxy_dist then return; {same value, ignore}
      sys_stat_set (pntcalc_subsys_k, pntcalc_stat_distdup_k, stat);
      sys_stat_parm_vstr (pnt.name, stat);
      sys_stat_parm_vstr (pnt2.name, stat);
      return;
      end;
    meas_p := meas_p^.next_p;          {to next measurement in list}
    end;                               {back to check this new measurement}

  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement}
  meas_p^.measty := pntcalc_measty_distxy_k; {distance measurement in XY plane}
  meas_p^.distxy_pnt_p := addr(pnt2);  {the other point distance was measured to}
  meas_p^.distxy_dist := dist;         {the measured distance}
  pntcalc_meas_link (ptc, pnt, meas_p^); {add the measurement to point PNT}

  pntcalc_meas_new (ptc, meas_p);      {create and init a new measurement}
  meas_p^.measty := pntcalc_measty_distxy_k; {distance measurement in XY plane}
  meas_p^.distxy_pnt_p := addr(pnt);   {the other point distance was measured to}
  meas_p^.distxy_dist := dist;         {the measured distance}
  pntcalc_meas_link (ptc, pnt2, meas_p^); {add the measurement to point PNT2}
  end;
