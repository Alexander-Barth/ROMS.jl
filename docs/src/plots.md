```@meta
DocTestSetup = quote
using ROMS
cd(expanduser("~/ROMS-implementation-test")) do
if !isfile("liguriansea2019_Qair.nc")
   include(joinpath(dirname(pathof(ROMS)),"..","test","example_config.jl"))
end
end
end
```



```@example example_config
using PyPlot, ROMS

using ROMS, PyPlot, NCDatasets, GeoDatasets
using Statistics

datadir = expanduser("~/ROMS-implementation-test")


ds_grid = NCDataset(joinpath(datadir,"LS2v.nc"));
lon = ds_grid["lon_rho"][:,:];
lat = ds_grid["lat_rho"][:,:];
h = ds_grid["h"][:,:];
mask_rho = ds_grid["mask_rho"][:,:];


clf();
hmask = copy(h)
hmask[mask_rho .== 0] .= NaN;
pcolormesh(lon,lat,hmask);
colorbar(orientation="horizontal")
gca().set_aspect(1/cosd(mean(lat)))

title("smoothed bathymetry [m]");
savefig("smoothed_bathymetry.png"); nothing # hide
```

![](smoothed_bathymetry.png)




```@example example_config
# instance to plot
n = 3

#ds = NCDataset(joinpath(datadir,"clim2019.nc"))
ds = NCDataset(joinpath(datadir,"Simulation1","roms_his.nc"))

temp = nomissing(ds["temp"][:,:,end,n],NaN);
temp[mask_rho .== 0] .= NaN;

if haskey(ds,"time")
    # for clim files
    time = ds["time"][:]
else
    # for others files
    time = ds["ocean_time"][:]
end



clf();
pcolormesh(lon,lat,temp)
gca().set_aspect(1/cosd(mean(lat)))
colorbar(orientation="horizontal");
title("sea surface temperature [°C]")
savefig("SST.png"); nothing # hide
```

![](SST.png)


```@example example_config
zeta = nomissing(ds["zeta"][:,:,n],NaN)
u = nomissing(ds["u"][:,:,end,n],NaN);
v = nomissing(ds["v"][:,:,end,n],NaN);

mask_u = ds_grid["mask_u"][:,:];
mask_v = ds_grid["mask_v"][:,:];


u[mask_u .== 0] .= NaN;
v[mask_v .== 0] .= NaN;
zeta[mask_rho .== 0] .= NaN;

u_r = cat(u[1:1,:], (u[2:end,:] .+ u[1:end-1,:])/2, u[end:end,:], dims=1);
v_r = cat(v[:,1:1], (v[:,2:end] .+ v[:,1:end-1])/2, v[:,end:end], dims=2);
size(u_r), size(v_r), size(mask_rho)


clf();
pcolormesh(lon,lat,zeta)
r = 3;
i = 1:r:size(lon,1);
j = 1:r:size(lon,2);
q = quiver(lon[i,j],lat[i,j],u_r[i,j],v_r[i,j])
quiverkey(q,0.9,0.85,1,"1 m/s",coordinates="axes")
title("surface currents [m/s] and elevation [m]");
colorbar(orientation="horizontal");
gca().set_aspect(1/cosd(mean(lat)))
savefig("surface_zeta_uv.png"); nothing # hide
```

![](surface_zeta_uv.png)


```@example example_config
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
colorbar(orientation="horizontal");
savefig("temp_section1.png"); nothing # hide
```

![](temp_section1.png)



```@example example_config
tempi = ROMS.model_interp3(lon,lat,z_r,temp,lon,lat,[-200])
mlon,mlat,mdata = GeoDatasets.landseamask(resolution='f', grid=1.25)

clf();
pcolormesh(lon,lat,tempi[:,:,1])
colorbar(orientation="horizontal");
ax = axis()
contourf(mlon,mlat,mdata',[0.5, 3],colors=["gray"])
axis(ax)
gca().set_aspect(1/cosd(mean(lat)))
title("temperature at 200 m [°C]")
savefig("temp_hsection_200.png"); nothing # hide
```

![](temp_hsection_200.png)



```@example example_config
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

ax2 = gcf().add_axes([0.5,0.2,0.2,0.15])
ax2.pcolormesh(lon,lat,temp[:,:,end])
axis("on")
ax2.set_aspect(1/cosd(mean(lat)))
ax2.plot(section_lon,section_lat,"m")

savefig("temp_vsection.png");
```

![](temp_vsection.png)
