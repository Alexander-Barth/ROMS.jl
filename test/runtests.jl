
using Test
using ROMS
using Statistics
using Dates

#=
i = ROMS.findindex([10.,20.,30.],20.1)
@test i == 2

A = Float64.(reshape(1:16,(4,4)))
A2 = ROMS.reduce_res(A,(2,2))
A2r = mean(mean(reshape(A,(2,2,2,2)),dims=1),dims=3)[1,:,1,:]
@test A2 ≈ A2r

h = Float64.(reshape(1:64,(8,8)))
hs = ROMS.smoothgrid(h,5.,0.2)
@test hs[4,4] ≈ 26.6854178605039

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

@testset "set_depth" begin
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


x,y = ROMS.sg_mercator(5,50)
x_ref =  0.0872664625997165
y_ref =  1.01068318868302

@test x_ref ≈ x
@test y_ref ≈ y_ref


x_r = randn(40,42)
x_u,x_v,x_psi = @time ROMS.stagger(x_r);
@test x_u[1,1] ≈ (x_r[1,1] + x_r[2,1])/2
@test x_v[1,1] ≈ (x_r[1,1] + x_r[1,2])/2
@test x_psi[1,1] ≈ (x_r[1,1] + x_r[1,2] + x_r[2,1] + x_r[2,2])/4

x_r = trues(40,42)
x_u,x_v,x_psi = @time ROMS.stagger_mask(x_r);
@test size(x_u,1) == size(x_r,1)-1
@test size(x_u,2) == size(x_r,2)
=#
#=

outdir = joinpath(basedir,"OGCM")
mkpath(outdir)

ENV["JULIA_DEBUG"] = "ROMS"
tr = [t0,t1]
dataset = ROMS.CMEMS(cmems_username,cmems_password,outdir)

ds_zeta = dataset[:sea_surface_height_above_geoid]
filenames = download(ds_zeta,longitude=xr,latitude=yr,time=tr)

sv,(sx,sy,st) = load(ds_zeta,longitude=xr,latitude=yr,time=tr)
=#

z = reshape(-10:0,(1,1,11))
v = 2*z
zi = reshape(-10:0,(1,1,11))

vi = ROMS.interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);
@test vi ≈ 2*zi

#include("../src/ls2_config.jl")
#include("../src/gen_model_setup.jl")

"""
    e = vapor_pressure(T)

actual vapor pressure in hPa (millibars) from dewpoint temperature `T` in degree Celsius
using [1]. If `T` is the air temperature, then  `e` is the saturated vapor
pressure.

[1] https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
vapor_pressure(T) = 6.11 * 10.0 ^ (7.5 * T / (237.7 + T))



"""

https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
function relative_humidity(temperature_2m_C,dew_temperature_2m_C)
    100 * vapor_pressure(dew_temperature_2m_C) / vapor_pressure(temperature_2m_C)
end


using NCDatasets, DataStructures


function prep_field(atmo_fname,filename_prefix,domain_name)

    ds_ecmwf = NCDataset(atmo_fname)
    lon = ds_ecmwf["longitude"][:]
    lat = ds_ecmwf["latitude"][:]
    time = ds_ecmwf["time"][:]

    fliplat = lat[2] < lat[1]
    if fliplat
        lat = reverse(lat)
    end

    flag_cartesian = 0
    flag_spherical = 1
    time_origin = DateTime(1858,11,17)

    F = [
        (
            Vname = "sustr",
            ECMWFname = "ewss",
            accumulation = true,
            output = "sms",
            scale = 1/(3*60*60), # 3 hours accumulation
        ),
        (
            Vname  = "svstr",
            ECMWFname = "nsss",
            accumulation = true,
            output = "sms",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "shflux",
            ECMWFname = "",
            accumulation = true,
            output = "shflux",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "swflux",
            ECMWFname = "",
            accumulation = true,
            output = "swflux",
            scale  = 100.0/(3*3600.0)*(24*3600.0),
        ),
        (
            Vname  = "swrad",
            ECMWFname = "ssr",
            accumulation = true,
            output = "swrad",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "Uwind",
            ECMWFname = "u10",
            accumulation = false,
            output = "wind",
            scale  = 1.0,
        ),
        (
            Vname  = "Vwind",
            ECMWFname = "v10",
            accumulation = false,
            output = "wind",
            scale  = 1.0,
        ),
        (
            Vname  = "lwrad",
            ECMWFname = "str",
            accumulation = true,
            output = "lwrad",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "lwrad_down",
            ECMWFname = "strd",
            accumulation = true,
            output = "lwrad",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "latent",
            ECMWFname = "slhf",
            accumulation = true,
            output = "latent",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "sensible",
            ECMWFname = "sshf",
            accumulation = true,
            output = "sensible",
            scale  = 1.0/(3*3600.0),
        ),
        (
            Vname  = "cloud",
            ECMWFname = "tcc",
            accumulation = false,
            output = "cloud",
            scale  = 1.0,
        ),
        (
            Vname  = "rain",
            ECMWFname = "tp",
            accumulation = true,
            output = "rain",
            scale  = 1000.0/(3*3600.0),
        ),
        (
            Vname  = "Pair",
            ECMWFname = "msl",
            accumulation = false,
            output = "Pair",
            scale  = 0.01,
        ),
        (
            Vname  = "Tair",
            ECMWFname = "t2m",
            accumulation = false,
            output = "Tair",
            scale  = 1.0,
        ),
        (
            Vname  = "Qair",
            ECMWFname = "d2m",
            accumulation = false,
            output = "Qair",
            scale  = 1.0,
        ),
        (
            Vname  = "PAR",
            ECMWFname = "par",
            accumulation = true,
            output = "PAR",
            scale  = 1.0/(3*3600.0),
        )
    ]


    doFields = 1:16
    #    doFields = 1:1

    filenames = [(F[i].Vname,filename_prefix * "$(F[i].output)_test.nc") for i = doFields]

    rm.(unique([filename_prefix * "$(F[i].output)_test.nc" for i = doFields]))

    for i = doFields
        #local field_previous

        # ** Processing: Qair  for  01-Jan-2020 21:00:00 **
        # Wrote Qair                into record: 2927, Min= 3.81590e+01 Max= 1.00005e+02

        min_field = Inf
        max_field = -Inf

        Vname = F[i].Vname
        @info "Processing: $Vname for $(time[1]) - $(time[end])"
        Tname = ROMS.roms_metadata[Vname].Tname

        outfname = filename_prefix * "$(F[i].output)_test.nc"

        ncattrib = OrderedDict(
            String(k) => v for (k,v) in
            pairs(ROMS.roms_metadata[Vname].ncattrib))

        merge!(ncattrib,OrderedDict(
            "time" => Tname,
            "coordinates" => "lon lat $Tname"))

        ncattrib_time = OrderedDict(
            String(k) => v for (k,v) in
            pairs(ROMS.roms_metadata[Tname].ncattrib))

        merge!(ncattrib_time,OrderedDict(
            "units"                     => "days since $(Dates.format(time_origin,"yyyy-mm-dd HH:MM:SS"))",
            "calendar"                  => "gregorian"))

        dsout = ROMS.def_forcing(outfname,lon,lat,Vname,Tname,ncattrib,ncattrib_time,
                                 domain_name,time_origin)

        # Define variables

        dsout["spherical"][:] = flag_spherical
        dsout["lon"][:] = repeat(lon,inner=(1,length(lat)))
        dsout["lat"][:] = repeat(lat',inner=(length(lon),1))

        Dates.Hour(time[1]) == Dates.Hour(3)

        Δt =  Dates.Hour(3)
        scale = F[i].scale
        previous_field = zeros(length(lon),length(lat))

        for irec = 1:length(time)
            #    global field
            #    global previous_field

            if Vname == "Tair"
                field = nomissing(ds_ecmwf[F[i].ECMWFname][:,:,irec],NaN)
                field = field .- 273.15
            elseif Vname == "Qair"
                tsur = nomissing(ds_ecmwf["t2m"][:,:,irec],NaN)
                tdew = nomissing(ds_ecmwf["d2m"][:,:,irec],NaN)

                tsur  = tsur .- 273.15
                tdew  = tdew .- 273.15
                field = relative_humidity.(tsur,tdew)
            elseif Vname == "swflux"
                evap = Float64.(nomissing(ds_ecmwf["e"][:,:,irec],NaN))
                prec = Float64.(nomissing(ds_ecmwf["tp"][:,:,irec],NaN))
                field = (-evap - prec) .* scale;
            elseif Vname == "shflux"
                sensible = Float64.(nomissing(ds_ecmwf["sshf"][:,:,irec],NaN))
                latent = Float64.(nomissing(ds_ecmwf["slhf"][:,:,irec],NaN))
                nlwrad = Float64.(nomissing(ds_ecmwf["str"][:,:,irec],NaN))
                nsward = Float64.(nomissing(ds_ecmwf["ssr"][:,:,irec],NaN))
                field = (sensible + latent + nlwrad + nsward) * F[i].scale
            else
                field = nomissing(ds_ecmwf[F[i].ECMWFname][:,:,irec],NaN)
                field = field * F[i].scale
            end

            if fliplat
                field = reverse(field,dims=2)
            end

            time_rec = time[irec]
            if F[i].accumulation
                # compute the accumulation over a single 3h time step
                field,previous_field = (field - previous_field,field)

                if (Dates.Hour(time_rec) == Dates.Hour(0)) || (
                    Dates.Hour(time_rec) == Dates.Hour(12))
                    # reset accumulation at 00:00:00 or 12:00:00
                    previous_field .= 0
                end

                # time shift due to accumulation
                time_rec -= Dates.Millisecond(Δt)/2
            end

            dsout[Tname][irec] = time_rec
            dsout[Vname][:,:,irec] = field

            min_field = min(min_field,minimum(field))
            max_field = max(max_field,maximum(field))
        end
        close(dsout)

        @info "Wrote $Vname, Min= $(min_field) Max= $(max_field)"

    end
    close(ds_ecmwf)

    return filenames

end

datadir = joinpath(dirname(@__FILE__),"..","data")
atmo_fname = joinpath(datadir,"era_operational_archive_2019.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"

filenames = @time prep_field(atmo_fname,filename_prefix,domain_name)

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
