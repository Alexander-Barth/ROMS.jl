
# Untested code


# We assume that the OPENDAP server
# https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2

# produce the same output as:

# https://web.archive.org/web/20220517143017/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2.dds
# https://web.archive.org/web/20220517143054/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2.das


using NCDatasets

fname = "https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f000.grib2"

ds = NCDataset(fname);

lon = ds["lon"][:]
lat = ds["lat"][:]
time = ds["time"][:]

# index for 10 m winds
k_wind = 1

n = 1

z_level = 10


function gfs_depth_index(ds,varname,z_level)
    ncvar = ds[varname]
    varname_z = dimnames(ncvar)[3]
    z = ds[varname_z]
    @assert z.attrib["units"] == "m"
    return findfirst(z[:] .== z_level)
end

k_wind = gfs_depth_index(ds,"u-component_of_wind_height_above_ground",10)
k_Tair = gfs_depth_index(ds,"Temperature_height_above_ground",2)
k_rh = gfs_depth_index(ds,"Relative_humidity_height_above_ground",2)

uwind = ds["u-component_of_wind_height_above_ground"][:,:,k_wind,n]
vwind = ds["v-component_of_wind_height_above_ground"][:,:,k_wind,n]
Tair = ds["Temperature_height_above_ground"][:,:,k_Tair,n]
rh = ds["Relative_humidity_height_above_ground"][:,:,k_rh,n]



using PyPlot
pcolormesh(lon,lat,Tair')
