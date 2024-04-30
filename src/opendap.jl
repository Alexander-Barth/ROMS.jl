struct OPENDAP{TDS} <: ROMS.AbstractDataset
    url::DefaultDict{Symbol,String,String}
    cachedir::String
    mapping::Dict{Symbol,String}
    chunks::Int
    options::Dict{Symbol,Any}
    time_shift::Int
end


function OPENDAP(TDS,urls;
                 mapping = Dict{Symbol,String}(),
                 cachedir = tempdir(),
                 chunks = 60,
                 options = Dict{Symbol,Any}(),
                 time_shift = 0,
                 )

    return OPENDAP{TDS}(
        urls,
        cachedir,
        mapping,
        chunks,
        options,
        time_shift,
    )
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
    _ds = TDS(dsopendap.url[variablename]; dsopendap.options...)
    ncvar = getvar(dsopendap,_ds,variablename)

    nclon = coord(ncvar,"longitude")
    nclat = coord(ncvar,"latitude")
    nctime = coord(ncvar,"time")

    if !isnothing(time)
        time = time - Dates.Second(dsopendap.time_shift)
    end

    indices = (; ((Symbol(name(ncv)), rg(findall(first(b) .<= ncv[:] .<= last(b))) )
                  for (ncv,b) in [ (nclon,longitude),(nclat,latitude),(nctime,time)]) ...)

    time_indices = indices[3]
    time_dim = Symbol(name(nctime))
    varname = name(ncvar)
    include_var = name.([ncvar,nclon,nclat,nctime])

    if ndims(ncvar) == 4
        # depth is sometimes called elevation
        # with always has the standard_name depth
        push!(include_var,name(_ds[CF"depth"]))
    end

    fnames_subset = String[]

    for n in first(time_indices):dsopendap.chunks:last(time_indices)
        n0 = n:min(n+dsopendap.chunks-1,last(time_indices))
        @show n0
        indices0 = (;indices..., (time_dim => n0,)...)

        time_range0 = nctime[n0[[1,end]]]

        fbasename = join([
            uri.host,
            replace(uri.path,'/' => '-'),
            "$variablename",
            "lon",join(string.(longitude),'-'),
            "lat",join(string.(latitude),'-'),
            "time",join(string.(time_range0),'-')],'-')

        fbasename = bytes2hex(sha256(fbasename))
        fname_subset = joinpath(dsopendap.cachedir,fbasename * ".nc")

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

    # https://help.marine.copernicus.eu/en/articles/8656000-differences-between-netcdf-and-arco-formats
    # Start-of-interval time samples vs centred-of-interval
    t = t + Dates.Second(dsopendap.time_shift)

    if ndims(ncvar) == 3
        @debug "time: $t"
        @debug "size $variablename: $(size(ncvar))"
        return (ncvar,(x,y,t))
    else
        ncdepth = ds[CF"depth"]
        z = nomissing(ncdepth[:])
        # CMEMS Zarr file have the wrong attributes
        #if get(ncdepth.attrib,"positive","up") == "down"
        if mean(z) > 0
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
