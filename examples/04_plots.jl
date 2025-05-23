# # Plotting ROMS results and input files

#md # *The code here is also available as a notebook [04\_plots.ipynb](04_plots.ipynb).*
#
# The aim here is to visualize the model files with generic plotting and analsis packages rather than to use a model specific visualization tool which hides many details and might lack of flexibility.
# The necessary files are already in the directory containing the model simulation and its
# parent direction (`ROMS-implementation-test`). Downloading the files is only needed if you did not run the simulation.

grd_name = "roms_grd_liguriansea.nc"

if !isfile(grd_name)
    download("https://dox.ulg.ac.be/index.php/s/J9DXhUPXbyLADJa/download",grd_name)
end

fname = "roms_his.nc"
if !isfile(fname)
    download("https://dox.ulg.ac.be/index.php/s/17UWsY7tRNMDf4w/download",fname)
end

# ## Bathymetry

# In this example, the bathymetry defined in the grid file is visualized. Make sure that your current working directory
# contains the file `roms_grd_liguriansea.nc` (use e.g. `;cd ~/ROMS-implementation-test`)

using ROMS, NCDatasets, GeoDatasets, Statistics
using PyPlot

ds_grid = NCDataset("roms_grd_liguriansea.nc");
lon = ds_grid["lon_rho"][:,:];
lat = ds_grid["lat_rho"][:,:];
h = nomissing(ds_grid["h"][:,:],NaN);
mask_rho = ds_grid["mask_rho"][:,:];

figure(figsize=(7,4))
hmask = copy(h)
hmask[mask_rho .== 0] .= NaN;
pcolormesh(lon,lat,hmask);
colorbar()
## or colorbar(orientation="horizontal")
gca().set_aspect(1/cosd(mean(lat)))

title("smoothed bathymetry [m]");
savefig("smoothed_bathymetry.png");

#md # ![](smoothed_bathymetry.png)

# ## Surface temperature

# The surface surface temperature (or salinity) of the model output or
# climatology file can be visualized as follows.
# The parameter `n` is the time instance to plot.
# Make sure that your current working directory
# contains the file to plot (use e.g. `;cd ~/ROMS-implementation-test/` to plot `roms_his.nc`)


## instance to plot
n = 1

ds = NCDataset("roms_his.nc")
temp = nomissing(ds["temp"][:,:,end,n],NaN);
temp[mask_rho .== 0] .= NaN;

if haskey(ds,"time")
    ## for the climatology file
    time = ds["time"][:]
else
    ## for ROMS output
    time = ds["ocean_time"][:]
end

figure(figsize=(7,4))
pcolormesh(lon,lat,temp)
gca().set_aspect(1/cosd(mean(lat)))
colorbar();
title("sea surface temperature [°C]")
savefig("SST.png");

#md # ![](SST.png)

# Exercise:
# * Plot salinity
# * Plot different time instance (`n`)
# * Where do we specify that the surface values are to be plotted? Plot different layers.


# ## Surface velocity and elevation

zeta = nomissing(ds["zeta"][:,:,n],NaN)
u = nomissing(ds["u"][:,:,end,n],NaN);
v = nomissing(ds["v"][:,:,end,n],NaN);

mask_u = ds_grid["mask_u"][:,:];
mask_v = ds_grid["mask_v"][:,:];

u[mask_u .== 0] .= NaN;
v[mask_v .== 0] .= NaN;
zeta[mask_rho .== 0] .= NaN;

## ROMS uses an Arakawa C grid
u_r = cat(u[1:1,:], (u[2:end,:] .+ u[1:end-1,:])/2, u[end:end,:], dims=1);
v_r = cat(v[:,1:1], (v[:,2:end] .+ v[:,1:end-1])/2, v[:,end:end], dims=2);

## all sizes should be the same
size(u_r), size(v_r), size(mask_rho)

figure(figsize=(7,4))
pcolormesh(lon,lat,zeta)
colorbar();
## plot only a single arrow for r x r grid cells
r = 3;
i = 1:r:size(lon,1);
j = 1:r:size(lon,2);
q = quiver(lon[i,j],lat[i,j],u_r[i,j],v_r[i,j])
quiverkey(q,0.9,0.85,1,"1 m/s",coordinates="axes")
title("surface currents [m/s] and elevation [m]");
gca().set_aspect(1/cosd(mean(lat)))
savefig("surface_zeta_uv.png");

#md # ![](surface_zeta_uv.png)

# Exercise:
# * The surface currents seems to follow lines of constant surface elevation. Explain why this is to be expected.

# ## Vertical section

# In this example we will plot a vertical section by slicing the
# model output at a given index.

# It is very important that the parameters (`opt`) defining the vertical layer match the parameters values choosen when ROMS was setup.

opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)

hmin = minimum(h)
hc = min(hmin,opt.Tcline)
z_r = ROMS.set_depth(opt.Vtransform, opt.Vstretching,
                   opt.theta_s, opt.theta_b, hc, opt.nlevels,
                   1, h);

temp = nomissing(ds["temp"][:,:,:,n],NaN);

mask3 = repeat(mask_rho,inner=(1,1,opt.nlevels))
lon3 = repeat(lon,inner=(1,1,opt.nlevels))
lat3 = repeat(lat,inner=(1,1,opt.nlevels))

temp[mask3 .== 0] .= NaN;

i = 20;

clf()
contourf(lat3[i,:,:],z_r[i,:,:],temp[i,:,:],40)
ylim(-300,0);
xlabel("latitude")
ylabel("depth [m]")
title("temperature at $(round(lon[i,1],sigdigits=4)) °E")
colorbar();

## inset plot
ax2 = gcf().add_axes([0.1,0.18,0.4,0.3])
ax2.pcolormesh(lon,lat,temp[:,:,end])
ax2.set_aspect(1/cosd(mean(lat)))
ax2.plot(lon[i,[1,end]],lat[i,[1,end]],"m")

savefig("temp_section1.png");

#md # ![temp_section1](temp_section1.png)

# Exercise:
# * Plot a section at different longitude and latitude

# ## Horizontal section

# A horizontal at the fixed depth of 200 m is extracted and plotted.

tempi = ROMS.model_interp3(lon,lat,z_r,temp,lon,lat,[-200])
mlon,mlat,mdata = GeoDatasets.landseamask(resolution='f', grid=1.25)

figure(figsize=(7,4))
pcolormesh(lon,lat,tempi[:,:,1])
colorbar();
ax = axis()
contourf(mlon,mlat,mdata',[0.5, 3],colors=["gray"])
axis(ax)
gca().set_aspect(1/cosd(mean(lat)))
title("temperature at 200 m [°C]")
savefig("temp_hsection_200.png");

#md # ![](temp_hsection_200.png)

# ## Arbitrary vertical section

# The vectors `section_lon` and `section_lat` define the coordinates where we want to extract
# the surface temperature.


section_lon = LinRange(8.18, 8.7,100);
section_lat = LinRange(43.95, 43.53,100);

using Interpolations

function section_interp(v)
    itp = interpolate((lon[:,1],lat[1,:]),v,Gridded(Linear()))
    return itp.(section_lon,section_lat)
end

section_temp = mapslices(section_interp,temp,dims=(1,2))
section_z = mapslices(section_interp,z_r,dims=(1,2))

section_x = repeat(section_lon,inner=(1,size(temp,3)))

clf()
contourf(section_x,section_z[:,1,:],section_temp[:,1,:],50)
ylim(-500,0)
colorbar()
xlabel("longitude")
ylabel("depth")
title("temperature section [°C]");

## inset plot
ax2 = gcf().add_axes([0.4,0.2,0.4,0.3])
ax2.pcolormesh(lon,lat,temp[:,:,end])
axis("on")
ax2.set_aspect(1/cosd(mean(lat)))
ax2.plot(section_lon,section_lat,"m")

savefig("temp_vsection.png");

#md # ![](temp_vsection.png)
