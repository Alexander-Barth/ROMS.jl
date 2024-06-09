"""
    ROMS.create_grid(fname,h,f,lon_r,lat_r,mask_r,angle,pm,pn,dndx,dmde)

Create a NetCDF grid file `fname` using the bathymetry `h`, Coriolis parameter
`f` and longitude, latitude, mask, angle and strechting factors are rho-points.

!!! note
    This function currently only works for non-rotated grids (angle = 0) and
    the spherical grids.
"""
function create_grid(fname,h,f,lon_r,lat_r,mask_r,angle,pm,pn,dndx,dmde)
    @assert all(angle .== 0)

    xi_rho,eta_rho = size(h)

    if isfile(fname)
       rm(fname)
    end

    ds = def_grid(fname,xi_rho,eta_rho)

    mask_u,mask_v,mask_psi = stagger_mask(mask_r)
    lon_u,lon_v,lon_psi = stagger(lon_r)
    lat_u,lat_v,lat_psi = stagger(lat_r)

    x_rho,y_rho = map_to_grid(lon_r,lat_r,0,0)
    x_u,y_u = map_to_grid(lon_u,lat_u,0.5,0)
    x_v,y_v = map_to_grid(lon_v,lat_v,0,0.5)
    x_psi,y_psi = map_to_grid(lon_psi,lat_psi,0.5,0.5)

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

    ds["x_rho"][:] = x_rho
    ds["y_rho"][:] = y_rho

    ds["x_psi"][:] = x_psi
    ds["y_psi"][:] = y_psi

    ds["x_u"][:] = x_u
    ds["y_u"][:] = y_u

    ds["x_v"][:] = x_v
    ds["y_v"][:] = y_v


    @debug "closing"
    close(ds)
end
