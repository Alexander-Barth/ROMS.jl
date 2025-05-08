"""
    ROMS.prepare_ecmwf(
       atmo_fname,Vnames,filename_prefix,domain_name;
       time_origin = DateTime(1858,11,17),
       reset_accumulation = time -> Time(time) in (Time(0,0),Time(12,0)),
    )

Generate ROMS forcing fields from the ECMWF data file `atmo_fname`.
Note that some variables are [accumulated](https://www.myroms.org/forum/viewtopic.php?f=30&t=3003). Per default, the accumulation is reset at 00:00 and 12:00 UTC.
The accumulation period is determined from the time resolution (usually 3 hours).

For the operational model output, if the following ECMWF API request is made:

```
        [...]
        'step':    '3/6/9/12',
        'stream':  'oper',
        'time':    '00/12',
        [...]
```

The temporal resolution is 3 hours and several parameters (fluxes of heat, momentum and fresh water, radiation, and total precipiation) are accumulated since 
the start hour of the simulation (00 h and 12 h). The accumulation need therefore be reset at 0h and 12h.
The unit of the NetCDF variable indicates where the variable is accumulated (integrated over typically 3 hours) 
or an instantaneous value.

Note ERA5 reanalysis (hourly data): [Accumulations are performed over the hour](https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation#ERA5:datadocumentation-Meanrates/fluxesandaccumulations).


# Example

```julia
datadir = "..."
atmo_fname = joinpath(datadir,"ecmwf_sample_data.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","lwrad",
    "lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]
ROMS.prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name)
)
```

Based on forcing/d_ecmwf2roms.m (svn revision 1102):

    Copyright (c) 2002-2017 The ROMS/TOMS Group      Hernan G. Arango
    Licensed under a MIT/X style license             John Wilkin
    See License_ROMS.txt

"""
function prepare_ecmwf(
    atmo_fname,Vnames,filename_prefix,domain_name;
    time_origin = DateTime(1858,11,17),
    reset_accumulation = time -> Time(time) in (Time(0,0),Time(12,0)),
)

    ds_ecmwf = NCDataset(atmo_fname)
    lon = ds_ecmwf["longitude"][:]
    lat = ds_ecmwf["latitude"][:]
    time = ds_ecmwf["time"][:]

    fliplat = lat[2] < lat[1]
    if fliplat
        lat = reverse(lat)
    end

    # time resolution for accumulation
    Δt = time[2]-time[1]
    Δt_seconds = Dates.value(Δt) / 1000 # ms to s
    flag_cartesian = 0
    flag_spherical = 1

    F = [
        (
            Vname = "sustr",
            ECMWFname = "ewss",
            accumulation = true,
            output = "sms",
            scale = 1/Δt_seconds, # 3 hours accumulation
        ),
        (
            Vname  = "svstr",
            ECMWFname = "nsss",
            accumulation = true,
            output = "sms",
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "shflux",
            ECMWFname = "",
            accumulation = true,
            output = "shflux",
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "swflux",
            ECMWFname = "",
            accumulation = true,
            output = "swflux",
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "swrad",
            ECMWFname = "ssr",
            accumulation = true,
            output = "swrad",
            scale  = 1.0/Δt_seconds,
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
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "lwrad_down",
            ECMWFname = "strd",
            accumulation = true,
            output = "lwrad",
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "latent",
            ECMWFname = "slhf",
            accumulation = true,
            output = "latent",
            scale  = 1.0/Δt_seconds,
        ),
        (
            Vname  = "sensible",
            ECMWFname = "sshf",
            accumulation = true,
            output = "sensible",
            scale  = 1.0/Δt_seconds,
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
            scale  = 1000.0/Δt_seconds,
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
            scale  = 1.0/Δt_seconds,
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

        dsout = ROMS.def_forcing(
            outfname,lon,lat,Vname,Tname,ncattrib,ncattrib_time,
            time_origin;
            title = "ECMWF Dataset $domain_name from $atmo_fname",
        )

        # Define variables

        dsout["spherical"][:] = flag_spherical
        dsout["lon"][:] = repeat(lon,inner=(1,length(lat)))
        dsout["lat"][:] = repeat(lat',inner=(length(lon),1))

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
                field = (evap - prec) .* scale;
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

                if reset_accumulation(time_rec)
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
