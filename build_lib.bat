@echo off
rem
rem   BUILD_LIB
rem
rem   Build the PNTCALC library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_calc
call src_pas %srcdir% %libname%_lib
call src_pas %srcdir% %libname%_meas
call src_pas %srcdir% %libname%_pnt
call src_pas %srcdir% %libname%_read
call src_pas %srcdir% %libname%_show

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%

call src_doc pntcalc
call src_doc pntcalc_file
