function defgrid(fname,xi_rho,eta_rho)
    @debug "create $fname"
    ds = NCDataset(fname,"c", attrib = OrderedDict(
        "type"                      => "GRID file",
        "history"                   => "created by $(@__FILE__)",
    ))

    # Dimensions

    ds.dim["xi_rho"] =  xi_rho;
    ds.dim["xi_u"] =  xi_rho-1;
    ds.dim["xi_v"] =  xi_rho;
    ds.dim["xi_psi"] =  xi_rho-1;
    ds.dim["eta_rho"] =  eta_rho;
    ds.dim["eta_u"] =  eta_rho;
    ds.dim["eta_v"] =  eta_rho-1;
    ds.dim["eta_psi"] =  eta_rho-1;
    ds.dim["bath"] =  1;

    # Declare variables

    ncspherical = defVar(ds,"spherical", Char, (), attrib = OrderedDict(
        "long_name"                 => "grid type logical switch",
        "option_T"                  => "spherical",
        "option_F"                  => "Cartesian",
    ))

    ncxl = defVar(ds,"xl", Float64, (), attrib = OrderedDict(
        "long_name"                 => "basin length in the XI-direction",
        "units"                     => "meter",
    ))

    ncel = defVar(ds,"el", Float64, (), attrib = OrderedDict(
        "long_name"                 => "basin length in the ETA-direction",
        "units"                     => "meter",
    ))

    ncangle = defVar(ds,"angle", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "angle between XI-axis and EAST",
        "units"                     => "radians",
        "field"                     => "angle, scalar",
        "missing_value"             => 9999.0,
    ))

    ncpm = defVar(ds,"pm", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "curvilinear coordinate metric in XI",
        "units"                     => "meter-1",
        "field"                     => "pm, scalar",
    ))

    ncpn = defVar(ds,"pn", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "curvilinear coordinate metric in ETA",
        "units"                     => "meter-1",
        "field"                     => "pn, scalar",
    ))

    ncdndx = defVar(ds,"dndx", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "XI-derivative of inverse metric factor pn",
        "units"                     => "meter",
        "field"                     => "dndx, scalar",
    ))

    ncdmde = defVar(ds,"dmde", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "ETA-derivative of inverse metric factor pm",
        "units"                     => "meter",
        "field"                     => "dmde, scalar",
    ))

    ncf = defVar(ds,"f", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "Coriolis parameter at RHO-points",
        "units"                     => "second-1",
        "field"                     => "f, scalar",
    ))

    nchraw = defVar(ds,"hraw", Float64, ("xi_rho", "eta_rho", "bath"), attrib = OrderedDict(
        "long_name"                 => "Working bathymetry at RHO-points",
        "units"                     => "meter",
        "field"                     => "hraw, scalar",
    ))

    nch = defVar(ds,"h", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "model bathymetry at RHO-points",
        "units"                     => "meter",
        "field"                     => "h, scalar",
        "missing_value"             => Float64(9999.0),
    ))

    ncx_rho = defVar(ds,"x_rho", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "X-location of RHO-points",
        "units"                     => "meter",
        "field"                     => "x_rho, scalar",
    ))

    ncy_rho = defVar(ds,"y_rho", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "Y-location of RHO-points",
        "units"                     => "meter",
        "field"                     => "y_rho, scalar",
    ))

    ncx_psi = defVar(ds,"x_psi", Float64, ("xi_psi", "eta_psi"), attrib = OrderedDict(
        "long_name"                 => "X-location of PSI-points",
        "units"                     => "meter",
        "field"                     => "x_psi, scalar",
    ))

    ncy_psi = defVar(ds,"y_psi", Float64, ("xi_psi", "eta_psi"), attrib = OrderedDict(
        "long_name"                 => "Y-location of PSI-points",
        "units"                     => "meter",
        "field"                     => "y_psi, scalar",
    ))

    ncx_u = defVar(ds,"x_u", Float64, ("xi_u", "eta_u"), attrib = OrderedDict(
        "long_name"                 => "X-location of U-points",
        "units"                     => "meter",
        "field"                     => "x_u, scalar",
    ))

    ncy_u = defVar(ds,"y_u", Float64, ("xi_u", "eta_u"), attrib = OrderedDict(
        "long_name"                 => "Y-location of U-points",
        "units"                     => "meter",
        "field"                     => "y_u, scalar",
    ))

    ncx_v = defVar(ds,"x_v", Float64, ("xi_v", "eta_v"), attrib = OrderedDict(
        "long_name"                 => "X-location of V-points",
        "units"                     => "meter",
        "field"                     => "x_v, scalar",
    ))

    ncy_v = defVar(ds,"y_v", Float64, ("xi_v", "eta_v"), attrib = OrderedDict(
        "long_name"                 => "Y-location of V-points",
        "units"                     => "meter",
        "field"                     => "y_v, scalar",
    ))

    nclon_rho = defVar(ds,"lon_rho", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "longitude of RHO-points",
        "units"                     => "degree_east",
        "field"                     => "lon_rho, scalar",
    ))

    nclat_rho = defVar(ds,"lat_rho", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "latitute of RHO-points",
        "units"                     => "degree_north",
        "field"                     => "lat_rho, scalar",
    ))

    nclon_psi = defVar(ds,"lon_psi", Float64, ("xi_psi", "eta_psi"), attrib = OrderedDict(
        "long_name"                 => "longitude of PSI-points",
        "units"                     => "degree_east",
        "field"                     => "lon_psi, scalar",
    ))

    nclat_psi = defVar(ds,"lat_psi", Float64, ("xi_psi", "eta_psi"), attrib = OrderedDict(
        "long_name"                 => "latitute of PSI-points",
        "units"                     => "degree_north",
        "field"                     => "lat_psi, scalar",
    ))

    nclon_u = defVar(ds,"lon_u", Float64, ("xi_u", "eta_u"), attrib = OrderedDict(
        "long_name"                 => "longitude of U-points",
        "units"                     => "degree_east",
        "field"                     => "lon_u, scalar",
    ))

    nclat_u = defVar(ds,"lat_u", Float64, ("xi_u", "eta_u"), attrib = OrderedDict(
        "long_name"                 => "latitute of U-points",
        "units"                     => "degree_north",
        "field"                     => "lat_u, scalar",
    ))

    nclon_v = defVar(ds,"lon_v", Float64, ("xi_v", "eta_v"), attrib = OrderedDict(
        "long_name"                 => "longitude of V-points",
        "units"                     => "degree_east",
        "field"                     => "lon_v, scalar",
    ))

    nclat_v = defVar(ds,"lat_v", Float64, ("xi_v", "eta_v"), attrib = OrderedDict(
        "long_name"                 => "latitute of V-points",
        "units"                     => "degree_north",
        "field"                     => "lat_v, scalar",
    ))

    ncmask_rho = defVar(ds,"mask_rho", Float64, ("xi_rho", "eta_rho"), attrib = OrderedDict(
        "long_name"                 => "mask on RHO-points",
        "option_0"                  => "land",
        "option_1"                  => "water",
        "units"                     => "nondimensional",
        "field"                     => "mask_rho, scalar",
    ))

    ncmask_psi = defVar(ds,"mask_psi", Float64, ("xi_psi", "eta_psi"), attrib = OrderedDict(
        "long_name"                 => "mask on PSI-points",
        "option_0"                  => "land",
        "option_1"                  => "water",
        "units"                     => "nondimensional",
        "field"                     => "mask_psi, scalar",
    ))

    ncmask_u = defVar(ds,"mask_u", Float64, ("xi_u", "eta_u"), attrib = OrderedDict(
        "long_name"                 => "mask on U-points",
        "option_0"                  => "land",
        "option_1"                  => "water",
        "units"                     => "nondimensional",
        "field"                     => "mask_u, scalar",
    ))

    ncmask_v = defVar(ds,"mask_v", Float64, ("xi_v", "eta_v"), attrib = OrderedDict(
        "long_name"                 => "mask on V-points",
        "option_0"                  => "land",
        "option_1"                  => "water",
        "units"                     => "nondimensional",
        "field"                     => "mask_v, scalar",
    ))

    return ds
end
