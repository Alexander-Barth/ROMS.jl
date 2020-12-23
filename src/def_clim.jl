function def_clim(fname,missing_value,xi_rho,eta_rho,s_rho)
    if isfile(fname)
        rm(fname)
    end
    ds = NCDataset(fname,"c", attrib = OrderedDict(
        "type"                      => "CLIMATOLOGY file",
    ))

    # Dimensions
    ds.dim["time"] = Inf # unlimited dimension
    ds.dim["xi_rho"] = xi_rho
    ds.dim["eta_rho"] = eta_rho
    ds.dim["s_rho"] = s_rho
    ds.dim["xi_u"] = xi_rho-1
    ds.dim["eta_u"] = eta_rho
    ds.dim["xi_v"] = xi_rho
    ds.dim["eta_v"] = eta_rho-1

    # Declare variables

    nctime = defVar(ds,"time", Float64, ("time",), attrib = OrderedDict(
        "long_name"                 => "time",
        "units"                     => "days since 1858-11-17 00:00:00",
        "field"                     => "time, scalar, series",
    ))

    nczeta = defVar(ds,"zeta", Float32, ("xi_rho", "eta_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "free-surface",
        "units"                     => "meter",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
    ))

    nctemp = defVar(ds,"temp", Float32, ("xi_rho", "eta_rho", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "potential temperature",
        "units"                     => "Celsius",
        "field"                     => "temperature, scalar, series",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    ncsalt = defVar(ds,"salt", Float32, ("xi_rho", "eta_rho", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "salinity",
        "units"                     => "PSU",
        "field"                     => "salinity, scalar, series",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    ncu = defVar(ds,"u", Float32, ("xi_u", "eta_u", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "u-momentum component",
        "units"                     => "meter second-1",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    ncv = defVar(ds,"v", Float32, ("xi_v", "eta_v", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "v-momentum component",
        "units"                     => "meter second-1",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    ncubar = defVar(ds,"ubar", Float32, ("xi_u", "eta_u", "time"), attrib = OrderedDict(
        "long_name"                 => "2D u-momentum component",
        "units"                     => "meter second-1",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    ncvbar = defVar(ds,"vbar", Float32, ("xi_v", "eta_v", "time"), attrib = OrderedDict(
        "long_name"                 => "2D v-momentum component",
        "units"                     => "meter second-1",
        "time"                      => "time",
        "_FillValue"                => Float32(missing_value),
        "missing_value"             => Float32(missing_value),
    ))

    return ds
end
