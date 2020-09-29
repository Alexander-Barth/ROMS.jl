function generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax; do_plot = false)

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

# aspect ratio for plotting
ar = [1  cos(mean(y[:]) * pi/180) 1];

# mask

mask = b .< 0;

# avoid isolated sea points at boundary
mask[:,1] =   mask[:,1]   .& mask[:,2]
mask[:,end] = mask[:,end] .& mask[:,end-1]
mask[1,:] =   mask[1,:]   .& mask[2,:]
mask[end,:] = mask[end,:] .& mask[end-1,:]


b[b .> 0] .= 0;
b = -b;

if do_plot
    field = copy(b)
    field[.!mask] .= NaN;
    figure(),pcolor(x,y,field),
    colorbar()
    title("Bathymetry")
    #set(gca,'DataAspectRatio',ar, 'Layer', 'top')
end

# smooth bathymetry

h = ROMS.smoothgrid(b,hmin,rmax);

if do_plot
    field = copy(b)
    field[.!mask] .= NaN
    figure(),pcolor(x,y,field)
    title("Bathymetry (smooth)")
    #set(gca,'DataAspectRatio',ar, 'Layer', 'top')
end

# generate bathymetry file

z_r,z_w = ROMS.roms_generate_config(grid_fname,x,y,h,mask,pm,pn,dndx,dmde,opt);


end
