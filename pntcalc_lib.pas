{   High level library management.
}
module pntcalc;
define pntcalc_lib_new;
define pntcalc_lib_end;
%include 'pntcalc2.ins.pas';
{
********************************************************************************
*
*   Local subroutine PNTCALC_LIB_INIT (PTC)
*
*   Init the library use state PTC to default or benign values.  No resources
*   will be allocated.  The previous state of PTC is irrelevant.
}
procedure pntcalc_lib_init (           {init lib use state to default or benign}
  out     ptc: pntcalc_t);             {library use state to initialize}
  val_param; internal;

begin
  ptc.mem_p := nil;
  ptc.pnt_p := nil;
  ptc.pnt_last_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_LIB_NEW (MEM, PTC, STAT)
*
*   Create a new use of the PNTCALC library.  MEM is the parent memory context.
*   A subordinate memory context will be created, and all dynamic memory for the
*   library use will be allocated under that new context.  PTC is returned the
*   new library use state.  PTC will be completely initialized, with its
*   previous state being irrelevant.
}
procedure pntcalc_lib_new (            {create a new use of this library}
  in out  mem: util_mem_context_t;     {parent mem context, will create subordinate}
  out     ptc: pntcalc_t;              {returned initialized library use state}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}
  pntcalc_lib_init (ptc);              {init the library use state}

  util_mem_context_get (mem, ptc.mem_p) {create private mem context for lib state}
  end;
{
********************************************************************************
*
*   Subroutine PNTCALC_LIB_END (PTC, STAT);
*
*   End a use of the PNTCALC library.  PTC is the library use state, and will be
*   returned invalid.  All resources allocated to this use of the library will
*   be deallocated.
}
procedure pntcalc_lib_end (            {end a use of the library, deallocate resources}
  in out  ptc: pntcalc_t;              {library use state, returned invalid}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}

  util_mem_context_del (ptc.mem_p);    {dealloc all dyn mem, delete mem context}
  pntcalc_lib_init (ptc);              {set lib use state to default or benign values}
  end;
