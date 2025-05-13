using ROMS
using Test
using Downloads: download

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

grid_fname = tempname()

# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)

ROMS.generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax);
domain = ROMS.Grid(grid_fname,opt);

tscale = 5; # days
alpha = 0.3;
halo = 1;
Niter = 20
max_tscale = 5e5

nud_name = tempname()
tracer_NudgeCoef = ROMS.nudgecoef(domain,nud_name,alpha,Niter,
          halo,tscale; max_tscale = max_tscale);
#@show tracer_NudgeCoef[1:5,10,end]
@test tracer_NudgeCoef[1,10,end] ≈ 1/tscale
@test isfile(nud_name)
