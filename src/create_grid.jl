"""
    ROMS.create_grid(fname,h,f,lon_r,lat_r,mask_r,angle,pm,pn,dndx,dmde)

Create a NetCDF grid file `fname` using the bathymetry `h`, Coriolis parameter
`f` and longitude, latitude, mask, angle and strechting factors are rho-points.

!!! note
    This function currently only works for non-rotated grids (angle = 0) and
    the spherical grids.
"""
function create_grid(fname,h,f,lon_r,lat_r,mask_r,angle,pm,pn,dndx,dmde;
                     opt = nothing,
                     attribs = Dict(),
                     )
    @assert all(angle .== 0)

    xi_rho,eta_rho = size(h)

    if isfile(fname)
       rm(fname)
    end

    ds = def_grid(fname,xi_rho,eta_rho)

    mask_u,mask_v,mask_psi = stagger_mask(mask_r)
    lon_u,lon_v,lon_psi = stagger(lon_r)
    lat_u,lat_v,lat_psi = stagger(lat_r)

    x_rho,y_rho = sg_mercator(lon_r,lat_r)
    x_psi,y_psi = sg_mercator(lon_psi,lat_psi)
    x_u,y_u = sg_mercator(lon_u,lat_u)
    x_v,y_v = sg_mercator(lon_v,lat_v)

    ds["spherical"][:] = 'T'
    ds["lat_rho"][:] = lat_r
    ds["lat_u"][:] = lat_u
    ds["lat_v"][:] = lat_v
    ds["lat_psi"][:] = lat_psi

    ds["lon_rho"][:] = lon_r
    ds["lon_u"][:] = lon_u
    ds["lon_v"][:] = lon_v
    ds["lon_psi"][:] = lon_psi

    ds["hraw"][:,:,1] = h
    ds["h"][:] = h

    ds["angle"][:] = angle

    ds["xl"][:] = sum(1 ./ pm[:,1])
    ds["el"][:] = sum(1 ./ pn[1,:])

    ds["f"][:] = f
    ds["pm"][:] = pm
    ds["pn"][:] = pn

    ds["dndx"][:] = dndx
    ds["dmde"][:] = dmde

    ds["mask_rho"][:] = mask_r
    ds["mask_u"][:] = mask_u
    ds["mask_v"][:] = mask_v
    ds["mask_psi"][:] = mask_psi

    ds["x_rho"][:] = x_rho * earthradius
    ds["y_rho"][:] = y_rho * earthradius

    ds["x_psi"][:] = x_psi * earthradius
    ds["y_psi"][:] = y_psi * earthradius

    ds["x_u"][:] = x_u * earthradius
    ds["y_u"][:] = y_u * earthradius

    ds["x_v"][:] = x_v * earthradius
    ds["y_v"][:] = y_v * earthradius

    if !isnothing(opt)
        defVar(ds,"Tcline",Float64(opt.Tcline))
        defVar(ds,"theta_s", Float64(opt.theta_s))
        defVar(ds,"theta_b", Float64(opt.theta_b))
        defDim(ds,"s_rho", opt.nlevels)
        defVar(ds,"Vtransform", Int32(opt.Vtransform))
        defVar(ds,"Vstretching", Int32(opt.Vstretching))
    end

    # global attributes
    for (k,v) in attribs
        ds.attrib[k] = v
    end
    @debug "closing"
    close(ds)
end
