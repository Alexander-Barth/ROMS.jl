
# # Regional Ocean Modeling System (ROMS)
#
#
# The Regional Ocean Modeling System (ROMS) is a free-surface, terrain-following,
# primitive equations ocean model widely used by the scientific community for
# a diverse range of applications.
#
# ## Compilation
#
# The source code of ROMS is distributed via [GitHub](https://github.com/myroms/roms).
# We use version 4.1 of the ROMS code.
# The code is downloaded to the directory `~/src/roms`:

using ROMS

romsdir = expanduser("~/src/roms")
if !isdir(romsdir)
    mkpath(dirname(romsdir))
    cd(dirname(romsdir)) do
        run(`git clone https://github.com/myroms/roms`)
        cd("roms") do
            run(`git checkout roms-4.1`)
        end
    end
end

# All files that are specific to a given implementation of ROMS will be
# saved in a different directory `modeldir`:

modeldir = expanduser("~/ROMS-implementation-test")
mkpath(modeldir)

# Before we can compile ROMS we need to
# * activate diffent terms of the momentum equations
# * specify the schemes uses for advection, horizontal mixing,
#   type equation of state, ...
#
# The header files controls the compilation of the ROMS model by telling the
# compiler which part of the code needs to be compiled. If you modify this file,
# ROMS need to be recompiled.

# Do not change the two first lines and the last line of the following cell.
# When you execute the cell, the header file with the specified content is
# created.

header_file = joinpath(modeldir,"liguriansea.h")
write(header_file,"""
#define UV_ADV                    /* turn ON advection terms */
#define UV_COR                    /* turn ON Coriolis term */
#define DJ_GRADPS                 /* Splines density  Jacobian (Shchepetkin, 2000) */
#define NONLIN_EOS                /* define if using nonlinear equation of state */
#define SALINITY                  /* define if using salinity */
#define SOLVE3D                   /* define if solving 3D primitive equations */
#define MASKING                   /* define if there is land in the domain */
#define TS_U3HADVECTION           /* Third-order upstream horizontal advection of tracers */
#define TS_C4VADVECTION           /* Fourth-order centered vertical advection of tracers */
#define TS_DIF2                   /* use to turn ON or OFF harmonic horizontal mixing  */
#define MIX_S_UV                  /* mixing along constant S-surfaces */
#define UV_VIS2                   /* turn ON Laplacian horizontal mixing */
#define AVERAGES
#define UV_QDRAG
#define MIX_S_TS

#define  MY25_MIXING
#ifdef MY25_MIXING
#define N2S2_HORAVG
#define KANTHA_CLAYSON
#endif

#define ANA_BSFLUX                /* analytical bottom salinity flux */
#define ANA_BTFLUX                /* analytical bottom temperature flux */
#define ANA_SSFLUX

#define BULK_FLUXES               /* turn ON bulk fluxes computation */
#define CLOUDS
#define LONGWAVE
#define SOLAR_SOURCE
""");

# The [ROMS wiki](https://www.myroms.org/wiki/Documentation_Portal) give more information about the [compiler different options](https://www.myroms.org/wiki/Options).

# ROMS can use the MPI ([Message Passing Interface](https://en.wikipedia.org/wiki/Message_Passing_Interface)) or OpenMP ([Open Multi-Processing](https://en.wikipedia.org/wiki/OpenMP)) for parallelization (but not both at the same time):

use_mpi = true;
#use_mpi = false;
#use_openmp = true;
use_openmp = false;

# `roms_application` is a descriptive name of the domain or the particular application
# that the use can choose. We compile ROMS with the [GNU Fortran](https://en.wikipedia.org/wiki/GNU_Fortran) compiler using 8 jobs for compilation.

roms_application = "LigurianSea"
fortran_compiler = "gfortran"
jobs = 8

ROMS.build(romsdir,roms_application,modeldir;
           jobs,
           fortran_compiler,
           use_openmp,
           use_mpi)