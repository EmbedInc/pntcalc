{   Public include file for the PNTCALC library.
}
const
  pntcalc_subsys_k = -74;              {subsystem ID for this library}

type
  pntcalc_point_p_t = ^pntcalc_point_t;

  pntcalc_measty_k_t = (               {different types of measurements for resolving points}
    pntcalc_measty_ang_k,              {angle from another point, in XY plane}
    pntcalc_measty_distxy_k);          {distance to another point, in XY plane}
  pntcalc_measty_t = set of pntcalc_measty_k_t;

  pntcalc_meas_p_t = ^pntcalc_meas_t;
  pntcalc_meas_t = record              {one measurement for resolving a point}
    next_p: pntcalc_meas_p_t;          {to next measurement for this point}
    measty: pntcalc_measty_k_t;        {the type of this measurement}
    case pntcalc_measty_k_t of
pntcalc_measty_ang_k: (                {angle from another point}
      ang_pnt_p: pntcalc_point_p_t;    {the other point the angle is from}
      ang_ang: real;                   {angle from the other point, relative to its ANG0}
      );
pntcalc_measty_distxy_k: (             {XY plane distance from to point}
      distxy_pnt_p: pntcalc_point_p_t; {the other point the distance is to}
      distxy_dist: real;               {distance to the other point}
      );
    end;

  pntcalc_pntflg_k_t = (               {individual modifier flags for points}
    pntcalc_pntflg_xy_k,               {XY coordinate is set}
    pntcalc_pntflg_coor_k,             {full coordinate is set}
    pntcalc_ang0_k);                   {0 ref for angle measurments is set}
  pntcalc_pntflg_t = set of pntcalc_pntflg_k_t;

  pntcalc_point_t = record             {data about one point}
    next_p: pntcalc_point_p_t;         {to next point in list}
    name: string_var32_t;              {point name, for user interactions}
    meas_p: pntcalc_meas_p_t;          {to list of measurements for this point}
    coor: vect_3d_t;                   {absolute coordinate}
    ang0: real;                        {0 reference for angle measurements from this point}
    flags: pntcalc_pntflg_t;           {set of modifier flags}
    end;

  pntcalc_t = record                   {state for one use of this library}
    mem_p: util_mem_context_p_t;       {mem context for all dynamic memory}
    pnt_p: pntcalc_point_p_t;          {list of points}
    pnt_last_p: pntcalc_point_p_t;     {to last point in list}
    end;
{
*   Subroutines and function.
}
procedure pntcalc_lib_end (            {end a use of the library, deallocate resources}
  in out  ptc: pntcalc_t;              {library use state, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure pntcalc_lib_new (            {create a new use of this library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     ptc: pntcalc_t;              {returned initialized library use state}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
