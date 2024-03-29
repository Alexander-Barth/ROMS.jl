struct OPENDAP{TDS} <: ROMS.AbstractDataset
    url::DefaultDict{Symbol,String,String}
    cachedir::String
    mapping::Dict{Symbol,String}
    chunks::Int
end

function getvar(h::OPENDAP,ds,variablename)
    if haskey(h.mapping,variablename)
        ncvar = ds[h.mapping[variablename]]
    else
        ncvars = varbyattrib(ds,standard_name = String(variablename));

        if length(ncvars) != 1
            error("$(length(ncvars)) variables with the standard name attribute equal to '$variablename' found.")
        end

        ncvar = ncvars[1];
    end

    @debug "NetCDF variable $(name(ncvar)) with the size of $(size(ncvar)) is used for $variablename"
    return ncvar
end

rg(i) = i[1]:i[end]

function download(dsopendap::OPENDAP{TDS},variablename::Symbol;
                  longitude=nothing,latitude=nothing,time=nothing) where TDS

    mkpath(dsopendap.cachedir)
    uri = URI(dsopendap.url[variablename])
    _ds = TDS(dsopendap.url[variablename])
    ncvar = getvar(dsopendap,_ds,variablename)

    nclon = coord(ncvar,"longitude")
    nclat = coord(ncvar,"latitude")
    nctime = coord(ncvar,"time")

    indices = (; ((Symbol(name(ncv)), rg(findall(first(b) .<= ncv[:] .<= last(b))) )
                  for (ncv,b) in [ (nclon,longitude),(nclat,latitude),(nctime,time)]) ...)

    time_indices = indices[3]
    time_dim = Symbol(name(nctime))
    varname = name(ncvar)
    include_var = name.([ncvar,nclon,nclat,nctime])

    if ndims(ncvar) == 4
        push!(include_var,"depth")
    end

    fnames_subset = String[]

    for n in first(time_indices):dsopendap.chunks:last(time_indices)
        n0 = n:min(n+dsopendap.chunks-1,last(time_indices))
        @show n0
        indices0 = (;indices..., (time_dim => n0,)...)

        time_range0 = nctime[n0[[1,end]]]

        fname_subset = joinpath(dsopendap.cachedir,join([
            uri.host,
            replace(uri.path,'/' => '-'),
            "$variablename",
            "lon",join(string.(longitude),'-'),
            "lat",join(string.(latitude),'-'),
            "time",join(string.(time_range0),'-')],'-') * ".nc")

        if isfile(fname_subset)
            @info "$fname_subset is in cache"
        else
            # download to a temporary file in case
            # the download fails
            tmp = fname_subset * ".partial-" * randstring(12)
            ds_subset = view(_ds; pairs(indices0)...)

            @info "download $name in $fname_subset"
            NCDataset(tmp,"c") do ds
                NCDatasets.write(
                    ds,ds_subset,
                    include = include_var)
            end

            mv(tmp,fname_subset)
        end

        push!(fnames_subset,fname_subset)
    end

    close(_ds)


    @show fnames_subset,varname
    return fnames_subset,varname
end

function load(dsopendap::OPENDAP,variablename::Symbol; kwargs...)
    filenames,varname = download(dsopendap,variablename; kwargs...)
    ds = NCDataset(filenames,"r", aggdim = "time")

    ncvar = ds[varname]
    x = coord(ncvar,"longitude")[:]
    y = coord(ncvar,"latitude")[:]
    t = coord(ncvar,"time")[:]

    if ndims(ncvar) == 3
        @debug "time: $t"
        @debug "size $variablename: $(size(ncvar))"
        return (ncvar,(x,y,t))
    else
        ncdepth = ds["depth"]
        z = nomissing(ncdepth[:])
        if get(ncdepth.attrib,"positive","up") == "down"
            # change vertical axis to positive up
            z = -z
        end
        @debug "depth: $z"
        @debug "time: $t"
        @debug "size $variablename: $(size(ncvar))"

        return (ncvar,(x,y,z,t))
    end
end


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
