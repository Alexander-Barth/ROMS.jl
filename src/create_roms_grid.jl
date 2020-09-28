"""
    Non-rotated grids
"""
function create_roms_grid(fname,h,f,lon_r,lat_r,mask_r,angle,pm,pn,dndx,dmde)
    @assert all(angle .== 0)

    xi_rho,eta_rho = size(h)

    rm(fname)
    ds = defgrid(fname,xi_rho,eta_rho)

    mask_u,mask_v,mask_psi = stagger_mask(mask_r)
    lon_u,lon_v,lon_psi = stagger(lon_r)
    lat_u,lat_v,lat_psi = stagger(lat_r)

    m = pi/180 * earthradius

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

    ds["x_rho"][:] = x_rho * m
    ds["y_rho"][:] = y_rho * m

    ds["x_psi"][:] = x_psi * m
    ds["y_psi"][:] = y_psi * m

    ds["x_u"][:] = x_u * m
    ds["y_u"][:] = y_u * m

    ds["x_v"][:] = x_v * m
    ds["y_v"][:] = y_v * m

    @debug "closing"
    close(ds)
end
