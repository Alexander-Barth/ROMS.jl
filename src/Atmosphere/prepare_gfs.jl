"""
time start time of the forecast (DateTime)
tau: lead time (hours)
"""
function gfs_url(time,tau,
                 modelname = "gfs",
                 resolution = 0.25,
                 baseurl="https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/")

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



"""
Tair: degC
Output: J/kg
"""
function latent_heat_of_vaporization(Tair)
    # equation 2.55 (page 38) of
    # Foken, T, 2008: Micrometeorology. Springer, Berlin, Germany.
    # https://link.springer.com/content/pdf/10.1007/978-3-540-74666-9.pdf
    λ = 2500827 - 2360 * Tair
end


function prepare_gfs(
    atmo_src,Vnames,filename_prefix,domain_name)

    modelname = "gfs"
    resolution = 0.25
    time_origin = DateTime(1858,11,17)

    Vnames = ["sustr","svstr","sensible","Uwind","Vwind","Tair", "Qair",
              "rain", "cloud","Pair","swrad"]
    #Vnames = ["rain"]
    #Vnames = ["Pair"]
    #Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","lwrad",
    #    "lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

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

    function gfs_ds(atmo_src,t)
        if Dates.hour(t)-3 in (0,6,12,18)
            tau = 3
        else
            tau = 6
        end
        #@show t,tau,irec

        time_start = t - Dates.Hour(tau)
        url = gfs_url(time_start, tau)

        yyyymmddHH = Dates.format(time_start,"yyyymmddHH")

        fname = joinpath(atmo_src.dir,join((
            modelname,
            replace(string(resolution),"." => "p"),
            yyyymmddHH,"f$(@sprintf("%03d",tau)).nc"),'.'))

        return NCDataset(fname),tau
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


        ds, = gfs_ds(atmo_src,atmo_src.times[1])
        lon = ds["lon"][:] #:: Vector{Float64}
        lat = ds["lat"][:] #:: Vector{Float64}
        close(ds)

        dsout = ROMS.def_forcing(outfname,lon,lat,Vname,Tname,ncattrib,ncattrib_time,
                                 domain_name,time_origin)

        latent_last = NaN
        precip_rate_last = NaN
        sustr_last = NaN
        field_last = NaN
        swrad_down_last = NaN

        for irec = 1:length(atmo_src.times)
            #global latent_last, precip_rate_last, sustr_last, time_start, yyyymmddHH, tau, t
            #global Tair, fname, ds, field_last, swrad_down_last
            t = atmo_src.times[irec]

            ds,tau = gfs_ds(atmo_src,t)

            if (tau == 3) || !F[i].accumulation
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
                time_rec = t - Dates.Minute(3 * 60 ÷ 2)
            else
                time_rec = t
            end

            if Vname == "swflux"
                Tair = ds["Temperature_height_above_ground"][:,:,k_Tair,1]

                # W m⁻² J⁻¹ kg = J s⁻¹ m⁻² J⁻¹ kg = kg m⁻² s⁻¹
                evaporation_rate = @. latent / latent_heat_of_vaporization(Tair)

                # check sign
                field = -(field - evaporation_rate)
            elseif Vname == "swrad"
                field = swrad_down - field
            else
                field = field * F[i].scale
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
