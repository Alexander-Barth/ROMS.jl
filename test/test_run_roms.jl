using ROMS
using Test
using NCDatasets

include("../examples/build_roms.jl")
include("example_config.jl")
include("../examples/run_roms.jl")


ds = NCDataset(grd_name);
lon_rho = ds["lon_rho"][:,:]
lat_rho = ds["lat_rho"][:,:]
x_rho = ds["x_rho"][:,:]
y_rho = ds["y_rho"][:,:]
pn = ds["pn"][:,:]
pm = ds["pm"][:,:]

# Mercator scale factor
# https://en.wikipedia.org/w/index.php?title=Mercator_projection&oldid=1227033338
factor = 1/cosd((lat_rho[2,1] + lat_rho[1,1])/2)
@test (x_rho[2,1] - x_rho[1,1])/factor ≈ 1/pm[1,1]

factor = 1/cosd((lat_rho[1,2] + lat_rho[1,1])/2)
@test (y_rho[1,2] - y_rho[1,1])/factor ≈ 1/pn[1,1] atol=1e-2
