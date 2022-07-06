
# Untested code

# https://rda.ucar.edu/thredds/catalog/files/g/ds084.1/2015/20150115/catalog.html

# We assume that the OPENDAP server
# https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2

# produce the same output as:

# https://web.archive.org/web/20220517143017/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2.dds
# https://web.archive.org/web/20220517143054/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2.das


using NCDatasets
using Dates
using Printf
using Statistics
using Test
using ROMS
using DataStructures
using ROMS: latent_heat_of_vaporization, gfs_depth_index, gfs_url

fname_ref, timename = "/mnt/data1/abarth/work/ROMS-implementation-test/liguriansea2019_rain.nc", "rain_time"
fname_ref, timename = "/home/abarth/ROMS-implementation-test/liguriansea2019_wind.nc", "wind_time"
fname_ref, timename = "/home/abarth/ROMS-implementation-test/liguriansea2019_sms.nc", "sms_time"

fname_ref = "/home/abarth/ROMS-implementation-test/liguriansea2019_sensible.nc"

ds_ref = NCDataset(fname_ref)
xr = extrema(ds_ref["lon"][:])
yr = extrema(ds_ref["lat"][:])

#time_ref = ds_ref["rain_time"][:]
#time_ref = ds_ref[timename][:]


#tr = extrema(time_ref)
tr = (DateTime(2019,1,1,3),DateTime(2019,1,7,3))
#mrain = mean(ds_ref["rain"][:,:,:],dims=3)[:,:,1]



"""
forecast_cycle hours
"""
function gfs_url_old(time; forecast_cycle = 6,
                 kwargs...)

    forecast_cycle_ms = forecast_cycle*60*60*1000 # ms

    c = Dates.datetime2epochms(time) ÷ forecast_cycle_ms
    timef = Dates.epochms2datetime(c*forecast_cycle_ms)
    # ms to hours
    tau = Dates.value(time-timef) ÷ (60*60*1000)
    return gfs_url(timef,tau; kwargs...)
end


time = DateTime(2015,1,15)
tau = 0 # hours
tau = 3

fname = gfs_url(time,tau)

time = DateTime(2015,1,16)
tau = 0 # hours
fname = gfs_url(time,tau)

time = DateTime(2015,1,15,9)
fname = gfs_url(time)


times = DateTime(2015,1,15):Dates.Hour(3):DateTime(2015,1,18)

fnames = gfs_url.(times)

#ds = NCDataset(fnames,aggdim="time",deferopen=false);


time = DateTime(2015,1,15)
tau = 3
fname = gfs_url(time,tau)
ds = NCDataset(fname);

lon = ds["lon"][:]
lat = ds["lat"][:]
time = ds["time"][:]

# index for 10 m winds
k_wind = 1

n = 1

z_level = 10




#=
uwind = ds["u-component_of_wind_height_above_ground"][:,:,k_wind,n]
vwind = ds["v-component_of_wind_height_above_ground"][:,:,k_wind,n]
Tair = ds["Temperature_height_above_ground"][:,:,k_Tair,n]
rh = ds["Relative_humidity_height_above_ground"][:,:,k_rh,n]

ds
=#



time0 = tr[1] #+ Dates.Minute(3*60 ÷ 2)
time1 = tr[end] #+ Dates.Minute(3*60 ÷ 2)

times = time0:Dates.Hour(3):time1

irange = findall(xr[1] .<= lon .<= xr[end])
jrange = findall(yr[1] .<= lat .<= yr[end])


irange = irange[1]:irange[end]
jrange = jrange[1]:jrange[end]

lon = lon[irange]
lat = lat[jrange]

sz = (length(irange),length(jrange),length(times))
rain = zeros(sz)
uwind = zeros(sz)
vwind = zeros(sz)
sustr = zeros(sz)
output = zeros(sz)
output_time = Vector{DateTime}(undef,length(times))


n = 1
cachedir = "/home/abarth/tmp/GFS"
mkpath(cachedir)
datadir = "/home/abarth/tmp/GFS-roms"
mkpath(datadir)
filename_prefix = joinpath(datadir,"liguriansea_gfs_")

domain_name = "Ligurian Sea Region"
time_origin = DateTime(1858,11,17)

atmo_src = ( dir = cachedir, times = times)



ROMS.prepare_gfs(atmo_src,Vnames,filename_prefix,domain_name)


using PyPlot


#=
n = 1
clf()


#var,var_ref = rain,ds_ref["rain"][:,:,n]
#var,var_ref = uwind[:,:,n],ds_ref["Uwind"][:,:,n]
#var,var_ref = vwind[:,:,n],ds_ref["Vwind"][:,:,n]
#var,var_ref = sustr[:,:,n],ds_ref["sustr"][:,:,n]
#var,var_ref = output[:,:,n],ds_ref["sustr"][:,:,n]

var = dsout[Vname][:,:,n]
var_ref = ds_ref[Vname][:,:,n]


subplot(1,2,1); p1 = pcolor(lon,lat,var'), colorbar()
subplot(1,2,2); p2 = pcolor(lon_ref,lat_ref,nomissing(var_ref,NaN)), colorbar()

cl = extrema([p1[1].get_clim()...,p2[1].get_clim()...])
p1[1].set_clim(cl)
p2[1].set_clim(cl)

=#

lont = 12
latt = 44

lont = 9
latt = 43.5

#=
for iparam = 1:length(Vnames)
figure(iparam)

clf()

Vname = Vnames[iparam]
ii = findfirst(i -> F[i].Vname == Vname,1:length(F))
outfname = filename_prefix * "$(F[ii].output).nc"
fname_ref = "/home/abarth/ROMS-implementation-test/liguriansea2019_$(F[ii].output).nc"
ds_ref = NCDataset(fname_ref)
lon_ref = ds_ref["lon"][:]
lat_ref = ds_ref["lat"][:]
i = findmin(abs.(lon_ref[:,1] .- lont))[2]
j = findmin(abs.(lat_ref[1,:] .- latt))[2]

dsout = NCDataset(outfname)
lon = dsout["lon"][:]
lat = dsout["lat"][:]
i = findmin(abs.(lon .- lont))[2]
j = findmin(abs.(lat .- latt))[2]


Tname = ROMS.metadata[Vname].Tname
plot(ds_ref[Tname][:],ds_ref[Vname][i,j,:],label="ECMWF")


plot(dsout[Tname][:],dsout[Vname][i,j,:],label="GFS")

units = ""
if hasproperty(ROMS.metadata[Vname].ncattrib,:units)
units = ROMS.metadata[Vname].ncattrib.units
end

title("$Vname [$(units)]")
legend()
end
=#

#subplot(2,1,1);
#plot(output_time,output[i,j,:])
#=
pcolormesh(lon,lat,Tair')



pcolor(mrain'); colorbar()
=#
