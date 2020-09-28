using Dates
using PyPlot
ioff()

# name of the domain
domain_name = "LS2v";

bath_name = "/mnt/data1/abarth/combined_emodnet_bathymetry.nc"

# range of longitude
xr = [7.6, 12.2];
# range of latitude
yr = [42, 44.5];

# reduce bathymetry in x and y direction
red = (2, 2); # units: resolution of bathymetry (1/120 degrees)
red = (8, 8); # units: resolution of bathymetry (1/480 degrees)


# enable (true) or disable (false) plots
do_plot = false;

# maximum normalized topographic variations
rmax = 0.4;

# minimal depth
hmin = 2; # m

# name of folders
modeldir = joinpath(ENV["HOME"],"Models-tmp",domain_name); # grid file
basedir = joinpath(ENV["HOME"],"tmp-test",domain_name);
mfs_filename =  joinpath(basedir,"mfs.mat"); # not used
clim_filename =  joinpath(basedir,"clim2016-eb.nc"); # GCM interpolated on model grid
ic_filename =  joinpath(basedir,"ic2016-eb.nc"); # initial conditions
bc_filename =  joinpath(basedir,"bc2016-eb.nc"); # boundary conditions


clim_filename =  joinpath(basedir,"clim2019-eb.nc"); # GCM interpolated on model grid
ic_filename =  joinpath(basedir,"ic2019-eb.nc"); # initial conditions
bc_filename =  joinpath(basedir,"bc2019-eb.nc"); # boundary conditions


# additional space in longitude and latitude to download from GCM
extra = .5;

# Quadratic mean radius of Earth
R0 = 6372.795477598e3;

# model specific parameters
opt = Dict(
    :Tcline => 50,   # m
    :theta_s => 5,   # surface refinement
    :theta_b => 0.4, # bottom refinement
    :nlevels => 32,  # number of vertical levels
    :Vtransform  => 2,
    :Vstretching => 4,
    :grid_fname => joinpath(modeldir,domain_name * ".nc")
)

atmo_model = "ecmwf";
ecmwf_fname = joinpath(ENV["HOME"],"tmp/LS2v/era_interim_2019.nc")

atmo_filename = joinpath(basedir,"atmo-" * atmo_model * "2019.nc");

atmo_dt = 6/24; # 6 hours
atmo_dt = 3/24; # 3 hours

bc_model = "hycom";
bc_model = "mfs";
bc_dt = Dates.Day(1); # 1 day


# change time range
# t0 start time
# t1 end time

t0 = DateTime(2019,1,1);
t1 = DateTime(2019,1,2);
#t1 = DateTime(2019,1,10);
#t1 = DateTime(2020,1,1);


cmems_username = ENV["CMEMS_USERNAME"]
cmems_password = ENV["CMEMS_PASSWORD"]
