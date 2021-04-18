{   Public include file for the PNTCALC library.
}
const
  pntcalc_subsys_k = -74;              {subsystem ID for this library}

type
  pntcalc_t = record                   {state for one use of this library}
    mem_p: util_mem_context_p_t;       {mem context for all dynamic memory}
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
