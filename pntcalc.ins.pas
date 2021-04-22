{   Public include file for the PNTCALC library.
}
const
  pntcalc_subsys_k = -74;              {subsystem ID for this library}
  pntcalc_stat_prevcoor_k = 1;         {full absolute coordinate already set}
  pntcalc_stat_prevxy_k = 2;           {absolute XY coordinate already set}
  pntcalc_stat_prevrefa_k = 3;         {reference angle already set}

type
  pntcalc_point_p_t = ^pntcalc_point_t;

  pntcalc_measty_k_t = (               {different types of measurements for resolving points}
    pntcalc_measty_none_k,             {no measurement, not filled in, not used, etc}
    pntcalc_measty_angt_k,             {angle to another point, in XY plane}
    pntcalc_measty_angf_k,             {angle from another point, in XY plane}
    pntcalc_measty_distxy_k);          {distance to another point, in XY plane}
  pntcalc_measty_t = set of pntcalc_measty_k_t;

  pntcalc_meas_p_t = ^pntcalc_meas_t;
  pntcalc_meas_t = record              {one measurement for resolving a point}
    next_p: pntcalc_meas_p_t;          {to next measurement for this point}
    measty: pntcalc_measty_k_t;        {the type of this measurement}
    case pntcalc_measty_k_t of
pntcalc_measty_angt_k: (               {angle to another point}
      angt_pnt_p: pntcalc_point_p_t;   {the other point the angle is to}
      angt_ang: real;                  {radians to the other point, relative to this point's ANG0}
      angt_ref: boolean;               {the angle to this point defines the reference angle}
      );
pntcalc_measty_angf_k: (               {angle from another point}
      angf_pnt_p: pntcalc_point_p_t;   {the other point the angle is from}
      angf_ang: real;                  {radian measured from remote point, relative to ref angle}
      );
pntcalc_measty_distxy_k: (             {XY plane distance from to point}
      distxy_pnt_p: pntcalc_point_p_t; {the other point the distance is to}
      distxy_dist: real;               {distance to the other point}
      );
    end;

  pntcalc_pntflg_k_t = (               {individual modifier flags for points}
    pntcalc_pntflg_xy_k,               {XY coordinate is set}
    pntcalc_pntflg_coor_k,             {full coordinate is set}
    pntcalc_pntflg_nearxy_k,           {XY of NEAR filled in}
    pntcalc_pntflg_nearxyz_k,          {XYZ of NEAR filled in}
    pntcalc_pntflg_ang0_k);            {0 ref for angle measurments is set}
  pntcalc_pntflg_t = set of pntcalc_pntflg_k_t;

  pntcalc_point_t = record             {data about one point}
    next_p: pntcalc_point_p_t;         {to next point in list}
    name: string_var32_t;              {point name, for user interactions}
    meas_p: pntcalc_meas_p_t;          {to list of measurements for this point}
    coor: vect_3d_t;                   {absolute coordinate}
    near: vect_3d_t;                   {coordinate that this point is near to}
    ang0: real;                        {0 reference for angle measurements from this point}
    flags: pntcalc_pntflg_t;           {set of modifier flags}
    end;

  pntcalc_t = record                   {state for one use of this library}
    mem_p: util_mem_context_p_t;       {mem context for all dynamic memory}
    pnt_p: pntcalc_point_p_t;          {list of points}
    pnt_last_p: pntcalc_point_p_t;     {to last point in list}
    end;
{
*   Subroutines and functions.
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

procedure pntcalc_meas_add_ang (       {add angle measurement from another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t;        {point to add the measurement to}
  var     pnt2: pntcalc_point_t;       {point to which angle is measured}
  in      ang: real;                   {angle to PNT2, radians, rel to PNT ref ang}
  in      ref: boolean);               {use this measurement to get reference angle}
  val_param; extern;

procedure pntcalc_meas_add_distxy (    {add distance in XY plane to another point}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt, pnt2: pntcalc_point_t;  {points distance measured between}
  in      dist: real);                 {distance between the points}
  val_param; extern;

procedure pntcalc_pnt_add (            {create and init point, add to end of points list}
  in out  ptc: pntcalc_t;              {library use state}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the new point}
  val_param; extern;

procedure pntcalc_pnt_find (           {find existing point}
  in out  ptc: pntcalc_t;              {library use state}
  in      name: univ string_var_arg_t; {name of point to find, case sensitive}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the point, NIL on not found}
  val_param; extern;

procedure pntcalc_pnt_get (            {get point by name, create new if not existing}
  in out  ptc: pntcalc_t;              {library use state}
  in      name: univ string_var_arg_t; {name of point to get, case sensitive}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the point}
  val_param; extern;

procedure pntcalc_pnt_link (           {link point to end of points list}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to add}
  val_param; extern;

procedure pntcalc_pnt_new (            {create and initialize new point, not added to list}
  in out  ptc: pntcalc_t;              {library use state}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the new point}
  val_param; extern;

procedure pntcalc_read_file (          {read input from file}
  in out  ptc: pntcalc_t;              {library use state}
  in      fnam: univ string_var_arg_t; {file name}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure pntcalc_show_meas (          {show data of one measurement to STDOUT}
  in      meas: pntcalc_meas_t;        {the measurement to show}
  in      indent: sys_int_machine_t;   {number of spaces to indent top level lines}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure pntcalc_show_point (         {show data of one point to STDOUT}
  in      pnt: pntcalc_point_t;        {the point to show}
  in      indent: sys_int_machine_t;   {number of spaces to indent top level lines}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure pntcalc_show (               {show all the data in a lib usage}
  in      ptc: pntcalc_t;              {library use state to show data of}
  in      indent: sys_int_machine_t);  {number of spaces to indent top level lines}
  val_param; extern;
