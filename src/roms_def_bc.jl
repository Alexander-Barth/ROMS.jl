# domain.z_r and domain.mask

function roms_def_bc(bc_filename,domain,missing_value;
                     time_origin = DateTime(1858,11,17))

    xi_rho = size(domain.z_r,1)
    eta_rho = size(domain.z_r,2)
    s_rho = size(domain.z_r,3)
    mask = domain.mask

    directions = String[];

    if any(mask[2:end-1,1]);    push!(directions,"south");  end
    if any(mask[2:end-1,end]);  push!(directions,"north");  end
    if any(mask[1,2:end-1]);    push!(directions,"west");   end
    if any(mask[end,2:end-1]);  push!(directions,"east");   end


    ds = NCDataset(bc_filename,"c", attrib = OrderedDict(
        "type"                      => "BOUNDARY FORCING file",
    ))

    # dimensions

    ds.dim["xi_rho"] = xi_rho
    ds.dim["xi_u"] = xi_rho-1
    ds.dim["xi_v"] = xi_rho
    ds.dim["eta_rho"] = eta_rho
    ds.dim["eta_u"] = eta_rho
    ds.dim["eta_v"] = eta_rho-1
    ds.dim["s_rho"] = s_rho
    ds.dim["time"] = Inf # unlimited dimension

    # Declare variables

    nctime = defVar(ds,"time", Float64, ("time",), attrib = OrderedDict(
        "long_name"                 => "time",
        "units"                     => "days since $(Dates.format(time_origin,"yyyy-mm-dd HH:MM:SS"))",
        "field"                     => "temp_time, scalar, series",
        "missing_value"             => Float64(missing_value),
    ))

    T = Float64

    for direction in directions
        if (direction == "south") || (direction == "north")
            dim_rho = "xi_rho"
            dim_u = "xi_u"
            dim_v = "xi_v"
        else
            dim_rho = "eta_rho"
            dim_u = "eta_u"
            dim_v = "eta_v"
        end

        nczeta = defVar(ds,"zeta_" * direction, Float64, (dim_rho, "time"), attrib = OrderedDict(
            "long_name"                 => "free-surface $(direction)ern boundary condition",
            "units"                     => "meter",
            "field"                     => "zeta_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => Float64(missing_value),
            "_FillValue"                => Float64(missing_value),
        ))

        ncubar = defVar(ds,"ubar_" * direction, T, (dim_u, "time"), attrib = OrderedDict(
            "long_name"                 => "2D u-momentum $(direction)ern boundary condition",
            "units"                     => "meter second-1",
            "field"                     => "ubar_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

        ncvbar = defVar(ds,"vbar_" * direction, T, (dim_v, "time"), attrib = OrderedDict(
            "long_name"                 => "2D v-momentum $(direction)ern boundary condition",
            "units"                     => "meter second-1",
            "field"                     => "vbar_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

        nctemp = defVar(ds,"temp_" * direction, T, (dim_rho, "s_rho", "time"), attrib = OrderedDict(
            "long_name"                 => "potential temperature $(direction)ern boundary condition",
            "units"                     => "Celsius",
            "field"                     => "temp_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

        ncsalt = defVar(ds,"salt_" * direction, T, (dim_rho, "s_rho", "time"), attrib = OrderedDict(
            "long_name"                 => "salinity $(direction)ern boundary condition",
            "units"                     => "PSU",
            "field"                     => "salt_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

        ncu = defVar(ds,"u_" * direction, T, (dim_u, "s_rho", "time"), attrib = OrderedDict(
            "long_name"                 => "3D u-momentum $(direction)ern boundary condition",
            "units"                     => "meter second-1",
            "field"                     => "u_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

        ncv = defVar(ds,"v_" * direction, T, (dim_v, "s_rho", "time"), attrib = OrderedDict(
            "long_name"                 => "3D v-momentum $(direction)ern boundary condition",
            "units"                     => "meter second-1",
            "field"                     => "v_$(direction), scalar, series",
            "time"                      => "time",
            "missing_value"             => T(missing_value),
            "_FillValue"                => T(missing_value),
        ))

    end

    return ds
end
