
function HYCOM(url,cachedir; chunks = 60)
    mapping = Dict(
        :sea_water_potential_temperature => "water_temp",
        :sea_surface_height_above_geoid => "surf_el",
    )

    return CDMDataset(
        NCDataset,
        DefaultDict{Symbol,String,String}(url),
        cachedir = cachedir,
        mapping = mapping,
        chunks = chunks,
    )
end



#dataset[]



