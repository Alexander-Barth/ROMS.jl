function def_ic(icname,domain,missing_value;
                     time_origin = DateTime(1858,11,17))

    xi_rho = size(domain.z_r,1);
    eta_rho = size(domain.z_r,2);
    s_rho = size(domain.z_r,3);

    # dimensions

    ds = NCDataset(icname,"c", attrib = OrderedDict(
        "type"                      => "INITIALIZATION file",
    ))

    # Dimensions

    ds.dim["xi_rho"] = xi_rho
    ds.dim["xi_u"] = xi_rho-1
    ds.dim["xi_v"] = xi_rho
    ds.dim["eta_rho"] = eta_rho
    ds.dim["eta_u"] = eta_rho
    ds.dim["eta_v"] = eta_rho-1
    ds.dim["s_rho"] = s_rho
    ds.dim["s_w"] = s_rho+1
    ds.dim["tracer"] = 2
    ds.dim["time"] = Inf # unlimited dimension

    time_origin
    # Declare variables

    ncocean_time = defVar(ds,"ocean_time", Float64, ("time",), attrib = OrderedDict(
        "long_name"                 => "time since initialization",
        "units"                     => "days since $(Dates.format(time_origin,"yyyy-mm-dd HH:MM:SS"))",
        "field"                     => "time, scalar, series",
        "missing_value"             => missing_value,
    ))

    nczeta = defVar(ds,"zeta", Float32, ("xi_rho", "eta_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "free-surface",
        "units"                     => "meter",
        "field"                     => "free-surface, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    ncubar = defVar(ds,"ubar", Float32, ("xi_u", "eta_u", "time"), attrib = OrderedDict(
        "long_name"                 => "vertically integrated u-momentum component",
        "units"                     => "meter second-1",
        "field"                     => "ubar-velocity, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    ncvbar = defVar(ds,"vbar", Float32, ("xi_v", "eta_v", "time"), attrib = OrderedDict(
        "long_name"                 => "vertically integrated v-momentum component",
        "units"                     => "meter second-1",
        "field"                     => "vbar-velocity, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    ncu = defVar(ds,"u", Float32, ("xi_u", "eta_u", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "u-momentum component",
        "units"                     => "meter second-1",
        "field"                     => "u-velocity, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    ncv = defVar(ds,"v", Float32, ("xi_v", "eta_v", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "v-momentum component",
        "units"                     => "meter second-1",
        "field"                     => "v-velocity, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    nctemp = defVar(ds,"temp", Float32, ("xi_rho", "eta_rho", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "potential temperature",
        "units"                     => "Celsius",
        "field"                     => "temperature, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))

    ncsalt = defVar(ds,"salt", Float32, ("xi_rho", "eta_rho", "s_rho", "time"), attrib = OrderedDict(
        "long_name"                 => "salinity",
        "units"                     => "PSU",
        "field"                     => "salinity, scalar, series",
        "time"                      => "ocean_time",
        "missing_value"             => Float32(missing_value),
        "_FillValue"                => Float32(missing_value),
    ))


    return ds
end
