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
basedir = joinpath(ENV["HOME"],"tmp-test2",domain_name);
mfs_filename =  joinpath(basedir,"mfs.mat"); # not used
clim_filename =  joinpath(basedir,"clim2016-eb.nc"); # GCM interpolated on model grid
ic_filename =  joinpath(basedir,"ic2016-eb.nc"); # initial conditions
bc_filename =  joinpath(basedir,"bc2016-eb.nc"); # boundary conditions


clim_filename =  joinpath(basedir,"clim2019.nc"); # GCM interpolated on model grid
ic_filename =  joinpath(basedir,"ic2019.nc"); # initial conditions
bc_filename =  joinpath(basedir,"bc2019.nc"); # boundary conditions
grid_fname = joinpath(modeldir,domain_name * ".nc")


# additional space in longitude and latitude to download from GCM
extra = .5;

# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)

atmo_model = "ecmwf";
ecmwf_fname = joinpath(ENV["HOME"],"tmp/LS2v/era_interim_2019.nc")
ecmwf_fname = expanduser("~/projects/Python/ROMS/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc")

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

t1 = DateTime(2018,12,1);
t0 = DateTime(2020,1,1);

cmems_username = ENV["CMEMS_USERNAME"]
cmems_password = ENV["CMEMS_PASSWORD"]


t0 = DateTime(2019,1,1);
t1 = DateTime(2019,1,2);

#include(joinpath(dirname(@__FILE__),"..","src","gen_model_setup.jl"))



# setup dir

mkpath(basedir);
mkpath(modeldir);


ROMS.generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax)


mkpath(basedir);
domain = ROMS.Grid(grid_fname,opt);

outdir = joinpath(basedir,"OGCM")
mkpath(outdir)


dataset = ROMS.CMEMS(cmems_username,cmems_password,outdir)

tr = [t0, t1]
time = tr[1]:bc_dt:tr[end]
ROMS.interp_clim(domain,clim_filename,dataset,tr)

ROMS.extract_ic(domain,clim_filename,ic_filename, t0);
ROMS.extract_bc(domain,clim_filename,bc_filename)


filename_prefix = joinpath(basedir,"liguriansea2019_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","
    lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,filename_prefix,domain_name)


romsdir = "/home/abarth/src/roms"
simulationdir = joinpath(basedir,"Simulation1")

intemplate = joinpath(romsdir,"ROMS","External","roms_upwelling.in")
varname_template = joinpath(romsdir,"ROMS","External","varinfo.dat")

mkpath(simulationdir)
infile = joinpath(simulationdir,"roms.in")
varname = joinpath(simulationdir,"varinfo.dat")
cp(varname_template,varname)

forc_filenames  = unique(getindex.(forcing_filenames,2))

openbc = ROMS.openboundaries(domain.mask)

@show ROMS.openboundaries(domain.mask)
directions = ["west","south","east","north"]


whenopen(BC) = join(map(d -> (d in openbc ? BC : "Clo"),directions)," ")

substitutions = Dict(
    "TITLE" => "My test",
    "TIME_REF" =>  "18581117",
    "VARNAME" => varname,
    "GRDNAME" => grid_fname,
    "ININAME" => ic_filename,
    "BRYNAME" => bc_filename,
    "CLMNAME" => clim_filename,
    "NFFILES" => length(forc_filenames),
    "FRCNAME" => join(forc_filenames,"  \\\n       "),
    "Vtransform" => opt.Vtransform,
    "Vstretching" => opt.Vstretching,
    "THETA_S" => opt.theta_s,
    "THETA_B" => opt.theta_b,
    "TCLINE" => opt.Tcline,
    "Lm" => size(domain.h,1)-2,
    "Mm" => size(domain.h,2)-2,
    "N" => opt.nlevels,
    "LBC(isFsur)" => whenopen("Cha"),
    "LBC(isUbar)" => whenopen("Fla"),
    "LBC(isVbar)" => whenopen("Fla"),
    "LBC(isUvel)" => whenopen("RadNud"),
    "LBC(isVvel)" => whenopen("RadNud"),
    "LBC(isMtke)" => whenopen("Rad"),
    "LBC(isTvar)" => whenopen("RadNud") * " \\\n" * whenopen("RadNud"),
)

ROMS.infilereplace(intemplate,infile,substitutions)
