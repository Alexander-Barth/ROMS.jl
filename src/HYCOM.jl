
function HYCOM(url)
    mapping = Dict(
        :sea_water_potential_temperature => "water_temp",
        :sea_surface_height_above_geoid => "surf_el",
    )

    return OPENDAP(url,mapping)
end



#dataset[]



