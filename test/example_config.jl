using Dates
using ROMS
using Downloads: download

# name of the domain
domain_name = "LS2v";

#bath_name = expanduser("~/Data/Bathymetry/combined_emodnet_bathymetry.nc")
#bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1.nc")
# longitude from 5°E to 15°E and latitude from 40°N to 45°N
bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1_ligurian_sea.nc")

if !isfile(bath_name)
    mkpath(dirname(bath_name))
    download("https://dox.ulg.ac.be/index.php/s/piwSaFP3nhM8jSD/download",bath_name)
end

# range of longitude
xr = [7.6, 12.2];

# range of latitude
yr = [42, 44.5];

# reduce bathymetry in x and y direction
red = (4, 4)

# maximum normalized topographic variations
rmax = 0.4;

# minimal depth
hmin = 2; # m

# name of folders and files

# grid file
modeldir = expanduser("~/ROMS-implementation-test")

# This file corresponds to GRDNAME in roms.in
grid_fname = joinpath(modeldir,domain_name * ".nc")

basedir = expanduser("~/ROMS-implementation-test")

# GCM interpolated on model grid (CLMNAME)
clim_filename =  joinpath(basedir,"clim2019.nc")

# initial conditions (ININAME in roms.in)
ic_filename =  joinpath(basedir,"ic2019.nc")

# boundary conditions (BRYNAME in roms.in)
bc_filename =  joinpath(basedir,"bc2019.nc")

# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)

# ECMWF from 2018-12-01 to 2020-01-01 is available at
# https://dox.ulg.ac.be/index.php/s/tbzNV9Z9UPtG5et/download
#ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc")

# ECMWF from 2019-01-01 03:00:00  to 2019-01-07 03:00:00
ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_sample_data.nc")

if !isfile(ecmwf_fname)
    mkpath(dirname(ecmwf_fname))
    download("https://dox.ulg.ac.be/index.php/s/8NJsCfk53fDFtbz/download",ecmwf_fname)
end

# change time range
# t0 start time
# t1 end time

t0 = DateTime(2019,1,2);
t1 = DateTime(2019,1,4);

# setup dir

mkpath(basedir);
mkpath(modeldir);

ROMS.generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax);

mkpath(basedir);
domain = ROMS.Grid(grid_fname,opt);

@info "domain size $(size(domain.mask))"

outdir = joinpath(basedir,"OGCM")
mkpath(outdir)

# Locate the dataset at https://marine.copernicus.eu/

# Example:
# https://doi.org/10.25423/CMCC/MEDSEA_MULTIYEAR_PHY_006_004_E3R1

product_id = "MEDSEA_MULTIYEAR_PHY_006_004"

mapping = Dict(
    # var  dataset_id
    :sea_surface_height_above_geoid => "med-cmcc-ssh-rean-d",
    :sea_water_potential_temperature => "med-cmcc-tem-rean-d",
    :sea_water_salinity => "med-cmcc-sal-rean-d",
    :eastward_sea_water_velocity => "med-cmcc-cur-rean-d",
    :northward_sea_water_velocity => "med-cmcc-cur-rean-d",
)

dataset = ROMS.CMEMS_zarr(product_id,mapping,outdir, time_shift = 12*60*60)

# take one extra day
tr = [t0-Dates.Day(1), t1+Dates.Day(1)]

ROMS.interp_clim(domain,clim_filename,dataset,tr)

ROMS.extract_ic(domain,clim_filename,ic_filename, t0);
ROMS.extract_bc(domain,clim_filename,bc_filename)

# Prepare atmospheric forcings

filename_prefix = joinpath(basedir,"liguriansea2019_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
    "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

# forcing_filenames corresponds to FRCNAME in roms.in
forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,filename_prefix,domain_name)


# nudging coefficient

tscale = 7; # days
alpha = 0.3;
halo = 2;
Niter = 50
max_tscale = 5e5

nudge_filename = joinpath(basedir,"roms_nud_$(tscale)_$(Niter).nc")
tracer_NudgeCoef = ROMS.nudgecoef(domain,nudge_filename,alpha,Niter,
          halo,tscale; max_tscale = max_tscale)
