using ROMS
using Test

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
end
