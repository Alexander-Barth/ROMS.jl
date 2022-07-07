function def_forcing(outfname,lon,lat,Vname,Tname,ncattrib,ncattrib_time,
                     time_origin;
                     title = "ECMWF ERA-Interim Dataset, $domain_name",
                     )


    if isfile(outfname)
        ds = NCDataset(outfname,"a")
    else
        ds = NCDataset(outfname,"c", attrib = OrderedDict(
            "type"                      => "FORCING file",
            "history"                   => "Forcing file created with $(@__FILE__) on $(Dates.format(Dates.now(),"E - U d, yyyy - HH:MM:SS.sss"))",
        ))

        if title !== ""
            ds.attrib["title"] = title
        end
        # Dimensions

        ds.dim["lon"] = length(lon)
        ds.dim["lat"] = length(lat)
        ds.dim[Tname] = Inf # unlimited dimension

        # Declare variables

        ncspherical = defVar(ds,"spherical", Int32, (), attrib = OrderedDict(
            "long_name"                 => "grid type logical switch",
            "flag_values"               => Int32[0, 1],
            "flag_meanings"             => "Cartesian spherical",
        ))

        nclon = defVar(ds,"lon", Float64, ("lon", "lat"), attrib = OrderedDict(
            "long_name"                 => "longitude",
            "units"                     => "degree_east",
            "standard_name"             => "longitude",
        ))

        nclat = defVar(ds,"lat", Float64, ("lon", "lat"), attrib = OrderedDict(
            "long_name"                 => "latitude",
            "units"                     => "degree_north",
            "standard_name"             => "latitude",
        ))

        ncfield_time = defVar(ds,Tname, Float64, (Tname,), attrib = ncattrib_time)

    end

    ncfield = defVar(ds,Vname, Float32, ("lon", "lat", Tname), attrib = ncattrib)

    return ds

end
