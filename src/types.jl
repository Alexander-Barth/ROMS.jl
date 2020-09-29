struct Grid{T,TAB}
    grid_fname::String
    Tcline::T
    theta_s::T
    theta_b::T
    nlevels::Int
    Vtransform::Int
    Vstretching::Int
    hmin::T
    hc::T
    h::Array{T,2}
    h_u::Array{T,2}
    h_v::Array{T,2}
    h_psi::Array{T,2}
    mask::TAB
    mask_u::TAB
    mask_v::TAB
    mask_psi::TAB
    pm::Array{T,2}
    pm_u::Array{T,2}
    pm_v::Array{T,2}
    pm_psi::Array{T,2}
    pn::Array{T,2}
    pn_u::Array{T,2}
    pn_v::Array{T,2}
    pn_psi::Array{T,2}
    lon::Array{T,2}
    lon_u::Array{T,2}
    lon_v::Array{T,2}
    lon_psi::Array{T,2}
    lat::Array{T,2}
    lat_u::Array{T,2}
    lat_v::Array{T,2}
    lat_psi::Array{T,2}
    angle::Array{T,2}
    angle_u::Array{T,2}
    angle_v::Array{T,2}
    angle_psi::Array{T,2}
    z_r::Array{T,3}
    z_u::Array{T,3}
    z_v::Array{T,3}
    z_w::Array{T,3}
end

"""
    grid = ROMS.Grid(grid_fname,opt)

Note
grid.z is for an elevation equal to zero.

Example

```julia
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)
grid = ROMS.Grid(expanduser("~/Models/LS2v/LS2v.nc"),opt)
```
"""
function Grid(grid_fname,opt)
    T = Float64
    Tcline      = T(opt.Tcline)
    theta_s     = T(opt.theta_s)
    theta_b     = T(opt.theta_b)
    nlevels     = opt.nlevels
    Vtransform  = opt.Vtransform
    Vstretching = opt.Vstretching

    ds = Dataset(grid_fname,"r")
    h = nomissing(ds["h"][:,:])
    mask = Bool.(nomissing(ds["mask_rho"][:,:]))
    mask_u = Bool.(nomissing(ds["mask_u"][:,:]))
    mask_v = Bool.(nomissing(ds["mask_v"][:,:]))
    mask_psi = Bool.(nomissing(ds["mask_psi"][:,:]))
    pm = nomissing(ds["pm"][:,:])
    pn = nomissing(ds["pn"][:,:])
    lon = nomissing(ds["lon_rho"][:,:])
    lat = nomissing(ds["lat_rho"][:,:])
    lon_u = nomissing(ds["lon_u"][:,:])
    lat_u = nomissing(ds["lat_u"][:,:])
    lon_v = nomissing(ds["lon_v"][:,:])
    lat_v = nomissing(ds["lat_v"][:,:])
    lon_psi = nomissing(ds["lon_psi"][:,:])
    lat_psi = nomissing(ds["lat_psi"][:,:])
    angle = nomissing(ds["angle"][:,:])
    close(ds)

    hmin = minimum(h)
    hc = min(hmin,Tcline)

    z_r = set_depth(Vtransform, Vstretching,
                    theta_s, theta_b, hc, nlevels,
                    1, h,
                    zeta = zeros(size(h)),
                    report = false)

    z_w = set_depth(Vtransform, Vstretching,
                    theta_s, theta_b, hc, nlevels,
                    5, h,
                    zeta = zeros(size(h)),
                    report = false)

    angle_u,angle_v,angle_psi = stagger(angle)

    h_u,h_v,h_psi = stagger(h)
    pm_u,pm_v,pm_psi = stagger(pm)
    pn_u,pn_v,pn_psi = stagger(pn)

    z_u = stagger_r2u(z_r)
    z_v = stagger_r2v(z_r)

    h_u = stagger_r2u(h)
    h_v = stagger_r2v(h)

    return Grid(
        grid_fname,
        Tcline,
        theta_s,
        theta_b,
        nlevels,
        Vtransform,
        Vstretching,
        hmin,
        hc,
        h,
        h_u,
        h_v,
        h_psi,
        mask,
        mask_u,
        mask_v,
        mask_psi,
        pm,
        pm_u,
        pm_v,
        pm_psi,
        pn,
        pn_u,
        pn_v,
        pn_psi,
        lon,
        lon_u,
        lon_v,
        lon_psi,
        lat,
        lat_u,
        lat_v,
        lat_psi,
        angle,
        angle_u,
        angle_v,
        angle_psi,
        z_r,
        z_u,
        z_v,
        z_w,
    )

end
