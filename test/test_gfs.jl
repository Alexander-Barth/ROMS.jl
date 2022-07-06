
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

datadir = joinpath(dirname(@__FILE__),"..","data")

if !isdir(datadir)
    # get ROMS-test-data
    testdatazip = download("https://dox.ulg.ac.be/index.php/s/hr2QIw8ND7a6dGZ/download")
    temporarydir = mktempdir()
    cd(temporarydir) do
        run(`unzip $testdatazip`)
    end
    datadir = joinpath(temporarydir,"ROMS-test-data")
end


fname_ref = joinpath(datadir,"gom_Tair_era.nc")

ds_ref = NCDataset(fname_ref)
xr = extrema(ds_ref["lon"][:])
yr = extrema(ds_ref["lat"][:])

#time_ref = ds_ref["rain_time"][:]
#time_ref = ds_ref[timename][:]


#tr = extrema(time_ref)
tr = (DateTime(2019,1,1,3),DateTime(2019,1,7,3))
#mrain = mean(ds_ref["rain"][:,:,:],dims=3)[:,:,1]



time = DateTime(2015,1,16)
tau = 0 # hours
@test occursin("2015",ROMS.gfs_url(time,tau))


times = tr[1]:Dates.Hour(3):tr[end]

cachedir = "/home/abarth/tmp/GFS"

#ROMS.download_gfs(xr,yr,tr,cachedir)

outdir = "/home/abarth/tmp/GFS-roms"
mkpath(cachedir)
mkpath(outdir)
filename_prefix = joinpath(outdir,"liguriansea_gfs_")
domain_name = "Ligurian Sea Region"

atmo_src = ( dir = cachedir, times = times)

Vnames = ["sustr","svstr","swflux","swrad","Uwind","Vwind",
          "sensible","cloud","rain","Pair","Tair","Qair"]


#    Vnames = ["sustr","svstr","sensible","Uwind","Vwind","Tair", "Qair",
#              "rain", "cloud","Pair","swrad"]

filenames = ROMS.prepare_gfs(atmo_src,Vnames,filename_prefix,domain_name)


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

function tsplot(fname_ref, Tname, Vname; label = nothing)
    ds_ref = NCDataset(fname_ref)
    lon_ref = ds_ref["lon"][:]
    lat_ref = ds_ref["lat"][:]
    i = findmin(abs.(lon_ref[:,1] .- lont))[2]
    j = findmin(abs.(lat_ref[1,:] .- latt))[2]
    @show i,j
    plot(ds_ref[Tname][:],ds_ref[Vname][i,j,:],label=label)
    close(ds_ref)
end

(iparam,(Vname,outfname)) = first(enumerate(filenames))


#for iparam = 1:length(Vnames)
for (iparam,(Vname,outfname)) in enumerate(filenames)
    figure(iparam)

    clf()

    Tname = ROMS.metadata[Vname].Tname

    output = replace(outfname,filename_prefix => "",".nc" => "")
    fname_ref = joinpath(datadir,"gom_$(output)_era.nc")

    tsplot(fname_ref, Tname, Vname; label = "ECMWF")
    tsplot(outfname, Tname, Vname; label = "GFS")

    units = ""
    if hasproperty(ROMS.metadata[Vname].ncattrib,:units)
        units = ROMS.metadata[Vname].ncattrib.units
    end

    title("$Vname [$(units)]")
    legend()
end


#subplot(2,1,1);
#plot(output_time,output[i,j,:])
#=
pcolormesh(lon,lat,Tair')



pcolor(mrain'); colorbar()
=#
