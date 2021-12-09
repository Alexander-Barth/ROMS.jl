using NCDatasets
using ROMS
using Dates

struct OPENDAP <: ROMS.AbstractDataset
    url::String
    mapping::Dict{Symbol,String}
end

#function load(::CMEMS,name::Symbol; kwargs...)


function getvar(h::OPENDAP,ds,name)
    if haskey(h.mapping,name)
        ncvar = ds[h.mapping[name]]
    else
        ncvars = varbyattrib(ds,standard_name = String(name));

        if length(ncvars) != 1
            error("$(length(ncvars)) variables with the standard name attribute equal to '$name' found.")
        end

        ncvar = ncvars[1];
    end

    @debug "NetCDF variable $(NCDatasets.name(ncvar)) with the size of $(size(ncvar)) is used for $name"
    return ncvar
end

function load(h::OPENDAP,name::Symbol;
              longitude=nothing,latitude=nothing,time=nothing)

    ds = NCDataset(h.url)
    ncvar = getvar(h,ds,name)

    lon = coord(ncvar,"longitude")[:]
    lat = coord(ncvar,"latitude")[:]
    ntime = coord(ncvar,"time")[:]

    rg(i) = i[1]:i[end]

    i = rg(findall(first(longitude) .<= lon .<= last(longitude)))
    j = rg(findall(first(latitude) .<= lat .<= last(latitude)))
    n = rg(findall(first(time) .<= ntime .<= last(time)))

    x = lon[i]
    y = lat[j]
    t = ntime[n]

    @debug "lon: $x"
    @debug "lat: $y"

    if ndims(ncvar) == 4
        ncdepth = coord(ncvar,"depth")
        z = ncdepth[:]

        if get(ncdepth.attrib,"positive","up") == "down"
            z = -z
        end

        @debug "depth: $z"
        @debug "time: $t"
        @debug "size $name: $(size(ncvar))"

        return (ncvar,(x,y,z,t))
    else
        @debug "time: $t"
        @debug "size $name: $(size(ncvar))"

        return (ncvar,(x,y,t))
    end
end
#close(ds)

#=

query = (
    time = DateTime(2013,10,1):Dates.Day(1):DateTime(2013,10,2),
    longitude = 104:108,
    latitude = -7:-5,
)

url = "http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_91.0"
h = OPENDAP(url,mapping)



#dataset[]

mapping = Dict(
    :sea_water_potential_temperature => "water_temp",
    :sea_surface_height_above_geoid => "surf_el",
)

name = :sea_water_potential_temperature

v,(x,y,z,t) = load(h,name; query...)

v,(x,y,z,t) = load(h,:sea_water_salinity; query...)

v,(x,y,t) = load(h,:sea_surface_height_above_geoid; query...)

=#
