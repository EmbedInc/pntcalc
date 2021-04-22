{   Manipulation of point descriptors.
}
module pntcalc_pnt;
define pntcalc_pnt_new;
define pntcalc_pnt_link;
define pntcalc_pnt_add;
define pntcalc_pnt_find;
define pntcalc_pnt_get;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Subroutine PNTCALC_PNT_NEW (PTC, PNT_P)
*
*   Create and initialize a new point descriptor.  PNT_P is returned pointing to
*   the new descriptor.
}
procedure pntcalc_pnt_new (            {create and initialize new point, not added to list}
  in out  ptc: pntcalc_t;              {library use state}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the new point}
  val_param;

begin
  util_mem_grab (                      {allocate memory for the new point}
    sizeof(pnt_p^), ptc.mem_p^, false, pnt_p);

  pnt_p^.next_p := nil;                {init to default or benign values}
  pnt_p^.name.max := size_char(pnt_p^.name.str);
  pnt_p^.name.len := 0;
  pnt_p^.meas_p := nil;
  pnt_p^.coor.x := 0.0;
  pnt_p^.coor.y := 0.0;
  pnt_p^.coor.z := 0.0;
  pnt_p^.near.x := 0.0;
  pnt_p^.near.y := 0.0;
  pnt_p^.near.z := 0.0;
  pnt_p^.ang0 := 0.0;
  pnt_p^.flags := [];
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_PNT_LINK (PTC, PNT)
*
*   Link the point PNT to the end of the points list.
}
procedure pntcalc_pnt_link (           {link point to end of points list}
  in out  ptc: pntcalc_t;              {library use state}
  in out  pnt: pntcalc_point_t);       {the point to add}
  val_param;

begin
  pnt.next_p := nil;                   {no following point in the list}

  if ptc.pnt_p = nil
    then begin                         {this is first point in the list}
      ptc.pnt_p := addr(pnt);
      end
    else begin                         {adding to end of existing list}
      ptc.pnt_last_p^.next_p := addr(pnt);
      end
    ;
  ptc.pnt_last_p := addr(pnt);         {update pointer to last list entry}

  ptc.npoints := ptc.npoints + 1;      {count one more point in the list}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_PNT_ADD (PTC, PNT_P)
*
*   Create a new point, initialize it, add it to the end of the points list, and
*   return PNT_P pointing to it.
}
procedure pntcalc_pnt_add (            {create and init point, add to end of points list}
  in out  ptc: pntcalc_t;              {library use state}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the new point}
  val_param;

begin
  pntcalc_pnt_new (ptc, pnt_p);        {create and init the new point}
  pntcalc_pnt_link (ptc, pnt_p^);      {add it to the end of the points list}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_PNT_FIND (PTC, NAME, PNT_P)
*
*   Find the existing point of name NAME, and return PNT_P pointing to it.
*   PNT_P is returned NIL if no such point currently exists.
}
procedure pntcalc_pnt_find (           {find existing point}
  in out  ptc: pntcalc_t;              {library use state}
  in      name: univ string_var_arg_t; {name of point to find, case sensitive}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the point, NIL on not found}
  val_param;

begin
  pnt_p := ptc.pnt_p;                  {init to first list entry}
  while pnt_p <> nil do begin          {scan the list}
    if string_equal (pnt_p^.name, name) then return; {found the point ?}
    pnt_p := pnt_p^.next_p;            {advance to next point in the list}
    end;                               {back to check this new point}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_PNT_GET (PTC, NAME, PNT_P)
*
*   Return PNT_P pointing to the point with name NAME.  The point is created, if
*   not previously existing.
}
procedure pntcalc_pnt_get (            {get point by name, create new if not existing}
  in out  ptc: pntcalc_t;              {library use state}
  in      name: univ string_var_arg_t; {name of point to get, case sensitive}
  out     pnt_p: pntcalc_point_p_t);   {returned pointer to the point}
  val_param;

begin
  pntcalc_pnt_find (ptc, name, pnt_p); {look for existing point}
  if pnt_p <> nil then return;         {found existing point ?}

  pntcalc_pnt_add (ptc, pnt_p);        {create a new blank point, add it to the list}
  string_copy (name, pnt_p^.name);     {set the name of this new point}
  end;
