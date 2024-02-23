using ROMS
using Test
using Dates

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

    mapping = Dict(
        # var  dataset_id
        :sea_surface_height_above_geoid => ("zos","med-cmcc-ssh-rean-d"),
        :sea_water_potential_temperature => ("thetao", "med-cmcc-tem-rean-d"),
        :sea_water_salinity => ("so","med-cmcc-sal-rean-d"),
        :eastward_sea_water_velocity => ("uo", "med-cmcc-cur-rean-d"),
        :northward_sea_water_velocity => ("vo", "med-cmcc-cur-rean-d"),
    )


    dataset_cmems = ROMS.CMEMS_opendap(cmems_username,cmems_password,mapping,outdir)
    push!(datasets,dataset_cmems)
end


#url = "https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0"
#dataset_hycom = ROMS.HYCOM(url,outdir);
#push!(datasets,dataset_hycom)


for dataset in datasets
    v,(x,y,z,t) = ROMS.load(dataset,:sea_water_potential_temperature,
                        longitude = xr, latitude = yr, time = tr);

    @test all(xr[1] .<= x .<= xr[end])
    @test all(yr[1] .<= y .<= yr[end])
    @test all(z .<= 0)
    @test all(tr[1] .<= t .<= tr[end])
end
