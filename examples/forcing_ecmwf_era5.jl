using Dates
using DataStructures
using CDSAPI


function download(xr,yr,tr,filename)
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

#=
    req2 = OrderedDict(
        "class" =>   "ea",
        "expver" =>  "1",
        "dataset" => "interim",
        "date" =>    join(Dates.format.(tr,fmt),"/"),
        "levtype" => "sfc",
        "grid" =>    "0.75/0.75",
        "param" =>   "146.128/147.128/151.128/164.128/165.128/166.128/167.128/168.128/175.128/176.128/177.128/180.128/181.128/182.128/205.128/228.128/34.128/58.128",
        "step" =>    "3/6/9/12",
        "stream" =>  "oper",
        "target" =>  "output",
        "time" =>    "00:00:00/12:00:00",
        "type" =>    "fc",
        "area" =>    join(string.((yr[1],xr[1],yr[2],xr[2])),"/"),
        "format" =>  "netcdf",
    )

    println(req2)

    CDSAPI.retrieve("reanalysis-era5-complete", req2, "output")
    #CDSAPI.retrieve("reanalysis-era5-single-levels",req2, filename)
=#
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
tr = [DateTime(2018,12,1),DateTime(2020,1,1)]
tr = [DateTime(2018,12,1),DateTime(2018,12,5)]

# output file name
filename = "ecmwf_era5_" * join(Dates.format.(tr,fmt),"_") * ".nc"

download(xr,yr,tr,filename)
