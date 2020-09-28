
# name of the domain
domain_name = 'choose_a_name';

bath_name = '/mnt/NasData/bathymetry/GEBCO/gebco_30sec_1.nc';

# range of longitude
xr = [104.3 107.4];
# range of latitude
yr = [-7.2 -4.5];

# reduce bathymetry in x and y direction
red = [2 2]; % units: resolution of bathymetry (1/120 degrees)


# enable (1) or disable (0) plots
do_plot = 1;

# maximum normalized topographic variations
rmax = 0.4;

# minimal depth
hmin = 2; % m

# name of folders
# file will be created, but the directories have to exist

modeldir = fullfile(getenv('HOME'),'Models',domain_name); % grid file
basedir = fullfile(getenv('HOME'),'tmp',domain_name);
clim_filename =  fullfile(basedir,'clim.nc'); % GCM interpolated on model grid
ic_filename =  fullfile(basedir,'ic.nc'); % initial conditions
bc_filename =  fullfile(basedir,'bc.nc'); % boundary conditions 


# additional space in longitude and latitude to download from GCM
extra = .5;

# Quadratic mean radius of Earth
R0 = 6372.795477598e3;

# model specific parameters
opt.Tcline = 50;   % m
opt.theta_s = 5;   % surface refinement
opt.theta_b = 0.4; % bottom refinement
opt.nlevels = 32;  % number of vertical levels
opt.Vtransform  = 2;
opt.Vstretching = 4;

opt.grid_fname = fullfile(modeldir,[domain_name '.nc']);

atmo_model = 'ecmwf';
ecmwf_fname = '/home/ulg/gher/abarth/tmp/LS2/netcdf-atls07-a562cefde8a29a7288fa0b8b7f9413f7-87tOkS.nc';
atmo_dt = 6/24; % 6 hours
atmo_dt = 3/24; % 3 hours

bc_model = 'hycom';
#bc_model = 'mfs';
bc_dt = 1; % 1 day


# change time range
# t0 start time
# t1 end time

t0 = mjd(2016,04,02)
t1 = mjd(2016,04,10)

# CMEMS credentials
cmems_username = 'your_username';
cmems_password = 'your_password';


