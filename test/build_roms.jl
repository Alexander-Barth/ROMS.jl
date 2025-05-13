using ROMS
romsdir = expanduser("~/src/roms")
modeldir = expanduser("~/ROMS-implementation-test")

use_mpi = true;
#use_mpi = false;
#use_openmp = true;
use_openmp = false;

roms_application = "LigurianSea"
fortran_compiler = "gfortran"
jobs = 8

ROMS.build(romsdir,roms_application,modeldir;
      jobs,
      fortran_compiler,
      use_mpi)
