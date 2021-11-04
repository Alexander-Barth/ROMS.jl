using Test
using ROMS
using Statistics
using Dates
using NCDatasets
using PyPlot


@testset "Bathymetry" begin
    include("test_bathymetry.jl")
end

@testset "Vertical coordinate" begin
    theta_s =  5
    theta_b =  0.4
    Vtransform =  2
    Vstretching =  4

    hc = 50; N = 10; kgrid = 1;

    s_ref = [-1.0,  -0.9,  -0.8,  -0.7,  -0.6,  -0.5,  -0.4,  -0.3,  -0.2,  -0.1, 0.]
    C_ref = [-1.000000000000000, -0.648358846221329, -0.406115736567400, -0.247411330585220, -0.146615163717739, -0.083875204222181, -0.045433766989769, -0.022330684710868, -0.008987056975688, -0.002114389421634,  0.000000000000000]
    s,C = ROMS.stretching(Vstretching, theta_s, theta_b, hc, N, kgrid)
    @test s_ref ≈ s_ref
    @test C_ref ≈ C_ref

    for Vstretching = 1:5
        local s,C
        s,C = ROMS.stretching(Vstretching, theta_s, theta_b, hc, N, kgrid)
    end

    hc = 50
    theta_s =  5
    theta_b =  0.4
    N = 10
    Vtransform =  2
    Vstretching =  4
    igrid = 1
    h = 100*ones(20,20)
    zeta = zeros(20,20);
    z = ROMS.set_depth(Vtransform, Vstretching, theta_s, theta_b, hc, N,  igrid, h;
                       zeta = zeta);

    z_ref = [-85.6156490828721, -62.6705707676990, -46.2021211503469, -34.4112258271638, -25.7652178611963, -19.1514577479149, -13.8252107015086, -9.31253620976400, -5.32532093820320,  -1.70137067316492]

    @test z[10,10,:] ≈ z_ref

    for igrid = 1:5
        for Vstretching = 1:5
            for Vtransform = 1:2
                local z
                z = ROMS.set_depth(Vtransform, Vstretching, theta_s, theta_b, hc, N,  igrid, h;
                                   zeta = zeta);
            end
        end
    end
end


@testset "projection" begin
    x,y = ROMS.sg_mercator(5,50)
    x_ref =  0.0872664625997165
    y_ref =  1.01068318868302

    @test x_ref ≈ x
    @test y_ref ≈ y_ref
end


@testset "staggering" begin
    x_r = randn(40,42)
    x_u,x_v,x_psi = @time ROMS.stagger(x_r);
    @test x_u[1,1] ≈ (x_r[1,1] + x_r[2,1])/2
    @test x_v[1,1] ≈ (x_r[1,1] + x_r[1,2])/2
    @test x_psi[1,1] ≈ (x_r[1,1] + x_r[1,2] + x_r[2,1] + x_r[2,2])/4

    x_r = trues(40,42)
    x_u,x_v,x_psi = @time ROMS.stagger_mask(x_r);
    @test size(x_u,1) == size(x_r,1)-1
    @test size(x_u,2) == size(x_r,2)
end


@testset "Interpolation" begin
    z = reshape(-10:0,(1,1,11))
    v = 2*z
    zi = reshape(-10:0,(1,1,11))

    vi = ROMS.interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);
    @test vi ≈ 2*zi
end

@testset "Nudging coefficient" begin
    include("test_nudge.jl")
end


@testset "Forcing" begin
    # reference values from https://en.wikipedia.org/w/index.php?title=Vapour_pressure_of_water&oldid=987479989
    @test ROMS.vapor_pressure(20) ≈ 23.388 rtol=0.01
    @test ROMS.vapor_pressure_Buck(20) ≈ 23.388 rtol=0.01

    include("test_forcing.jl")
end


@testset "ROMS run" begin
    if Sys.islinux() && haskey(ENV,"ROMS_PASSWORD")
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
