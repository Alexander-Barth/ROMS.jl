using Dates
using DataStructures
using CDSAPI


function _download(xr,yr,tr,filename)
    fmt = "yyyy-mm-dd"

    req =  Dict(
        "product_type" => "reanalysis",
        "format" => "netcdf",
        "variable" => [
            "10m_u_component_of_wind",
            "10m_v_component_of_wind",
            "eastward_turbulent_surface_stress",
            "northward_turbulent_surface_stress",
            "mean_sea_level_pressure",
            "2m_dewpoint_temperature",
            "2m_temperature",
            "evaporation",
            "runoff",
            "sea_surface_temperature",
            "surface_net_solar_radiation",
            "surface_net_thermal_radiation",
            "surface_latent_heat_flux",
            "surface_sensible_heat_flux",
            "surface_thermal_radiation_downwards",
            "total_cloud_cover",
            "total_precipitation",
        ],
        "date" => join(Dates.format.(tr,fmt),"/"),
        "area" => (yr[1],xr[1],yr[2],xr[2]),
        "time" => string.(Time.(0:1:23)),
    )
    println(req)
    CDSAPI.retrieve("reanalysis-era5-single-levels",req, filename)
end



function download(xr,yr,tr,fname_prefix)

    t0 = tr[1]
    tchunk = Dates.Month(1)
    teps = Dates.Minute(1)
    filenames = String[]

    for t = tr[1]:tchunk:tr[end]
        tr_chunk =
            if t + tchunk >= tr[end]
                (t,tr[end])
            else
                (t, t+tchunk - teps)
            end

        filename = fname_prefix *
            join((
                "ECMWF","ERA5",
                Dates.format(t,"yyyy-mm"),
                "lon" * join(string.(xr),'-'),
                "lat" * join(string.(yr),'-')),
                "_") * ".nc"

        if !isfile(filename)
            @info "get $(tr_chunk[1]) - $(tr_chunk[end])"
            tmp = filename * ".tmp"
            _download(xr,yr,tr_chunk,tmp)
            mv(tmp,filename)
        end
        push!(filenames,filename)
    end

    return filenames
end

fmt = "yyyy-mm-dd"

# range of longitude (east, west)
xr = [7.5, 12.375]

# range of latitude (south, north)
yr = [41.875, 44.625]

# time range (stard, end)
# the DateTime function expects year, month and day
# Note: it should contain 1 day more than the simulation time range of ROMS
# If ROMS starts at 1 January 2000, you will need data the 31 December 2000
tr = [DateTime(2018,12,1),DateTime(2020,1,31)]
#tr = [DateTime(2018,12,31),DateTime(2019,1,8)]
#tr = [DateTime(2018,12,1),DateTime(2018,12,5)]

# output file name
fname_prefix = expanduser("~/tmp/")

download(xr,yr,tr,fname_prefix)
