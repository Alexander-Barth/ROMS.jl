abstract type AbstractDataset end

struct DatasetVariable{DS<:AbstractDataset}
    ds::DS
    name::Symbol
end
Base.getindex(ds::AbstractDataset,name::Symbol) = DatasetVariable(ds,name)

load(dv::DatasetVariable; kwargs...) = load(dv.ds,dv.name; kwargs...)
download(dv::DatasetVariable; kwargs...) = download(dv.ds,dv.name; kwargs...)

struct CMEMS <: AbstractDataset
    username::String
    password::String
    service_id::String
    motu_server::String
    cachedir::String
    motu_program::String
    mapping::Dict{Symbol,NTuple{2,String}}
end


"""
    ds = ROMS.CMEMS(username,password,service_id,mapping,cachedir;
                   motu_server = "http://nrt.cmems-du.eu/motu-web/Motu",
                   # Put here the path of the script motuclient
                   motu_program = "motuclient",
               )

Returns a structure `ds` to connect to a CMEMS Motu server using the python
tools `motuclient` (which must be available in your `PATH`).
The `mapping` parameter contains a dictorary linking the NetCDF CF standard namer
to the underlying NetCDF variable names and the product identifers (more
information is available in the product user manual).
`cachedir` is a directory where the products are downloaded for caching.

## Example

The  values of `service_id` and `mapping` below are specific to the
Mediterranean Sea and must be adapted for other domains.

```julia
cmems_username = "Alice"
cmems_password = "rabbit"
outdir = "/tmp"
service_id = "MEDSEA_ANALYSIS_FORECAST_PHY_006_013-TDS"
mapping = Dict(
    # var  product_id
    :sea_surface_height_above_geoid => ("zos","med00-cmcc-ssh-an-fc-d"),
    :sea_water_potential_temperature => ("thetao", "med00-cmcc-tem-an-fc-d"),
    :sea_water_salinity => ("so","med00-cmcc-sal-an-fc-d"),
    :eastward_sea_water_velocity => ("uo", "med00-cmcc-cur-an-fc-d"),
    :northward_sea_water_velocity => ("vo", "med00-cmcc-cur-an-fc-d"),
)
dataset = ROMS.CMEMS(cmems_username,cmems_password,service_id,mapping,outdir)
```

"""
function CMEMS(username,password,service_id,mapping,cachedir;
               motu_server = "http://nrt.cmems-du.eu/motu-web/Motu",
               # Put here the path of the script motuclient
               motu_program = "motuclient",
)
    return CMEMS(
        username,
        password,
        service_id,
        motu_server,
        cachedir,
        motu_program,
        mapping,
    )
end

function download(ds::CMEMS,name::Symbol;
                       longitude=nothing,latitude=nothing,time=nothing)

    outdir = ds.cachedir
    var,product_id = ds.mapping[name]

    tchunk = Dates.Day(60)
    #tchunk = Dates.Day(10)

    teps = Dates.Hour(1)

    filenames = String[];
    tr = time
    xr = longitude
    yr = latitude

    for time = tr[1]:tchunk:(tr[end] + teps)
        tr2 = [time, min(time+tchunk,(tr[end]+teps) )];

        fname = "$(var)_$(time)_$(tr2[end]).nc"
        fullname = joinpath(ds.cachedir,fname)

        if !isfile(fullname)
            cmd = `$(ds.motu_program)
         -u $(ds.username)
         -p $(ds.password)
         -m $(ds.motu_server)
         -s $(ds.service_id)
         -d $product_id
         -x $(xr[1])
         -X $(xr[2])
         -y $(yr[1])
         -Y $(yr[2])
         --date-min=$(Dates.format(tr2[1],"yyyy-mm-dd HH:MM:SS"))
         --date-max=$(Dates.format(tr2[end]+teps,"yyyy-mm-dd HH:MM:SS"))
         --depth-min=0
         --depth-max=1000000
         -v $var
         -o $outdir
         -f $fname`

            #cmd = `$(ds.motu_program)`

            @debug "running $cmd"
            status = run(cmd);
        else
            @info "$fullname already in cache"
        end
        push!(filenames,fullname)
    end

    @debug "filenames $filenames"
    return filenames,var
end


"""
    v,(x,y,z,t) = ROMS.load(ds::CMEMS,name::Symbol; kwargs...)

Loads a variable from a CMEMS remote resource.
`name` is the NetCDF CF standard name.
"""
function load(ds::CMEMS,name::Symbol; kwargs...)
    filenames,var = download(ds,name; kwargs...)
    ds = NCDataset(filenames,"r",aggdim = "time")

    v = ds[var]
    x = nomissing(ds["lon"][:])
    y = nomissing(ds["lat"][:])
    t = nomissing(ds["time"][:])

    if ndims(v) == 3
        return (v,(x,y,t))
    else
        ncdepth = ds["depth"]
        z = nomissing(ncdepth[:])
        if get(ncdepth.attrib,"positive","up") == "down"
            # change vertical axis to positive up
            z = -z
        end
        return (v,(x,y,z,t))
    end
end


export load
