"""
    ROMS.prepare_era5(
       atmo_fname,Vnames,filename_prefix,domain_name;
       time_origin = DateTime(1858,11,17))

Generate ROMS forcing fields from the ERA5 data file `atmo_fname`.

Translated to Julia by Alexander-Barth and rewritten by lnferris
to use rate variables instead of accumulated variables.

# Example

```julia
datadir = "..."
atmo_fname = joinpath(datadir,"ecmwf_sample_data.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","lwrad",
    "lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]
ROMS.prepare_era5(atmo_fname,Vnames,filename_prefix,domain_name)
)
```

Based on forcing/d_ecmwf2roms.m (svn revision 1102):

    Copyright (c) 2002-2017 The ROMS/TOMS Group      Hernan G. Arango
    Licensed under a MIT/X style license             John Wilkin
    See License_ROMS.txt

"""
function prepare_era5(
    atmo_fname,Vnames,filename_prefix,domain_name;
    time_origin = DateTime(1858,11,17),
)


ds_ecmwf = NCDataset(atmo_fname)
lon = ds_ecmwf["longitude"][:]
lat = ds_ecmwf["latitude"][:]
time = ds_ecmwf["time"][:]

fliplat = lat[2] < lat[1]
if fliplat
    lat = reverse(lat)
end

# The units we have (ECMWFname): https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels
# The units we need (Vname): varinfo.dat

F = [
    (
        Vname = "sustr",       #[N/m2]
        output = "sms",
        #ECMWFname = "ewss",   #[Ns/m2], Eastward turbulent surface stress
        #accumulation = true,
        #scale = 1.0/Δt_seconds,
        ECMWFname = "metss",           #[N/m2], Mean eastward turbulent surface stress
        accumulation = false,
        scale = 1.0,
    ),
    (
        Vname  = "svstr",      #[N/m2]
        output = "sms",
        #ECMWFname = "nsss",   #[Ns/m2], Northward turbulent surface stress
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname = "mntss",           #[N/m2], Mean northward turbulent surface stress
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "shflux",   # [W/m2]
        output = "shflux",
        #ECMWFname = "",    # calculated from Surface sensible heat flux, '' latent heat flux, '' net thermal radiation, '' net solar radiation [J/m2]
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname = "",       # calculated from Mean surface sensible heat flux, '' latent heat flux, '' net long-wave radiation flux, '' net short-wave radiation flux [W/m2]
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "swflux",     # [m/s]
        output = "swflux",
        #ECMWFname = "",       # calculated from Evaporation [m] and Total precipitation [m]
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname = "",        # calculated from Mean evaporation rate [kg/m2s], Mean total precipitation rate [kg/m2s]
        accumulation = false,
        scale  = 0.001,
    ),
    (
        Vname  = "swrad",           # [W/m2]
        output = "swrad",
        #ECMWFname = "ssr",         # [J/m2], Surface net solar radiation
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname =   "msnswrf",              # [W/m2], Mean surface net short-wave radiation flux
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "Uwind",   #[m/s]
        output = "wind",
        ECMWFname = "u10",  #[m/s], 10m u-component of wind
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "Vwind",    #[m/s]
        output = "wind",
        ECMWFname = "v10",   #[m/s], 10m v-component of wind
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "lwrad",         # [W/m2]
        output = "lwrad",
        #ECMWFname = "str",       # [J/m2], Surface net thermal radiation
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname =   "msnlwrf",            # [W/m2], Mean surface net long-wave radiation flux
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "lwrad_down",   # [W/m2]
        output = "lwrad",
        #ECMWFname = "strd",     # [J/m2], Surface thermal radiation downwards
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname =  "msdwlwrf",            # [W/m2], Mean surface downward long-wave radiation flux
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "latent",     #[W/m2]
        output = "latent",
        #ECMWFname = "slhf",   #[J/m2], Surface latent heat flux
        #accumulation = true,
        #scale  = 1.0/Δt_seconds,
        ECMWFname = "mslhf",           #[W/m2], Mean surface latent heat flux
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "sensible",  #[W/m2]
        output = "sensible",
        #accumulation = true,
        #ECMWFname = "sshf",     # [J/m2], Surface sensible heat flux
        #scale  = 1.0/Δt_seconds,
        ECMWFname =  "msshf",           # [W/m^2], Mean surface sensible heat flux
        accumulation = false,
        scale  = 1.0
    ),
    (
        Vname  = "cloud",   # [fraction]
        output = "cloud",
        ECMWFname = "tcc",  # [fraction], Total cloud cover
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "rain",              #[kg/m2s]
        output = "rain",
        #ECMWFname = "tp",            #[m], Total precipitation
        #scale  = 1000.0/Δt_seconds,
        #accumulation = true,
        ECMWFname = "mtpr",           #[kg/m2s], Mean total precipitation rate
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "Pair",    # [millibar]
        output = "Pair",
        ECMWFname = "msl",  # [Pa], Mean sea level pressure
        accumulation = false,
        scale  = 0.01,
    ),
    (
        Vname  = "Tair",       # [degC]
        output = "Tair",
        ECMWFname = "",     # calculated from 2m temperature [K]
        accumulation = false,
        scale  = 1.0,
    ),
    (
        Vname  = "Qair",   # [percent]
        output = "Qair",
        ECMWFname = "",    # calculated from 2m temperature [K] and 2m dewpoint temperature [K]
        accumulation = false,
        scale  = 1.0,
    )
]


doFields = filter(i -> F[i].Vname in Vnames,1:length(F))

filenames = [(F[i].Vname,filename_prefix * "$(F[i].output).nc") for i = doFields]

# remove existing files
for (Vname,fname) in filenames
    if isfile(fname)
        rm(fname)
    end
end

for i = doFields

    min_field = Inf
    max_field = -Inf

    Vname = F[i].Vname
    @info "Processing: $Vname for $(time[1]) - $(time[end])"
    Tname = metadata_era5[Vname].Tname

    outfname = filename_prefix * "$(F[i].output).nc"

    ncattrib = OrderedDict(
        String(k) => v for (k,v) in
        pairs(metadata_era5[Vname].ncattrib))

    merge!(ncattrib,OrderedDict(
        "time" => Tname,
        "coordinates" => "lon lat $Tname"))

    ncattrib_time = OrderedDict(
        String(k) => v for (k,v) in
        pairs(metadata_era5[Tname].ncattrib))

    merge!(ncattrib_time,OrderedDict(
        "units"                     => "days since $(Dates.format(time_origin,"yyyy-mm-dd HH:MM:SS"))",
        "calendar"                  => "gregorian"))

    dsout = ROMS.def_forcing(
        outfname,lon,lat,Vname,Tname,ncattrib,ncattrib_time,
        time_origin;
        title = "ECMWF Dataset $domain_name from $atmo_fname",
    )

    # Define variables

    dsout["spherical"][:] = 1 # indeed spherical
    dsout["lon"][:] = repeat(lon,inner=(1,length(lat)))
    dsout["lat"][:] = repeat(lat',inner=(length(lon),1))

    scale = F[i].scale
    previous_field = zeros(length(lon),length(lat))

    for irec = 1:length(time)

        if Vname == "Tair"
            field = nomissing(ds_ecmwf["t2m"][:,:,irec],NaN)
            field = field .- 273.15
        elseif Vname == "Qair"
            tsur = nomissing(ds_ecmwf["t2m"][:,:,irec],NaN)
            tdew = nomissing(ds_ecmwf["d2m"][:,:,irec],NaN)
            tsur  = tsur .- 273.15
            tdew  = tdew .- 273.15
            field = ROMS.relative_humidity.(tsur,tdew)
        elseif Vname == "swflux"
            evap = Float64.(nomissing(ds_ecmwf["mer"][:,:,irec],NaN))
            prec = Float64.(nomissing(ds_ecmwf["mtpr"][:,:,irec],NaN))
            field = (evap - prec) .* scale;
        elseif Vname == "shflux"
            sensible = Float64.(nomissing(ds_ecmwf["msshf"][:,:,irec],NaN))
            latent = Float64.(nomissing(ds_ecmwf["mslhf"][:,:,irec],NaN))
            nlwrad = Float64.(nomissing(ds_ecmwf["msnlwrf"][:,:,irec],NaN))
            nsward = Float64.(nomissing(ds_ecmwf["msnswrf"][:,:,irec],NaN))
            field = (sensible + latent + nlwrad + nsward) * F[i].scale
        else
            field = nomissing(ds_ecmwf[F[i].ECMWFname][:,:,irec],NaN)
            field = field * F[i].scale
        end

        if fliplat
            field = reverse(field,dims=2)
        end

        dsout[Tname][irec] = time[irec]
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
