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
service_id = "MEDSEA_ANALYSISFORECAST_PHY_006_013-TDS"
mapping = Dict(
    # var  product_id
    :sea_surface_height_above_geoid => ("zos","med-cmcc-ssh-an-fc-d"),
    :sea_water_potential_temperature => ("thetao", "med-cmcc-tem-an-fc-d"),
    :sea_water_salinity => ("so","med-cmcc-sal-an-fc-d"),
    :eastward_sea_water_velocity => ("uo", "med-cmcc-cur-an-fc-d"),
    :northward_sea_water_velocity => ("vo", "med-cmcc-cur-an-fc-d"),
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
         --user $(ds.username)
         --pwd $(ds.password)
         --motu $(ds.motu_server)
         --service-id $(ds.service_id)
         --product-id $product_id
         --longitude-min $(xr[1])
         --longitude-max $(xr[2])
         --latitude-min $(yr[1])
         --latitude-max $(yr[2])
         --date-min=$(Dates.format(tr2[1],"yyyy-mm-dd HH:MM:SS"))
         --date-max=$(Dates.format(tr2[end]+teps,"yyyy-mm-dd HH:MM:SS"))
         --depth-min=0
         --depth-max=1000000
         --variable $var
         --out-dir $outdir
         --out-name $fname`

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

    x = nomissing(varbyattrib(ds,standard_name = "longitude")[1][:]);
    y = nomissing(varbyattrib(ds,standard_name = "latitude")[1][:]);
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


# form
# https://my.cmems-du.eu/thredds/dodsC/med-cmcc-ssh-rean-d.html
# opendap url
# https://my.cmems-du.eu/thredds/dodsC/med-cmcc-ssh-rean-d

function CMEMS_opendap(username,password,mapping,cachedir;
                baseurl = "https://my.cmems-du.eu/thredds/dodsC",
                chunks = 60,
)

    username_escaped = URIs.escapeuri(username)
    password_escaped = URIs.escapeuri(password)
    userinfo = string(username_escaped,":",password_escaped)
    baseURI = URI(URI(baseurl),userinfo=userinfo)

    urls = DefaultDict{Symbol,String,String}("unknown")
    for (k,v) in mapping
        dataset_id =
            if length(v) > 1
                v[end]
            else
                v
            end
        urls[k] = string(URI(baseURI,path=joinpath(baseURI.path,dataset_id)))
    end

    return OPENDAP{NCDataset}(
        urls,cachedir,
        Dict{Symbol,String}(),
        chunks)
end
