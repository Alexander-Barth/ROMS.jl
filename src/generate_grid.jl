"""
    ROMS.generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax)


Generate the netCDF file `grid_fname` representing the model grid from the
bathymetry file `bath_name`. The domain is bounded by the longitude range `xr`
and the latitude range `yr`. The resolution of the bathymetry is reduced by the
factors `red[1]` and `red[2]` in the longitude and latitude directions. `opt` is
tuple with additional parameters describing the vertical axis. `hmin` and `rmax`
is the minimum depth and `rmax` is the smoothness parameter of the bathymetry.
The ``r`` parameter is defined as:

``
r = \\max\\left( \\underset{ij}{\\max} \\frac{|h_{i,j} - h_{i+1,j}|}{h_{i,j} + h_{i+1,j}},
 \\underset{ij}{\\max} \\frac{|h_{i,j} - h_{i,j+1}|}{h_{i,j} + h_{i,j+1}} \\right)
``

The parameter `opt` contains for example:

```julia
# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)
```

"""
function generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax;
                       postprocess_mask = (x,y,mask) -> mask)

    xo,yo,bo = ROMS.gebco_load(bath_name,xr,yr);

    x = ROMS.reduce_res(xo,(red[1],))
    y = ROMS.reduce_res(yo,(red[2],))
    b = ROMS.reduce_res(bo,(red[1],red[2]));


    # lat/lon grid

    dx = x[2]-x[1];
    dy = y[2]-y[1];

    x,y = DIVAnd.ndgrid(x,y);

    dxs = pi * earthradius * dx * cos.(y*pi/180) / 180;
    dys = pi * earthradius * dy / 180;

    pm = ones(size(x)) ./ dxs;
    pn = ones(size(x)) ./ dys;

    # from seagrid
    # dmde(1,:),... remain zero????

    dmde = zeros(size(pm));
    dndx = zeros(size(pn));

    dmde[2:end-1, :] = 0.5*(1 ./ pm[3:end, :] - 1 ./ pm[1:end-2, :]);
    dndx[:, 2:end-1] = 0.5*(1 ./ pn[:, 3:end] - 1 ./ pn[:, 1:end-2]);

    # mask
    mask = b .< 0;

    # avoid isolated sea points at boundary
    mask[:,1] =   mask[:,1]   .& mask[:,2]
    mask[:,end] = mask[:,end] .& mask[:,end-1]
    mask[1,:] =   mask[1,:]   .& mask[2,:]
    mask[end,:] = mask[end,:] .& mask[end-1,:]


    mask = postprocess_mask(x,y,mask)

    b[b .> 0] .= 0;
    b = -b;

    # smooth bathymetry

    h = ROMS.smoothgrid(b,hmin,rmax);

    # generate bathymetry file

    z_r,z_w = ROMS.generate_config(grid_fname,x,y,h,mask,pm,pn,dndx,dmde,opt);

    domain = ROMS.Grid(grid_fname);
    return domain
end
