using Test
using ROMS
using Statistics
using Dates
using NCDatasets

@testset "Bathymetry" begin
    i = ROMS.findindex([10.,20.,30.],20.1)
    @test i == 2

    A = Float64.(reshape(1:16,(4,4)))
    A2 = ROMS.reduce_res(A,(2,2))
    A2r = mean(mean(reshape(A,(2,2,2,2)),dims=1),dims=3)[1,:,1,:]
    @test A2 ≈ A2r

    h = Float64.(reshape(1:64,(8,8)))
    hs = ROMS.smoothgrid(h,5.,0.2)
    @test hs[4,4] ≈ 26.6854178605039
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

    for Vstretching = 1:5
        for Vtransform = 1:2
            local z
            z = ROMS.set_depth(Vtransform, Vstretching, theta_s, theta_b, hc, N,  igrid, h;
                               zeta = zeta);
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


@testset "OGCM" begin
    outdir = joinpath(basedir,"OGCM")
    mkpath(outdir)

    ENV["JULIA_DEBUG"] = "ROMS"
    tr = [t0,t1]
    dataset = ROMS.CMEMS(cmems_username,cmems_password,outdir)

    ds_zeta = dataset[:sea_surface_height_above_geoid]
    filenames = download(ds_zeta,longitude=xr,latitude=yr,time=tr)

    sv,(sx,sy,st) = load(ds_zeta,longitude=xr,latitude=yr,time=tr)

    z = reshape(-10:0,(1,1,11))
    v = 2*z
    zi = reshape(-10:0,(1,1,11))

    vi = ROMS.interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);
    @test vi ≈ 2*zi

end



@testset "OGCM" begin
    datadir = joinpath(dirname(@__FILE__),"..","data")
    atmo_fname = joinpath(datadir,"era_operational_archive_2019.nc")
    filename_prefix = joinpath(datadir,"liguriansea_")
    domain_name = "Ligurian Sea Region"

    filenames = @time ROMS.prepare_ecmwf(atmo_fname,filename_prefix,domain_name)

    # compare

    basedir_ref = datadir

    for i = 1:length(filenames)
        Vname,fname = filenames[i]

        Tname = ROMS.roms_metadata[Vname].Tname
        output = split(replace(fname,filename_prefix => ""),"_")[1]

        fname_ref = joinpath(basedir_ref,"ls2_$(output)_era_2019.nc")

        dsout = Dataset(fname)
        ds_ref = Dataset(fname_ref)

        #@show ds_ref[Vname][1,1,1]
        #@show dsout[Vname][1,1,1]

        tindex = 1:length(ds_ref[Tname])
        #tindex = 1:2
        #@show ds_ref[Tname][1:2]
        #@show dsout[Tname][1:2]

        diff = ds_ref[Tname][tindex] - dsout[Tname][tindex]
        @test all(Dates.value.(diff) .== 0)

        diff = ds_ref[Vname][:,:,tindex] - dsout[Vname][:,:,tindex]

        #@show std(ds_ref[Vname][:,:,end])
        #@show std(dsout[Vname][:,:,end])
        @test maximum(abs.(diff)) < 1e-4

        close(dsout)
        close(ds_ref)
    end
end

@testset "Example setup" begin
    include("../src/ls2_config.jl")
    include("../src/gen_model_setup.jl")
end
