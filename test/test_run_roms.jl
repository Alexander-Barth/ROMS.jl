using ROMS
using Test
using NCDatasets

if Sys.islinux() && haskey(ENV,"ROMS_PASSWORD")
    withenv("OPAL_PREFIX" => nothing) do
        setupscript = joinpath(@__DIR__,"compile_run_ROMS.sh")
        run(`$setupscript`)
        include("example_config.jl")
        include("example_config_next.jl")
        romsbin = expanduser("~/ROMS-implementation-test/romsM")

        cd(expanduser("~/ROMS-implementation-test/Simulation1")) do
            run(`mpirun -np 1 $romsbin roms.in`)
            @test isfile("roms_his.nc")
        end
    end

    ds = NCDataset(grid_fname);
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
end
