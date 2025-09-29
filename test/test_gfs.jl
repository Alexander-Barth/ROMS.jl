
# We assume that the OPENDAP server

# https://thredds.rda.ucar.edu/thredds/catalog/files/g/ds084.1/catalog.html
# https://thredds.rda.ucar.edu/thredds/catalog/files/g/ds084.1/2015/20150115/catalog.html
# https://thredds.rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f003.grib2.html

# https://thredds.rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f003.grib2.das
# https://thredds.rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f003.grib2.dds

# produce the same output as:

# https://web.archive.org/web/20220707075743/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f003.grib2.dds
# https://web.archive.org/web/20220707075743/https://rda.ucar.edu/thredds/dodsC/files/g/ds084.1/2015/20150115/gfs.0p25.2015011500.f003.grib2.dds

using NCDatasets
using Dates
#using Printf
#using Statistics
using Test
using ROMS
#using DataStructures
using Downloads: download


time = DateTime(2015,1,16)
tau = 0 # hours
@test occursin("2015",ROMS.gfs_url(time,tau))


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

cachedir = expanduser("~/tmp/GFS")

# pre-fill cache (because the server is unreliable)
# source
# https://thredds.rda.ucar.edu/thredds/catalog/files/g/ds084.1/2019/20190101/catalog.html
if !isdir(cachedir)
    gfs_data_zip = download("https://dox.ulg.ac.be/index.php/s/O5MH4WLKJqV8iXm/download")
    mkpath(cachedir)
    cd(cachedir) do
        run(`unzip -j $gfs_data_zip`)
    end
end


fname_ref = joinpath(datadir,"gom_Tair_era.nc")

ds_ref = NCDataset(fname_ref)
xr = extrema(ds_ref["lon"][:])
yr = extrema(ds_ref["lat"][:])

#tr = extrema(time_ref)
tr = (DateTime(2019,1,1),DateTime(2019,1,3))

#cachedir = tempname()

atmo_src = ROMS.download_gfs(xr,yr,tr,cachedir)

# outdir = expanduser("~/tmp/GFS-roms")
outdir = tempname()
mkpath(outdir)
filename_prefix = joinpath(outdir,"liguriansea_gfs_")
domain_name = "Ligurian Sea Region"

Vnames = ["sustr","svstr","swflux","swrad","Uwind","Vwind",
          "sensible","cloud","rain","Pair","Tair","Qair"]


filenames = ROMS.prepare_gfs(atmo_src,Vnames,filename_prefix,domain_name)


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


#=
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

using PyPlot

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
        units = string(
           "[",ROMS.metadata[Vname].ncattrib.units,"]")
    end

    title("$Vname $(units)")
    legend()
end

=#
