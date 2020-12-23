function def_nudgecoef(fname,xi_rho,eta_rho,s_rho)
    if isfile(fname)
        rm(fname)
    end
    ds = NCDataset(fname,"c")

    # Dimensions

    ds.dim["xi_rho"] = xi_rho
    ds.dim["eta_rho"] = eta_rho
    ds.dim["s_rho"] = s_rho

    # Declare variables

    nctracer_NudgeCoef = defVar(ds,"tracer_NudgeCoef", Float64, ("xi_rho", "eta_rho", "s_rho"), attrib = OrderedDict(
        "long_name"                 => "generic tracer inverse nudging coefficients",
        "units"                     => "day-1",
        "coordinates"               => "xi_rho eta_rho s_rho ",
    ))

    return ds
end
