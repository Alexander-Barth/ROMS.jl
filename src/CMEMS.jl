Base.getindex(ds::AbstractDataset,name::Symbol) = DatasetVariable(ds,name)

load(dv::DatasetVariable; kwargs...) = load(dv.ds,dv.name; kwargs...)
download(dv::DatasetVariable; kwargs...) = download(dv.ds,dv.name; kwargs...)


function copernicus_marine_resolve(
    product_id,dataset_id;
    asset_name = "timeChunked",
    catalog_url = "https://stac.marine.copernicus.eu/metadata/catalog.stac.json")

    cat = STAC.Catalog(catalog_url);
    item_canditates = sort(filter(startswith(dataset_id),keys(cat[product_id].items)))
    # use last version per default
    dataset_version_id = item_canditates[end]
    item = cat[product_id].items[dataset_version_id]
    return STAC.href(item.assets[asset_name])
end


"""
    ds = ROMS.CMEMS_zarr(product_id,mapping,cachedir;
                    chunks = 60,
                    time_shift = 0,
                    kwargs...
                    )

Returns a structure `ds` to connect to a CMEMS zarr server.
The `mapping` parameter contains a dictorary linking the NetCDF CF standard namer
to the underlying NetCDF variable names and the product identifers (more
information is available in the product user manual).
`cachedir` is a directory where the products are downloaded for caching.

While for most datasets (and CMEMS in the past) the time
represents the central time the time axis. However since 2024, the time in
the CMEMS Zarr data represents now the beginning of the time interval.
Therefore `time_shift` has to be
added to the time variable to account for this difference.
For example, if for a daily dataset, the first time instance is the average from
2000-01-01:00:00:00 to 2000-01-02:00:00:00, then the Zarr file records
`2000-01-01:00:00:00` (the beginning for the averaging interval) rather than
`2000-01-01:12:00:00` (the center for the averaging interval). In this case,
`time_shift` should be `12*60*60` (12 hours in seconds).


## Example

The  values of `product_id` and `mapping` (with `dataset_id`)  below are specific to the
Mediterranean Sea and must be adapted for other domains.

```julia
outdir = "/tmp"
product_id = "MEDSEA_MULTIYEAR_PHY_006_004"
mapping = Dict(
    # var  dataset_id
    :sea_surface_height_above_geoid => "med-cmcc-ssh-an-fc-d",
    :sea_water_potential_temperature => "med-cmcc-tem-an-fc-d",
    :sea_water_salinity => "med-cmcc-sal-an-fc-d",
    :eastward_sea_water_velocity => "med-cmcc-cur-an-fc-d",
    :northward_sea_water_velocity => "med-cmcc-cur-an-fc-d",
)

dataset = ROMS.CMEMS_zarr(product_id,mapping,outdir,time_shift = 12*60*60)
```

"""
function CMEMS_zarr(product_id,mapping,cachedir;
                    chunks = 60,
                    time_shift = 0, # time shift in seconds as Int
                    kwargs...
                    )

    urls = DefaultDict{Symbol,String,String}("unknown")
    for (k,v) in mapping
        dataset_id =
            if (length(v) > 1) && v isa Tuple
                v[end]
            else
                v
            end
        urls[k] = copernicus_marine_resolve(product_id,dataset_id; kwargs...)
    end


    dataset = CDMDataset(
        ZarrDataset,
        urls,
        cachedir = cachedir,
        options = Dict(:_omitcode => [404,403]),
        time_shift = time_shift,
        chunks = chunks)

    return dataset
end
