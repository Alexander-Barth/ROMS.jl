using ROMS
using Test
using NCDatasets
using Dates

#=
# todo: test new URL once HYCOM dataset is back again
# since to 2018-12-04 to Present *3-hourly* (state 2022-07-21)
#url = "https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0"


# URL from https://www.hycom.org/data/glbu0pt08/expt-91pt0
#url = "http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_91.0"


cachedir = expanduser("~/tmp/HYCOM")
mkpath(cachedir)


ds = ROMS.HYCOM(url,cachedir);

# range of longitude
xr = [7.6, 12.2];

# range of latitude
yr = [42, 44.5];

t0 = DateTime(2019,1,2);
t1 = DateTime(2019,1,4);
t0 = DateTime(2013,9,1);
t1 = DateTime(2013,9,4);
tr = [t0-Dates.Day(1), t1+Dates.Day(1)]

ROMS.download(ds,:sea_surface_height_above_geoid,
              longitude = xr, latitude = yr, time = tr)


ncvar,(x,y,t) = ROMS.load(
    ds,:sea_surface_height_above_geoid,
    longitude = xr, latitude = yr, time = tr)


T,(x,y,z,t) = ROMS.load(
    ds,:sea_water_potential_temperature,
    longitude = xr, latitude = yr, time = tr)

=#
