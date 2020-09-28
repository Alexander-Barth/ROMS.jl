function roms_read_time(ds::NCDatasets.NCDataset)
    return (haskey(ds,"time") ? ds["time"] : ds["ocean_time"])[:]
end

function roms_read_time(fname::AbstractString)
    NCDataset(fname) do ds
        return roms_read_time(ds)
    end
end
