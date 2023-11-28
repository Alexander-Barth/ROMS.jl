

gfs_analysis(t) = Dates.hour(t) in (0,6,12,18)

const GFS_SAVE_STEP_HOURS = 3

"""
    url = ROMS.gfs_url(time,tau;
             modelname = "gfs",
             resolution = 0.25,
             baseurl = "https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/")

Returns the OPeNDAP url for the GFS data at time `time` (DateTime) and the forecast
time `tau` (hours) from the archive specified at `baseurl`.
"""
function gfs_url(time::TimeType,tau::Integer;
                 modelname = "gfs",
                 resolution = 0.25,
                 baseurl = "https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/")

    yyyy = Dates.format(time,"yyyy")
    yyyymmdd = Dates.format(time,"yyyymmdd")
    yyyymmddHH = Dates.format(time,"yyyymmddHH")

    return string(
        baseurl,
        "$yyyy/$yyyymmdd/",
        modelname,".",
        replace(string(resolution),"." => "p"),".",
        "$(yyyymmddHH).f$(@sprintf("%03d",tau)).grib2"
    )
end

function gfs_depth_index(ds,varname,z_level)
    ncvar = ds[varname]
    varname_z = dimnames(ncvar)[3]
    z = ds[varname_z]
    @assert z.attrib["units"] == "m"
    return findfirst(z[:] .== z_level)
end

function gfs_tau(t)
    if gfs_analysis(t)
        # fluxes and averages are missing at analysis time
        return 2*GFS_SAVE_STEP_HOURS
    else
        return GFS_SAVE_STEP_HOURS
    end
end

"""
    atmo_src = ROMS.download_gfs(xr,yr,tr,cachedir)

Downloads GFS 0.25° model results from the [NCAR Research Data Archive](https://rda.ucar.edu/)
within the longitude range `xr`, latitude range `yr` and time range `tr`.
Ranges are list of two elements with the start and end value.
Results are saved in `cachedir`.

See `ROMS.prepage_gfs` for an example.
"""
function download_gfs(
    xr,yr,tr,cachedir;
    modelname = "gfs",
    resolution = 0.25,
    baseurl = "https://thredds.rda.ucar.edu/thredds/dodsC/files/g/ds084.1/",
    verbose = true,
    padding = 1,
)
    # files contain 3 hours and 6 hours averaged. The later are converted to
    # 3 hours averages. Therefore it is not possible to start with a 6 hour average.

    #if gfs_analysis(tr[1]+Dates.Hour(GFS_SAVE_STEP_HOURS))
    if gfs_tau(tr[1]) != GFS_SAVE_STEP_HOURS
        tr = (tr[1]-Dates.Hour(GFS_SAVE_STEP_HOURS),tr[end])
    end

    times = tr[1]:Dates.Hour(GFS_SAVE_STEP_HOURS):tr[end]
    @debug "times $times"

    tau = gfs_tau(times[1])
    fname = gfs_url(
        times[1] - Dates.Hour(tau),tau,
        modelname = modelname,
        resolution = resolution,
        baseurl = baseurl,
    )

    # example
    # https://thredds.rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2018/20181231/gfs.0p25.2018123118.f003.grib2
    ds = NCDataset(fname);

    lon = ds["lon"][:]
    lat = ds["lat"][:]

    xr = xr .+ (-padding,padding)
    yr = yr .+ (-padding,padding)

    irange = findall(xr[1] .<= lon .<= xr[end])
    jrange = findall(yr[1] .<= lat .<= yr[end])


    irange = irange[1]:irange[end]
    jrange = jrange[1]:jrange[end]

    lon = lon[irange]
    lat = lat[jrange]

    mkpath(cachedir)
    filenames = Vector{String}(undef,length(times))

    for n = 1:length(times)
        t = times[n]
        tau = gfs_tau(t)

        time_start = t - Dates.Hour(tau)
        @debug "tt $time_start $tau"

        url = gfs_url(
            time_start, tau;
            modelname = modelname,
            resolution = resolution,
            baseurl = baseurl,
        )

        yyyymmddHH = Dates.format(time_start,"yyyymmddHH")

        fname = joinpath(cachedir,join((
            modelname,
            replace(string(resolution),"." => "p"),
            yyyymmddHH,"f$(@sprintf("%03d",tau))",
            "lon" * join(string.(xr),'-'),
            "lat" * join(string.(yr),'-'),
            "nc"),'.'))

        filenames[n] = fname
        @debug "checking cache" fname

        if !isfile(fname)
            if verbose
                print("Download ")
                printstyled(t,color=:green)
                println(" τ = $tau")
            end

            ds = NCDataset(url)

            write(fname,view(ds,lon = irange,lat = jrange),
                  include = intersect(keys(ds),[
                      "lon","lat","time",
                      "Pressure_surface",
                      "height_above_ground",
                      "height_above_ground1",
                      "height_above_ground2",
                      "height_above_ground3",
                      "height_above_ground4",
                      "u-component_of_wind_height_above_ground",
                      "v-component_of_wind_height_above_ground",
                      "Temperature_height_above_ground",
                      "Relative_humidity_height_above_ground",

                      "Momentum_flux_u-component_surface_3_Hour_Average",
                      "Momentum_flux_v-component_surface_3_Hour_Average",
                      "Convective_Precipitation_Rate_surface_3_Hour_Average",
                      "Latent_heat_net_flux_surface_3_Hour_Average",
                      "Sensible_heat_net_flux_surface_3_Hour_Average",
                      "Upward_Long-Wave_Radp_Flux_atmosphere_top_3_Hour_Average",
                      "Upward_Long-Wave_Radp_Flux_surface_3_Hour_Average",
                      "Upward_Short-Wave_Radiation_Flux_atmosphere_top_3_Hour_Average",
                      "Upward_Short-Wave_Radiation_Flux_surface_3_Hour_Average",
                      "Downward_Long-Wave_Radp_Flux_atmosphere_top_3_Hour_Average",
                      "Downward_Long-Wave_Radp_Flux_surface_3_Hour_Average",
                      "Downward_Short-Wave_Radiation_Flux_atmosphere_top_3_Hour_Average",
                      "Downward_Short-Wave_Radiation_Flux_surface_3_Hour_Average",
                      "Total_cloud_cover_entire_atmosphere_3_Hour_Average",

                      "Momentum_flux_u-component_surface_6_Hour_Average",
                      "Momentum_flux_v-component_surface_6_Hour_Average",
                      "Convective_Precipitation_Rate_surface_6_Hour_Average",
                      "Latent_heat_net_flux_surface_6_Hour_Average",
                      "Sensible_heat_net_flux_surface_6_Hour_Average",
                      "Upward_Long-Wave_Radp_Flux_atmosphere_top_6_Hour_Average",
                      "Upward_Long-Wave_Radp_Flux_surface_6_Hour_Average",
                      "Upward_Short-Wave_Radiation_Flux_atmosphere_top_6_Hour_Average",
                      "Upward_Short-Wave_Radiation_Flux_surface_6_Hour_Average",
                      "Downward_Long-Wave_Radp_Flux_atmosphere_top_6_Hour_Average",
                      "Downward_Long-Wave_Radp_Flux_surface_6_Hour_Average",
                      "Downward_Short-Wave_Radiation_Flux_atmosphere_top_6_Hour_Average",
                      "Downward_Short-Wave_Radiation_Flux_surface_6_Hour_Average",
                      "Total_cloud_cover_entire_atmosphere_6_Hour_Average",

                  ]
                                      ))
            close(ds)
        end
    end

    return (dir = cachedir, times = times, filenames = filenames)
end


"""
    ROMS.prepare_gfs(
       atmo_src,Vnames,filename_prefix,domain_name;
       time_origin = DateTime(1858,11,17),
    )

Generate ROMS forcing fields from GFS data `atmo_src` (a generated
by `ROMS.download_gfs`). The other arguments are the same as for
`ROMS.prepage_ecmwf`. The example below shows all currently supported values for
`Vnames`.

# Example

```julia
tr = (DateTime(2019,1,1),DateTime(2019,1,7))
xr = (7.5, 12.375)
yr = (41.875, 44.625)

cachedir = expanduser("~/tmp/GFS")
atmo_src = ROMS.download_gfs(xr,yr,tr,cachedir)

filename_prefix = "liguriansea_"
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","swflux","swrad","Uwind","Vwind",
          "sensible","cloud","rain","Pair","Tair","Qair"]
ROMS.prepare_gfs(atmo_src,Vnames,filename_prefix,domain_name)
)
```
"""
function prepare_gfs(
    atmo_src,Vnames,filename_prefix,domain_name;
    modelname = "gfs",
    resolution = 0.25,
    time_origin = DateTime(1858,11,17),
    )

    flag_spherical = 1

    F = [
        (
            Vname = "sustr",
            GFSname = "Momentum_flux_u-component_surface_3_Hour_Average",
            accumulation = true,
            output = "sms",
            scale = -1.,
        ),
        (
            Vname = "svstr",
            GFSname = "Momentum_flux_v-component_surface_3_Hour_Average",
            accumulation = true,
            output = "sms",
            scale = -1.,
        ),
        (
            Vname = "swrad",
            GFSname = "Upward_Short-Wave_Radiation_Flux_surface_3_Hour_Average",
            accumulation = true,
            output = "swrad",
            scale = 1.,
        ),
        (
            Vname = "sensible",
            GFSname = "Sensible_heat_net_flux_surface_3_Hour_Average",
            accumulation = true,
            output = "sensible",
            scale = -1.,
        ),
        (
            Vname  = "Uwind",
            GFSname = "u-component_of_wind_height_above_ground",
            accumulation = false,
            output = "wind",
            scale  = 1.0,
        ),
        (
            Vname  = "Vwind",
            GFSname = "v-component_of_wind_height_above_ground",
            accumulation = false,
            output = "wind",
            scale  = 1.0,
        ),
        (
            Vname  = "cloud",
            GFSname = "Total_cloud_cover_entire_atmosphere_3_Hour_Average",
            accumulation = true,
            output = "cloud",
            scale  = 0.01,
        ),
        (
            Vname  = "rain",
            GFSname = "Convective_Precipitation_Rate_surface_3_Hour_Average",
            accumulation = true,
            output = "rain",
            scale  = 1.,
        ),
        (
            Vname  = "Pair",
            GFSname = "Pressure_surface",
            accumulation = false,
            output = "Pair",
            scale  = 0.01, # millibar/Pa
        ),
        (
            Vname  = "Tair",
            GFSname = "Temperature_height_above_ground",
            accumulation = false,
            output = "Tair",
            scale  = 1.0,
        ),
        (
            Vname  = "Qair",
            GFSname = "Relative_humidity_height_above_ground",
            accumulation = false,
            output = "Qair",
            scale  = 1.0,
        ),

    ]

    doFields = filter(i -> F[i].Vname in Vnames,1:length(F))

    filenames = [(F[i].Vname,filename_prefix * "$(F[i].output).nc") for i = doFields]

    # remove existing files
    for (Vname,fname) in filenames
        if isfile(fname)
            rm(fname)
        end
    end

    function gfs_ds(atmo_src,irec)
        fname = atmo_src.filenames[irec]
        tau = gfs_tau(atmo_src.times[irec])

        @debug "opening $fname τ=$tau"

        return NCDataset(fname),tau
    end

    ds, = gfs_ds(atmo_src,1)
    lon = ds["lon"][:] #:: Vector{Float64}
    lat = ds["lat"][:] #:: Vector{Float64}
    close(ds)
    fliplat = lat[2] < lat[1]
    if fliplat
        lat = reverse(lat)
    end

    for i = doFields
        min_field = Inf
        max_field = -Inf

        Vname = F[i].Vname
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
            title = "GFS Dataset $domain_name from $(atmo_src.dir)",
        )

        # Define variables

        dsout["spherical"][:] = flag_spherical
        dsout["lon"][:] = repeat(lon,inner=(1,length(lat)))
        dsout["lat"][:] = repeat(lat',inner=(length(lon),1))

        latent_last = NaN
        precip_rate_last = NaN
        sustr_last = NaN
        field_last = NaN
        swrad_down_last = NaN

        for irec = 1:length(atmo_src.times)
            t = atmo_src.times[irec]

            ds,tau = gfs_ds(atmo_src,irec)

            if (tau == GFS_SAVE_STEP_HOURS) || !F[i].accumulation
                GFSname = F[i].GFSname
                if Vname in ("Uwind","Vwind")
                    k_wind = gfs_depth_index(ds,"u-component_of_wind_height_above_ground",10)
                    field = ds[GFSname][:,:,k_wind,1]
                elseif Vname == "Tair"
                    k_Tair = gfs_depth_index(ds,"Temperature_height_above_ground",2)
                    field = ds[GFSname][:,:,k_Tair,1]
                    field = field .- 273.15
                elseif Vname == "Qair"
                    k_Qair = gfs_depth_index(ds,"Relative_humidity_height_above_ground",2)
                    field = ds[GFSname][:,:,k_Qair,1]
                else
                    field = ds[GFSname][:,:,1]
                end

                if Vname == "swrad"
                    swrad_down = ds["Downward_Short-Wave_Radiation_Flux_surface_3_Hour_Average"][:,:,1]
                    swrad_down_last = swrad_down
                elseif Vname == "swflux"
                    # W m⁻²
                    latent = ds["Latent_heat_net_flux_surface_3_Hour_Average"][:,:,1]
                    # kg m⁻² s⁻¹
                    #field
                    latent_last = latent
                end

                field_last = field
            else
                GFSname = replace(F[i].GFSname,"3_Hour_Average" => "6_Hour_Average")
                field = ds[GFSname][:,:,1]

                # 6 hour average to 3 hour average
                field = 2*field - field_last

                if Vname == "swflux"
                    # W m⁻²
                    latent = ds["Latent_heat_net_flux_surface_6_Hour_Average"][:,:,1]

                    # kg m⁻² s⁻¹
                    latent = 2*latent - latent_last
                elseif Vname == "swrad"
                    swrad_down = ds["Downward_Short-Wave_Radiation_Flux_surface_6_Hour_Average"][:,:,1]

                    swrad_down = 2*swrad_down - swrad_down_last
                end
            end


            if F[i].accumulation
                time_rec = t - Dates.Minute(GFS_SAVE_STEP_HOURS * 60 ÷ 2)
            else
                time_rec = t
            end

            if Vname == "swflux"
                Tair = ds["Temperature_height_above_ground"][:,:,k_Tair,1]

                # W m⁻² J⁻¹ kg = J s⁻¹ m⁻² J⁻¹ kg = kg m⁻² s⁻¹
                evaporation_rate = @. latent / latent_heat_of_vaporization(Tair)

                # check sign
                field = -(field - evaporation_rate)

                density_fresh_water = 998 #  kg m⁻³

                # kg m⁻² s⁻¹ / (kg m⁻³) = m s⁻¹
                field = field / density_fresh_water
            elseif Vname == "swrad"
                field = swrad_down - field
            else
                field = field * F[i].scale
            end

            if fliplat
                field = reverse(field,dims=2)
            end

            dsout[Tname][irec] = time_rec
            dsout[Vname][:,:,irec] = field

            min_field = min(min_field,minimum(field))
            max_field = max(max_field,maximum(field))
        end
        close(dsout)

        @info "Wrote $Vname, Min= $(min_field) Max= $(max_field)"
    end

    return filenames
end
