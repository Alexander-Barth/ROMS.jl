# ## Preparation of the input file for ROMS
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
# This script can use multiple threads if [julia was started with multi-threading](https://docs.julialang.org/en/v1/manual/multi-threading/)
# (option `-t`/`--threads` or the environement variable `JULIA_NUM_THREADS`)

using Dates
using ROMS
using Downloads: download

# ### The model bathymetry

#bath_name = expanduser("~/Data/Bathymetry/combined_emodnet_bathymetry.nc")
#bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1.nc")
## longitude from 5°E to 15°E and latitude from 40°N to 45°N
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

# ### The boundary and initial conditions

## GCM interpolated on model grid (`CLMNAME` in roms.in)
clm_name =  joinpath(modeldir,"roms_clm_2023.nc")

## initial conditions (`ININAME` in roms.in)
ini_name =  joinpath(modeldir,"roms_ini_2023.nc")

## boundary conditions (`BRYNAME` in roms.in)
bry_name =  joinpath(modeldir,"roms_bry_2023.nc")

## temporary directory of the OGCM data
outdir = joinpath(modeldir,"OGCM")
mkpath(outdir)

# Locate the dataset at https://marine.copernicus.eu/

# Example:
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

tr = [t0-Dates.Day(1), t1+Dates.Day(1)]

ROMS.interp_clim(domain,clm_name,dataset,tr)

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

# ### The atmospheric forcings


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
