
# # Preparation of the input files for ROMS
#
#md # *The code here is also available as a notebook [02\_prep\_roms.ipynb](02_prep_roms.ipynb).*
#
# ROMS needs several input files in the NetCDF format, in paricular:
#
# * the model grid
# * the initial conditions
# * the boundary conditions
# * the atmospheric forcing fields
#
# Optionally
# * the climatology file
# * the field defining the nudging strength
#
#
# This script can use multiple threads if [julia was started with multi-threading](https://docs.julialang.org/en/v1/manual/multi-threading/)
# (option `-t`/`--threads` or the environement variable `JULIA_NUM_THREADS`)

using Dates
using ROMS
using ROMS: whenopen
using Downloads: download

# ## The model bathymetry


# While the full [GEBCO bathymetry](https://dox.ulg.ac.be/index.php/s/iEh7ompNdj8AN2p/download)
# is relatively large, where use here a subset of the global bathymetry to
# reduce the downloading time.
# (longitude from 5°E to 15°E and latitude from 40°N to 45°N)
bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1_ligurian_sea.nc")

if !isfile(bath_name)
    mkpath(dirname(bath_name))
    download("https://dox.ulg.ac.be/index.php/s/piwSaFP3nhM8jSD/download",bath_name)
end

# The time range for the simulation:
# * `t0` start time
# * `t1` end time

t0 = DateTime(2023,1,1);
t1 = DateTime(2023,1,4);

# Define the bounding box the of the grid

## range of longitude
xr = [7.6, 12.2];

## range of latitude
yr = [42, 44.5];

## reduce bathymetry in x and y direction
red = (4, 4)

## maximum normalized topographic variations
rmax = 0.4;

## minimal depth
hmin = 2; # m

## name of folders and files
modeldir = expanduser("~/ROMS-implementation-test")

## The model grid (`GRDNAME` in roms.in)
grd_name = joinpath(modeldir,"roms_grd_liguriansea.nc")

# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)

# setup dir

mkpath(modeldir);

domain = ROMS.generate_grid(grd_name,bath_name,xr,yr,red,opt,hmin,rmax);

@info "domain size $(size(domain.mask))"

# ## The boundary and initial conditions

## GCM interpolated on model grid (`CLMNAME` in roms.in)
clm_name =  joinpath(modeldir,"roms_clm_2023.nc")

## initial conditions (`ININAME` in roms.in)
ini_name =  joinpath(modeldir,"roms_ini_2023.nc")

## boundary conditions (`BRYNAME` in roms.in)
bry_name =  joinpath(modeldir,"roms_bry_2023.nc")

## temporary directory of the OGCM data
outdir = joinpath(modeldir,"OGCM")
mkpath(outdir)

# * For CMEMS boundary conditions (https://marine.copernicus.eu/):
#    * You may need to adapt the CMEMS `product_id` and `mapping` (if the model domain is outside of the Mediterranean Sea)
#    * Data will be downloaded and saved in NetCDF by "chunks" of 60 days in the folder `OGCM` under the content of the variable `basedir`
#    * You need to remove the files in this directory if you rerun the script with a different time range.
#
# Here we use the following dataset:
# https://doi.org/10.25423/CMCC/MEDSEA_MULTIYEAR_PHY_006_004_E3R1

product_id = "MEDSEA_MULTIYEAR_PHY_006_004"

# mapping the variable (CF names) with the CMEMS `dataset_id`

mapping = Dict(
    :sea_surface_height_above_geoid => "med-cmcc-ssh-rean-d",
    :sea_water_potential_temperature => "med-cmcc-tem-rean-d",
    :sea_water_salinity => "med-cmcc-sal-rean-d",
    :eastward_sea_water_velocity => "med-cmcc-cur-rean-d",
    :northward_sea_water_velocity => "med-cmcc-cur-rean-d",
)

dataset = ROMS.CMEMS_zarr(product_id,mapping,outdir, time_shift = 12*60*60)

# Extent the time range by one extra day

ROMS.interp_clim(domain,clm_name,dataset,[t0-Dates.Day(1), t1+Dates.Day(1)])

ROMS.extract_ic(domain,clm_name,ini_name, t0);
ROMS.extract_bc(domain,clm_name,bry_name)


# nudging coefficient (`NUDNAME`)

tscale = 7; # days
alpha = 0.3;
halo = 2;
Niter = 50
max_tscale = 5e5

nud_name = joinpath(modeldir,"roms_nud_$(tscale)_$(Niter).nc")
tracer_NudgeCoef = ROMS.nudgecoef(domain,nud_name,alpha,Niter,
          halo,tscale; max_tscale = max_tscale);

# ## The atmospheric forcings


# Prepare atmospheric forcings (`FRCNAME`)

ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_operational_archive_2022-12-01_2024-02-01.nc")

if !isfile(ecmwf_fname)
    mkpath(dirname(ecmwf_fname))
    download("https://data-assimilation.net/upload/OCEA0036/ecmwf_operational_archive_2022-12-01_2024-02-01.nc",ecmwf_fname)
end

frc_name_prefix = joinpath(modeldir,"roms_frc_2023_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
    "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

## forcing_filenames corresponds to `FRCNAME` in roms.in
forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,frc_name_prefix,domain_name)


fn(name) = basename(name) # use relative file path
## fn(name) = name         # use absolute file path

println()
println("The created netCDF files are in $modeldir.");
println("The following information has to be added to roms.in. A template of this file is")
println("provided in the directory User/External of your ROMS source code")
println("You can also use relative or absolute file names.")
println()
println("! grid file ")
println("     GRDNAME == $(fn(grd_name))")
println()
println("! initial conditions")
println("     ININAME == $(fn(ini_name))")
println()
println("! boundary conditions")
println("     NBCFILES == 1")
println("     BRYNAME == $(fn(bry_name))")
println()
println("! climatology or large-scale circulatio model")
println("     NCLMFILES == 1")
println("     CLMNAME == $(fn(clm_name))")
println()
println("! nudging coefficients file (optional)")
println("     NUDNAME == $(fn(nud_name))")
println()
println("! forcing files")
println("     NFFILES == $(length(Vnames))")

for i in 1:length(Vnames)
    if i == 1
        print("     FRCNAME == ")
    else
        print("                ")
    end
    print("$(fn(frc_name_prefix))$(Vnames[i]).nc")
    if i < length(Vnames)
        print(" \\")
    end
    println()
end

# Check the resulting files such as bathymetry, initial conditions,
# boundary conditions, interpolated model (`clim` file) and visualizing them.

# ## Configuration files
#
# Beside the created NetCDF files, ROMS needs two configuration files
# (`roms.in` and `varinfo.yaml`)

romsdir = expanduser("~/src/roms")
modeldir = expanduser("~/ROMS-implementation-test")
simulationdir = joinpath(modeldir,"Simulation1")
mkpath(simulationdir)

frc_name = joinpath.(modeldir,sort(filter(startswith("roms_frc"),readdir(modeldir))))

# Copy `varinfo.yaml` from `~/src/roms/ROMS/External/varinfo.yaml` in your
# directory for your simulation (e.g. `ROMS-implementation-test`).
# This file does not need to be changed.

var_name_template = joinpath(romsdir,"ROMS","External","varinfo.yaml")
var_name = joinpath(simulationdir,"varinfo.yaml")
cp(var_name_template,var_name; force=true)

# Load the ROMS grid

domain = ROMS.Grid(grd_name);

# We use `roms.in` from `~/src/roms/User/External/roms.in` as a template

intemplate = joinpath(romsdir,"User","External","roms.in")
infile = joinpath(simulationdir,"roms.in")

# This file is typicall edited with a text editor (when editing this file, do not use "tabs".).
# Check the glossary at the end of this file for the meaning of the keys that we will change.
#
# Here we edit the file programmatically. These are the changes that are done
# in the following:
#
#  * adapt `MyAppCPP` and change it to `LIGURIANSEA`
#
#  * adapt file names `VARNAME`, `GRDNAME`, `ININAME`, `BRYNAME`, `CLMNAME`, `FRCNAME` and `NFFILES` (`varinfo.yaml`, `LS2v.nc`, `ic2019.nc`, `bc2019.nc`, `clim2019.nc`, `liguriansea2019_*.nc`, `*` means the different variables). `NFFILES` is the number of forcing files.
#
#  * change `Lm`, `Mm` and `N` based on the dimensions of your grid (make sure to read the glossary for these variable in `roms.in`)
#
#  * read the desciption about "lateral boundary conditions" and adapt boundaries `LBC`:
#     * use closed (`Clo`) for boundaries without sea-point
#     * for open boundaries:
#        * free-surface: Chapman implicit (`Cha`)
#        * 2D U/V-momentum: Flather (`Fla`)
#        * 3D U/V-momentum, temperature, salinity: Radiation with nudging (`RadNud`)
#        * mixing TKE: Radiation (`Rad`)
#
#  * set the starting time and time reference
# ```
# DSTART = ...
# TIME_REF =  18581117
# ```
#
# where `DSTART` is here the number of days since 1858-11-17 or November 17, 1858 (see also [modified Julia day](https://en.wikipedia.org/wiki/Julian_day#Variants)) of the start of the model simulation (`t0` in the julia script). For instance the number of days since 2014-01-01 (year-month-day) can be computed by of following commands in Julia:
#
# ```julia
# using Dates
# Date(2020,1,1) - Date(1858,11,17)
# ```
#
# The inverse operation can be done with:
#
# ```julia
# using Dates
# Date(1858,11,17) + Day(58849)
# ```
#
# You can use `DateTime` if you want to specify hour, minutes or seconds.
#
# * Adapt the length of a time step `DT` (in seconds) and number of time steps `NTIMES`
# * `DT` can be 300 seconds
# * Initially we choose:
#     * `NTIMES` -> number of time step corresponding to 2 days (e.g. `2*24*60*60/DT` where `DT` is the time steps in seconds)
#     * `NHIS`, `NAVG`-> number of time steps corresponding to 1 hour
#     * `NRST` -> number of time steps correspond to 1 hour


## time step (seconds)
DT = 300.
## output frequency of ROMS in time steps
NHIS = round(Int,24*60*60 / DT)
NRST = NAVG = NHIS

## number of time steps
t0 = DateTime(2023,1,1);
t1 = DateTime(2023,1,4);
NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))

# How many CPU cores does your machine have? You can use the command `top` in a shell terminal followed by `1`.
# The number of CPU cores should be `NtileI` * `NtileJ`.
# The parameters `NtileI` and `NtileJ` are defined in `roms.in`.

NtileI = 1
NtileJ = 1

substitutions = Dict(
    "TITLE" => "My test",
    "NtileI" => NtileI,
    "NtileJ" => NtileJ,
    "TIME_REF" => "18581117",
    "VARNAME" => var_name,
    "GRDNAME" => grd_name,
    "ININAME" => ini_name,
    "BRYNAME" => bry_name,
    "CLMNAME" => clm_name,
    "NFFILES" => length(frc_name),
    "FRCNAME" => join(frc_name,"  \\\n       "),
    "Vtransform" => domain.Vtransform,
    "Vstretching" => domain.Vstretching,
    "THETA_S" => domain.theta_s,
    "THETA_B" => domain.theta_b,
    "TCLINE" => domain.Tcline,
    "Lm" => size(domain.h,1)-2,
    "Mm" => size(domain.h,2)-2,
    "N" => domain.nlevels,
    "LBC(isFsur)" => whenopen(domain,"Cha"),
    "LBC(isUbar)" => whenopen(domain,"Fla"),
    "LBC(isVbar)" => whenopen(domain,"Fla"),
    "LBC(isUvel)" => whenopen(domain,"RadNud"),
    "LBC(isVvel)" => whenopen(domain,"RadNud"),
    "LBC(isMtke)" => whenopen(domain,"Rad"),
    "LBC(isTvar)" => whenopen(domain,"RadNud") * " \\\n" * whenopen(domain,"RadNud"),
    "DT" => DT,
    "NHIS" => NHIS,
    "NAVG" => NAVG,
    "NRST" => NRST,
    "NTIMES" => NTIMES,
    "NUDNAME" => nud_name,
    "TNUDG" => "10.0d0 10.0d0",
    "LtracerCLM" => "T T",
    "LnudgeTCLM" => "T T",
    "OBCFAC" => 10.0,
)

ROMS.infilereplace(intemplate,infile,substitutions)

# Always make make sure that `THETA_S`, `THETA_B`, `TCLINE`, `Vtransform` and `Vstretching` match the values in your julia script.
# We can review the changes with the shell command:
# ```bash
# diff -u --color ~/src/roms/User/External/roms.in roms.in
# ```
