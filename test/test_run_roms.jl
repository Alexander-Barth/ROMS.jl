using ROMS
using Test
using NCDatasets
using Downloads: download

modeldir = expanduser("~/ROMS-implementation-test")
mkpath(modeldir)

romsdir = expanduser("~/src/roms")
if !isdir(romsdir)
    cd(dirname(romsdir)) do
        run(`git clone https://github.com/myroms/roms`)
        cd("roms") do
            run(`git checkout roms-4.1`)
        end
    end
end

download("https://dox.ulg.ac.be/index.php/s/9yqxI4tp5hNr2Sg/download",
         joinpath(modeldir,"liguriansea.h"))

use_mpi = true;
#use_mpi = false;
#use_openmp = true;
use_openmp = false;

roms_application = "LigurianSea"
fortran_compiler = "gfortran"
jobs = 8

ROMS.build(romsdir,roms_application,modeldir;
           jobs,
           fortran_compiler,
           use_openmp,
           use_mpi)

include("example_config.jl")
include("example_config_next.jl")

cd(expanduser("~/ROMS-implementation-test/Simulation1")) do
    withenv("OPAL_PREFIX" => nothing) do
        ROMS.run_model(modeldir,"roms.in"; use_mpi, use_openmp)
    end
    @test isfile("roms_his.nc")
end

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
