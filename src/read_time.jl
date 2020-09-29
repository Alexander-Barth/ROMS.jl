function read_time(ds::NCDatasets.NCDataset)
    return (haskey(ds,"time") ? ds["time"] : ds["ocean_time"])[:]
end

function read_time(fname::AbstractString)
    NCDataset(fname) do ds
        return read_time(ds)
    end
end
