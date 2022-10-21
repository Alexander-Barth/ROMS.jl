using Test
using ROMS
using Statistics
using Dates
using NCDatasets
using Downloads: download

@testset "Bathymetry" begin
    include("test_bathymetry.jl")
end

@testset "Vertical coordinate" begin
    include("test_vertical_coord.jl")
end

@testset "projection" begin
    include("test_projection.jl")
end

@testset "staggering" begin
    include("test_staggering.jl")
end

@testset "Interpolation" begin
    include("test_interpolation.jl")
end

@testset "Nudging coefficient" begin
    include("test_nudge.jl")
end

@testset "Forcing" begin
    include("test_forcing.jl")
    include("test_gfs.jl")
    include("test_cmems.jl")
end

@testset "ROMS run" begin
    include("test_run_roms.jl")
end
