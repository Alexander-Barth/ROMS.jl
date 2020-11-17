
vapor_pressure_Tetens(T) = 6.1078 * exp( 17.27 * T / (T + 237.3))


"""
    e = vapor_pressure_Buck(T)

actual vapor pressure in hPa (millibars) from dewpoint temperature `T` in degree Celsius
using using [Buck (1996)](https://en.wikipedia.org/w/index.php?title=Arden_Buck_equation&oldid=946509994). If `T` is the air temperature, then  `e` is the saturated vapor
pressure over liquid water is given by:

``
e(T) = 6.1121 \\exp \\left(\\left( 18.678 - \\frac{T} {234.5}\\right)\\left( \\frac{T} {257.14 + T} \\right)\\right)
``
"""
vapor_pressure_Buck(T) = 6.1121 * exp( (18.678 - T/234.5) * T / (257.14 + T))


"""
    e = vapor_pressure(T)

actual vapor pressure in hPa (millibars) from dewpoint temperature `T` in degree Celsius
using using [1]. If `T` is the air temperature, then  `e` is the saturated vapor
pressure over liquid water is given by:

``
e(T) = 6.11 \\cdot 10 ^ {\\left(  \\frac{7.5 T}{237.7 + T} \\right)}
``

[1] https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
vapor_pressure(T) = 6.11 * 10.0 ^ (7.5 * T / (237.7 + T))



"""
    rh = relative_humidity(temperature_2m_C,dew_temperature_2m_C)

Compute the relative humidity (between 0 and 100) from temperature at 2 m, and dew_temperature at
2 m) both in degree Celsius)

[1] https://web.archive.org/web/20200926200733/https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
"""
function relative_humidity(temperature_2m_C,dew_temperature_2m_C)
    100 * vapor_pressure(dew_temperature_2m_C) / vapor_pressure(temperature_2m_C)
end

"""
    prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name;
                       time_origin = DateTime(1858,11,17)
    )

Generate ROMS forcing fields from the ECMWF data file `atmo_fname`.

# Example

```julia
datadir = "..."
atmo_fname = joinpath(datadir,"ecmwf_sample_data.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","lwrad",
    "lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]
prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name)
)
```

Based on forcing/d_ecmwf2roms.m:

    Copyright (c) 2002-2017 The ROMS/TOMS Group      Hernan G. Arango
    Licensed under a MIT/X style license             John Wilkin
    See License_ROMS.txt

"""
function prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name;
                       time_origin = DateTime(1858,11,17)
)

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


    #doFields = 1:16
    doFields = filter(i -> F[i].Vname in Vnames,1:length(F))

    filenames = [(F[i].Vname,filename_prefix * "$(F[i].output).nc") for i = doFields]

    # remove existing files
    for (Vname,fname) in filenames
        if isfile(fname)
            rm(fname)
        end
    end

    for i = doFields
        #local field_previous

        # ** Processing: Qair  for  01-Jan-2020 21:00:00 **
        # Wrote Qair                into record: 2927, Min= 3.81590e+01 Max= 1.00005e+02

        min_field = Inf
        max_field = -Inf

        Vname = F[i].Vname
        @info "Processing: $Vname for $(time[1]) - $(time[end])"
        Tname = ROMS.metadata[Vname].Tname

        outfname = filename_prefix * "$(F[i].output).nc"

        ncattrib = OrderedDict(
            String(k) => v for (k,v) in
            pairs(ROMS.metadata[Vname].ncattrib))

        merge!(ncattrib,OrderedDict(
            "time" => Tname,
            "coordinates" => "lon lat $Tname"))

        ncattrib_time = OrderedDict(
            String(k) => v for (k,v) in
            pairs(ROMS.metadata[Tname].ncattrib))

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
