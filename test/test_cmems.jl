# https://help.marine.copernicus.eu/en/articles/8656000-differences-between-netcdf-and-arco-formats

using DataStructures
using Dates
using ROMS
using ROMS: CMEMS_zarr
using Test
using URIs

# range of longitude
xr = [7.6, 12.2];

# range of latitude
yr = [42, 44.5];

t0 = DateTime(2019,1,1);

tr = [t0, t0+Dates.Day(1)]

outdir = tempname()

datasets = []

if haskey(ENV,"CMEMS_USERNAME")
    cmems_username = ENV["CMEMS_USERNAME"]
    cmems_password = ENV["CMEMS_PASSWORD"]

end

# CMEMS Zarr ARCO

product_id = "MEDSEA_MULTIYEAR_PHY_006_004"

mapping = Dict(
    # var  dataset_id
    :sea_surface_height_above_geoid => ("zos","cmems_mod_med_phy-ssh_my_4.2km_P1D-m"),
    :sea_water_potential_temperature => ("thetao", "cmems_mod_med_phy-temp_my_4.2km_P1D-m"),
    :sea_water_salinity => ("so","cmems_mod_med_phy-sal_my_4.2km_P1D-m"),
    :eastward_sea_water_velocity => ("uo", "cmems_mod_med_phy-cur_my_4.2km_P1D-m"),
    :northward_sea_water_velocity => ("vo", "cmems_mod_med_phy-cur_my_4.2km_P1D-m"),
)

dataset_cmems_zarr = CMEMS_zarr(product_id,mapping,outdir,
                                time_shift = 12*60*60)
push!(datasets,dataset_cmems_zarr)

#url = "https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0"
#dataset_hycom = ROMS.HYCOM(url,outdir);
#push!(datasets,dataset_hycom)

for dataset in datasets
    local v, x, y, z, t
    v,(x,y,z,t) = ROMS.load(dataset,:sea_water_potential_temperature,
                        longitude = xr, latitude = yr, time = tr);

    @test all(xr[1] .<= x .<= xr[end])
    @test all(yr[1] .<= y .<= yr[end])
    @test all(z .<= 0)
    @test all(tr[1] .<= t .<= tr[end])
end

vz,(xz,yz,zz,tz) = ROMS.load(dataset_cmems_zarr,:sea_water_potential_temperature,
                             longitude = xr, latitude = yr, time = tr);
