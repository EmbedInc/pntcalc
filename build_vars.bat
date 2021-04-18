@echo off
rem
rem   Define the variables for running builds from this source library.
rem
set srcdir=pntcalc
set buildname=
call treename_var "(cog)source/pntcalc" sourcedir
set libname=pntcalc
set fwname=
call treename_var "(cog)src/%srcdir%/debug_%fwname%.bat" tnam
make_debug "%tnam%"
call "%tnam%"
