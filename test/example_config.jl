using Dates
using ROMS

# name of the domain
domain_name = "LS2v";

#bath_name = expanduser("~/Data/Bathymetry/combined_emodnet_bathymetry.nc")
#bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1.nc")
# longitude from 5°E to 15°E and latitude from 40°N to 45°N
bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1_ligurian_sea.nc")

if !isfile(bath_name)
    mkpath(dirname(bath_name))
    #download("http://modb.oce.ulg.ac.be/mediawiki/upload/OCEA0036/gebco_30sec_1.nc",bath_name)
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
grid_fname = joinpath(modeldir,domain_name * ".nc")

basedir = expanduser("~/ROMS-implementation-test")

# GCM interpolated on model grid
clim_filename =  joinpath(basedir,"clim2019.nc")

# initial conditions
ic_filename =  joinpath(basedir,"ic2019.nc")

# boundary conditions
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


# https://dox.ulg.ac.be/index.php/s/tbzNV9Z9UPtG5et/download
#ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_operational_archive_2018-12-01T00:00:00_2020-01-01T00:00:00.nc")

# ECMWF from 2019-01-01 03:00:00  to 2019-01-07 03:00:00
ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_sample_data.nc")

if !isfile(ecmwf_fname)
    mkpath(dirname(ecmwf_fname))
    download("https://dox.ulg.ac.be/index.php/s/8NJsCfk53fDFtbz/download",ecmwf_fname)
end


# CMEMS credentials

cmems_username = ENV["CMEMS_USERNAME"]
cmems_password = ENV["CMEMS_PASSWORD"]

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

service_id = "MEDSEA_ANALYSIS_FORECAST_PHY_006_013-TDS"
mapping = Dict(
    # var  product_id
    :sea_surface_height_above_geoid => ("zos","med00-cmcc-ssh-an-fc-d"),
    :sea_water_potential_temperature => ("thetao", "med00-cmcc-tem-an-fc-d"),
    :sea_water_salinity => ("so","med00-cmcc-sal-an-fc-d"),
    :eastward_sea_water_velocity => ("uo", "med00-cmcc-cur-an-fc-d"),
    :northward_sea_water_velocity => ("vo", "med00-cmcc-cur-an-fc-d"),
)

dataset = ROMS.CMEMS(cmems_username,cmems_password,service_id,mapping,outdir)

# take one extra day
tr = [t0-Dates.Day(1), t1+Dates.Day(1)]

ROMS.interp_clim(domain,clim_filename,dataset,tr)

ROMS.extract_ic(domain,clim_filename,ic_filename, t0);
ROMS.extract_bc(domain,clim_filename,bc_filename)


filename_prefix = joinpath(basedir,"liguriansea2019_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","
    lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,filename_prefix,domain_name)


romsdir = expanduser("~/src/roms")
simulationdir = joinpath(basedir,"Simulation1")

intemplate = joinpath(romsdir,"User","External","roms.in")
varname_template = joinpath(romsdir,"ROMS","External","varinfo.dat")

mkpath(simulationdir)
infile = joinpath(simulationdir,"roms.in")
varname = joinpath(simulationdir,"varinfo.dat")

cp(varname_template,varname; force=true)

forc_filenames  = unique(getindex.(forcing_filenames,2))

openbc = ROMS.openboundaries(domain.mask)

@show openbc
directions = ["west","south","east","north"]

whenopen(BC) = join(map(d -> (d in openbc ? BC : "Clo"),directions)," ")

# time step (seconds)
DT = 300.
# output frequency of ROMS in time steps
NHIS = round(Int,24*60*60 / DT)
NAVG = NHIS
# number of time steps
NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))

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
    "DT" => DT,
    "NHIS" => NHIS,
    "NAVG" => NAVG,
    "NTIMES" => NTIMES,
)

ROMS.infilereplace(intemplate,infile,substitutions)


# NBCFILES and NCLMFILES missing in roms.in but required

text = String(read(infile));
index = findfirst("BRYNAME",text)[1]
text = text[1:index-1] * "NBCFILES == 1\n     NCLMFILES == 1\n     " * text[index:end]
write(infile,text);


nothing
