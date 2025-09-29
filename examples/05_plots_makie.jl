# # Plotting ROMS results and input files

#md # *The code here is also available as a notebook [04\_plots.ipynb](05_plots_makie.ipynb).*
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
using CairoMakie # GeoMakie, GLMakie
using CairoMakie: Point2f

ds_grid = NCDataset("roms_grd_liguriansea.nc");
lon = ds_grid["lon_rho"][:,:];
lat = ds_grid["lat_rho"][:,:];
h = ds_grid["h"][:,:]
mask_rho = ds_grid["mask_rho"][:,:];

hmask = copy(h)
hmask[mask_rho .== 0] .= missing;

fig = Figure();
ga = Axis(fig[1, 1]; title = "smoothed bathymetry [m]",
         aspect = AxisAspect(1/cosd(mean(lat))));
surf = surface!(ga,lon,lat,hmask, shading = NoShading, interpolate = false);
Colorbar(fig[1,2],surf)
xlims!(ga,extrema(lon))
ylims!(ga,extrema(lat))
save("smoothed_bathymetry_makie.png",fig); nothing # hide

#md # ![](smoothed_bathymetry_makie.png)

# ## Surface temperature

# The surface surface temperature (or salinity) of the model output or
# climatology file can be visualized as follows.
# The parameter `n` is the time instance to plot.
# Make sure that your current working directory
# contains the file to plot (use e.g. `;cd ~/ROMS-implementation-test/` to plot `roms_his.nc`)


## instance to plot
n = 1

ds = NCDataset("roms_his.nc")
temp = ds["temp"][:,:,end,n]
temp[mask_rho .== 0] .= missing;

if haskey(ds,"time")
    ## for the climatology file
    time = ds["time"][:]
else
    ## for ROMS output
    time = ds["ocean_time"][:]
end

fig = Figure()
ga = Axis(fig[1, 1]; title = "sea surface temperature [degree C]")
surf = surface!(ga,lon,lat,temp, shading = NoShading, interpolate = false);
Colorbar(fig[1,2],surf);
xlims!(ga,extrema(lon))
ylims!(ga,extrema(lat))
save("SST_makie.png",fig); nothing # hide

#md # ![](SST_makie.png)

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

fig = Figure();
ga = Axis(fig[1, 1]; title = "surface currents [m/s] and elevation [m]",
         aspect = AxisAspect(1/cosd(mean(lat))));
surf = surface!(ga,lon,lat,zeta, shading = NoShading, interpolate = false);
Colorbar(fig[1,2],surf);
## plot only a single arrow for r x r grid cells
r = 3;
i = 1:r:size(lon,1);
j = 1:r:size(lon,2);
s = 0.6;
arrows!(ga,lon[i,j][:],lat[i,j][:],s*u_r[i,j][:],s*v_r[i,j][:]);
i=j=5;
arrows!(ga,[11],[44],[s*1],[0]);
text!(ga,[11],[44],text="1 m/s")
xlims!(ga,extrema(lon))
ylims!(ga,extrema(lat))
save("surface_zeta_uv_makie.png",fig); nothing # hide

#md # ![](surface_zeta_uv_makie.png)

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

fig = Figure();
ga = Axis(fig[1, 1]; title = "temperature at $(round(lon[i,1],sigdigits=4)) °E",
          xlabel = "latitude",
          ylabel = "depth [m]",
          backgroundcolor=:white,
          );
surf = surface!(ga,lat3[i,:,:],z_r[i,:,:],temp[i,:,:],shading = NoShading, interpolate = false);
xlims!(ga,extrema(lat3[i,:,:]))
ylims!(ga,-300,0);
Colorbar(fig[1,2],surf);
ax2 = Axis(
    fig[1, 1],
    width = Relative(0.4),
    height = Relative(0.3),
    halign = 0.13,
    valign = 0.18,
    aspect = AxisAspect(1/cosd(mean(lat))),
    backgroundcolor=:white);
## inset plot
poly!(ax2,Point2f[(lon[1,1], lat[1,1]), (lon[1,1], lat[1,end]), (lon[end,1], lat[1,end]), (lon[end,1], lat[1,1])], color = [:white, :white, :white, :white])
surf = surface!(ax2,lon[:,1],lat[1,:],temp[:,:,end], shading = NoShading, interpolate = false);
#ax2.pcolormesh(lon,lat,temp[:,:,end])
#ax2.set_aspect(1/cosd(mean(lat)))
lines!(ax2,lon[i,[1,end]],lat[i,[1,end]],color="magenta")
xlims!(ax2,extrema(lon))
ylims!(ax2,extrema(lat))

save("temp_section1_makie.png",fig);

#md # ![temp_section1](temp_section1_makie.png)

# Exercise:
# * Plot a section at different longitude and latitude

# ## Horizontal section

# A horizontal at the fixed depth of 200 m is extracted and plotted.

tempi = ROMS.model_interp3(lon,lat,z_r,temp,lon,lat,[-200])
mlon,mlat,mdata = GeoDatasets.landseamask(resolution='f', grid=1.25)

ii = findall(minimum(lon) .<=  mlon .<= maximum(lon))
jj = findall(minimum(lat) .<=  mlat .<= maximum(lat))

mlon = mlon[ii]
mlat = mlat[jj]
mdata = mdata[ii,jj]

fig = Figure();
ga = Axis(fig[1, 1]; title = "temperature at 200 m [°C]",
          xlabel = "longitude",
          ylabel = "latitude",
          );
surf = surface!(ga,lon,lat,tempi[:,:,1],shading = NoShading, interpolate = false);
Colorbar(fig[1,2],surf);
contourf!(ga,mlon,mlat,mdata,levels=[0.5, 3],colormap=[:grey])
xlims!(ga,extrema(lon))
ylims!(ga,extrema(lat))
fig

save("temp_hsection_200_makie.png",fig);

#md # ![](temp_hsection_200_makie.png)

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


fig = Figure();
ga = Axis(fig[1, 1]; title = "temperature section [°C]",
          xlabel = "longitude",
          ylabel = "depth",
          );
surf = surface!(ga,section_x,section_z[:,1,:],section_temp[:,1,:],shading = NoShading, interpolate = false)
ylims!(ga,-500,0)
Colorbar(fig[1,2],surf);
## inset plot
ax2 = Axis(
    fig[1, 1],
    width = Relative(0.4),
    height = Relative(0.3),
    halign = 0.6,
    valign = 0.18,
    aspect = AxisAspect(1/cosd(mean(lat))),
    backgroundcolor=:white);
poly!(ax2,Point2f[(lon[1,1], lat[1,1]), (lon[1,1], lat[1,end]), (lon[end,1], lat[1,end]), (lon[end,1], lat[1,1])], color = [:white, :white, :white, :white])
surf = surface!(ax2,lon[:,1],lat[1,:],temp[:,:,end], shading = NoShading, interpolate = false);
xlims!(ax2,extrema(lon))
ylims!(ax2,extrema(lat))
fig

save("temp_vsection_makie.png",fig);

#md # ![](temp_vsection_makie.png)
