{   Manipulation of point descriptors.
}
module pntcalc_pnt;
define pntcalc_pnt_new;
define pntcalc_pnt_link;
define pntcalc_pnt_add;
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
