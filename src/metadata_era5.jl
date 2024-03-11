
metadata_era5 = Dict(
    "cloud_time" => (
        ncattrib = (
            long_name = "cloud fraction time",
        ),
    ),
    "cloud" => (
        Tname = "cloud_time",
        ncattrib = (
            long_name = "cloud fraction",
        ),
     ),
    "pair_time" => (
        ncattrib = (
            long_name = "surface air pressure time",
        ),
    ),
    "Pair" => (
        Tname = "pair_time",
        ncattrib = (
            long_name = "surface air pressure",
            units = "millibar",
        ),
     ),
    "qair_time" => (
        ncattrib = (
            #long_name = "surface air humidity time",
            long_name = "2m air humidity time",
        ),
    ),
    "Qair" => (
        Tname = "qair_time",
        ncattrib = (
            #long_name = "surface air humidity",
            long_name = "2m air humidity",
            units = "percentage",
        ),
     ),
    "tair_time" => (
        ncattrib = (
            #long_name = "surface air temperature time",
            long_name = "2m air temperature time",
        ),
    ),
    "Tair" => (
        Tname = "tair_time",
        ncattrib = (
            #long_name = "surface air temperature",
            long_name = "2m air temperature",
            units = "Celsius",
        ),
     ),
    "lhf_time" => (
        ncattrib = (
            long_name = "latent heat flux time",
        ),
    ),
    "latent" => (
        Tname = "lhf_time",
        ncattrib = (
            long_name = "net latent heat flux",
            units = "Watt meter-2",
            positive_value = "downward flux, heating",
            negative_value = "upward flux, cooling",
        ),
     ),

    #----
    "lrf_time" => (
        ncattrib = (
            long_name = "longwave radiation flux time",
        ),
    ),
    "lwrad" => (
        Tname = "lrf_time",
        ncattrib = (
            long_name = "net longwave radiation flux",
            units = "Watt meter-2",
            positive_value = "downward flux, heating",
            negative_value = "upward flux, cooling",
        ),
    ),
    "lwrad_down" => (
        Tname = "lrf_time",
        ncattrib = (
            long_name = "downwelling longwave radiation flux",
            units = "Watt meter-2",
            positive_value = "downward flux, heating",
            negative_value = "upward flux, cooling",
        ),
    ),
    "sen_time" => (
        ncattrib = (
            long_name = "sensible heat flux time",
        ),
    ),
    "sensible" => (
        Tname = "sen_time",
        ncattrib = (
            long_name = "net sensible heat flux",
            units = "Watt meter-2",
            positive_value = "downward flux, heating",
            negative_value = "upward flux, cooling",
        ),
    ),
    "shf_time" => (
        ncattrib = (
            long_name = "surface net heat flux time",
        ),
    ),
    "shflux" => (
        Tname = "shf_time",
        ncattrib = (
            long_name = "surface net heat flux",
            units = "Watt meter-2",
            positive_value = "downward flux, heating",
            negative_value = "upward flux, cooling",
        ),
    ),
    "sms_time" => (
        ncattrib = (
            long_name = "surface momentum stress time",
        ),
    ),
    "sustr" => (
        Tname = "sms_time",
        ncattrib = (
            long_name = "surface u-momentum stress",
            units = "Newton meter-2",
        ),
    ),
    "svstr" => (
        Tname = "sms_time",
        ncattrib = (
            long_name = "surface v-momentum stress",
            units = "Newton meter-2",
        ),
        long_name_time = "surface momentum stress time",
    ),
    "swf_time" => (
        ncattrib = (
            long_name = "surface net freshwater flux time",
        ),
    ),
    "swflux" => (
        Tname = "swf_time",
        ncattrib = (
            long_name = "surface net freshwater flux (E-P)",
            units = "m s-1",
            positive_value = "net evaporation",
            negative_value = "net precipitation",
        ),
    ),
    "srf_time" => (
        ncattrib = (
            long_name = "shortwave radiation flux time",
        ),
    ),
    "swrad" => (
        Tname = "srf_time",
        ncattrib = (
            long_name = "solar shortwave radiation flux",
            units = "Watt meter-2",
        ),
    ),

    "rain_time" => (
        ncattrib = (
            long_name = "rain fall time",
        ),
    ),
    "rain" => (
        Tname = "rain_time",
        ncattrib = (
            long_name = "rain fall",
            units = "kilogram meter-2 second-1",
        ),
    ),

    "wind_time" => (
        ncattrib = (
            #long_name = "surface wind time",
            long_name = "10m wind time",
        ),
    ),
    "Uwind" => (
        Tname = "wind_time",
        ncattrib = (
            #long_name = "surface u-wind component",
            long_name = "10m u-wind component",
            units = "meter second-1",
        ),
    ),

    "Vwind" => (
        Tname = "wind_time",
        ncattrib = (
            #long_name = "surface v-wind component",
            long_name = "10m v-wind component",
            units = "meter second-1",
        ),
    ),

    # "sst_time" => (
    #     ncattrib = (
    #         long_name = "sea surface temperature time",
    #     ),
    # ),
    # "SST" => (
    #     Tname = "sst_time",
    #     ncattrib = (
    #         long_name = "sea surface temperature",
    #         units = "Celsius",
    #     ),
    # ),
    # "dQdSST" => (
    #     Tname = "sst_time",
    #     ncattrib = (
    #         long_name = "surface net heat flux sensitivity to SST",
    #         units = "Watt meter-2 Celsius-1",
    #     ),
    # ),

)
