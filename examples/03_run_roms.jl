# # Run ROMS
#
#md # *The code here is also available as a notebook [03\_run\_roms.ipynb](03_run_roms.ipynb).*
#
# Run ROMS with 4 CPUs splitting the domain in 2 by 2 tiles

using Dates
using ROMS

# Now we are ready to run the model:

modeldir = expanduser("~/ROMS-implementation-test")
simulationdir = joinpath(modeldir,"Simulation1");

# ## Run ROMS from julia
#
# `NtileI` and `NtileJ` must match the values in the
# roms.in file.

NtileI = 1
NtileJ = 1
np = NtileI*NtileJ

use_openmp = true
logfile = "roms.out"

cd(simulationdir) do
    withenv("OPAL_PREFIX" => nothing) do
        ROMS.run_model(modeldir,"roms.in"; use_openmp, np, stdout = logfile)
    end
end;

# If you run into a problem, please first read the error message
# carefully to get some indicaton what is wrong.
#
# The ROMS outputs are the files `roms_his.nc` and `roms_avg.nc`.

# Note that the usual method to run ROMS is from the command line.
#
# ## Run ROMS in serial
#
# For example the serial binary `romsS` (without MPI and OpenMP) can be run as:
#
# ```bash
# ./romsS < roms.in | tee roms.out
# ```
#
#
# ## Run ROMS in parallel
#
# Make sure to activate MPI or OpenMP and recompile ROMS if necessary
# With MPI:
#
# ```bash
# mpirun -np 4 ./romsM  roms.in | tee roms.out
# ```
#
# where 4 is the number of cores to use. To use 4 CPUs, you need to set `NtileI` to 2 and `NtileJ` to 2.
#
# With OpenMP:
#
# ```bash
# OMP_NUM_THREADS=4 ./romsO < roms.out | tee roms.out
# ```
#
# With the command `tee` the normal screen output will be place in the file `roms.out` but still be printed on the screen.

# ## Interpreting ROMS output

# * Check minimum and maximum value of the different parameters
# ```
#  NLM: GET_STATE - Read state initial conditions,             t = 57235 00:00:00
#                    (Grid 02, File: roms_nest_his.nc, Rec=0182, Index=1)
#                 - free-surface
#                    (Min = -4.63564634E-01 Max = -3.63838434E-01)
# ```

# * The barotropic, baroclinic and Coriolis Courant number should be smaller than 1

# ```
#  Minimum barotropic Courant Number =  2.09670689E-02
#  Maximum barotropic Courant Number =  5.56799674E-01
#  Maximum Coriolis   Courant Number =  1.71574766E-03
# ```

# * Information
#     * energy (kinetic, potential, total) and volume
#     * maximum Courant number

# ```
#    STEP   Day HH:MM:SS  KINETIC_ENRG   POTEN_ENRG    TOTAL_ENRG    NET_VOLUME  Grid
#           C => (i,j,k)       Cu            Cv            Cw         Max Speed

#  346200 57235 00:00:00  2.691184E-03  1.043099E+04  1.043099E+04  6.221264E+13  01
#           (079,055,30)  9.266512E-02  4.949213E-02  0.000000E+00  1.081862E+00
# ```


# Plot some variables like sea surface height and sea surface temperature at the beginning and the end of the simulation.
# In Julia, force figure 1 and to 2 to have the same color-bar.
#
# ```julia
# figure(); p1 = pcolor(randn(3,3)); colorbar()
# figure(); p2 = pcolor(randn(3,3)); colorbar()
# p2.set_clim(p1.get_clim())
# ```
#
# * If everything runs fine,
#     * is the model still stable with a longer time steps (`DT`) ?
#     * increase the number of time steps (`NTIMES`)
#     * possibly adapt the frequency at which you save the model results (`NHIS`, `NAVG`,`NRST`)
