
# # Compilation of ROMS
#
#md # *The code here is also available as a notebook [01\_build\_roms.ipynb](01_build_roms.ipynb).*
#
# The Regional Ocean Modeling System (ROMS) is a free-surface, terrain-following,
# primitive equations ocean model widely used by the scientific community for
# a diverse range of applications.
#
# ## Getting the source code
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

# The previous julia commands, are essentially the same as the following shell commands:
# ```bash
# mkdir ~/src/
# cd ~/src/
# git clone https://github.com/myroms/roms
# cd roms
# git checkout roms-4.1
# ```

# The output of the last command will tell you that `You are in 'detached HEAD' state.` (this is not an error).




# All files that are specific to a given implementation of ROMS will be
# saved in a different directory `modeldir`:

modeldir = expanduser("~/ROMS-implementation-test")
mkpath(modeldir);

# ## The header file

# Before we can compile ROMS we need to
# * activate diffent terms of the momentum equations
# * specify the schemes uses for advection, horizontal mixing,
#   type equation of state, ...
#
# The header file controls the compilation of the ROMS model by telling the
# compiler which part of the code needs to be compiled. If you modify this file,
# ROMS need to be recompiled.
#
# This header file should be named `yourdomain.h` (e.g. `liguriansea.h` for the Ligurian Sea)
# and created in the directory `ROMS-implementation-test`.
#
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

# ## Compiling the model code

# ROMS can use the MPI ([Message Passing Interface](https://en.wikipedia.org/wiki/Message_Passing_Interface)) or OpenMP ([Open Multi-Processing](https://en.wikipedia.org/wiki/OpenMP)) for parallelization (but not both at the same time):

use_mpi = false;
use_openmp = true;
## or
##use_mpi = true;
##use_openmp = false;
#
# ROMS can either be build (i.e. compiled) the shell script `build_roms.sh` or
# with the julia script `ROMS.build`.
#
# `roms_application` is a descriptive name of the domain or the particular application
# that the use can choose. We compile ROMS with the [GNU Fortran](https://en.wikipedia.org/wiki/GNU_Fortran) compiler using 8 jobs for compilation.

roms_application = "LigurianSea"
fortran_compiler = "gfortran"
jobs = 2
logfile = "roms_build.log"
logfile = stdout

ROMS.build(romsdir,roms_application,modeldir;
           stdout = logfile,
           jobs,
           fortran_compiler,
           use_openmp,
           use_mpi)

# The first and last 5 lines of this log file:

println.(collect(eachline(logfile))[1:5]);
println("...")
println.(collect(eachline(logfile))[end-5:end]);
