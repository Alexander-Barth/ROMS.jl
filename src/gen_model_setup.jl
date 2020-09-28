
# setup dir

mkpath(basedir);
mkpath(modeldir);


xo,yo,bo = ROMS.gebco_load(bath_name,xr,yr);

x = ROMS.reduce_res(xo,(red[1],))
y = ROMS.reduce_res(yo,(red[2],))
b = ROMS.reduce_res(bo,(red[1],red[2]));


# lat/lon grid

dx = x[2]-x[1];
dy = y[2]-y[1];

using DIVAnd
x,y = DIVAnd.ndgrid(x,y);

dxs = pi * R0 * dx * cos.(y*pi/180) / 180;
dys = pi * R0 * dy / 180;

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

z_r,z_w = ROMS.roms_generate_config(x,y,h,mask,pm,pn,dndx,dmde,opt);


# x,y,

# grid is not rotated
angle = zeros(size(x));



mkpath(basedir);
domain = ROMS.Grid(opt[:grid_fname],opt);

outdir = joinpath(basedir,"OGCM")
mkpath(outdir)


dataset = ROMS.CMEMS(cmems_username,cmems_password,outdir)

#=
ds_zeta = dataset[:sea_surface_height_above_geoid]

download(ds_zeta,longitude=xr,latitude=yr,time=tr)

sv,(sx,sy,st) = load(ds_zeta,longitude=xr,latitude=yr,time=tr)
=#

#if bc_model == "hycom"
#  roms_prep_clim_hycom(domain,clim_filename,[t0:1:t1],basedir);
#elseif bc_model == "mfs"
    tr = [t0, t1]
    time = tr[1]:bc_dt:tr[end]
    ROMS.roms_interp_clim4(clim_filename,domain,dataset,tr)
#end


#ROMS.extract_ic(domain,clim_filename,ic_filename, t0);

#=

# nccreate(parent_data,"theta_s")
# ncwriteatt(parent_data,"theta_s","long_name","S-coordinate surface control parameter")
# ncwrite(parent_data,"theta_s",opt.theta_s)

# nccreate(parent_data,"theta_b")
# ncwriteatt(parent_data,"theta_b","long_name","S-coordinate bottom control parameter")
# ncwrite(parent_data,"theta_b",opt.theta_b)

# nccreate(parent_data,"Tcline")
# ncwriteatt(parent_data,"Tcline","long_name","S-coordinate surface/bottom layer width")
# ncwriteatt(parent_data,"Tcline","units","meter")
# ncwrite(parent_data,"Tcline",opt.Tcline)

# nccreate(parent_data,"hc")
# ncwriteatt(parent_data,"hc","long_name","S-coordinate parameter, critical depth")
# ncwriteatt(parent_data,"hc","units","meter")
# ncwrite(parent_data,"hc",opt.Tcline)


roms_extract_bc(domain,clim_filename,bc_filename);


=#
