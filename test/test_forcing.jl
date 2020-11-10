using ROMS
using NCDatasets
using Test

datadir = joinpath(dirname(@__FILE__),"..","data")

if !isdir(datadir)
    # ROMS-test-data
    testdatazip = download("https://dox.ulg.ac.be/index.php/s/hr2QIw8ND7a6dGZ/download")
    run(`unzip -o $testdatazip`)
    datadir = joinpath(pwd(),"ROMS-test-data")
end

@show datadir
atmo_fname = joinpath(datadir,"ecmwf_sample_data.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind","
    lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

filenames = @time ROMS.prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name)

# compare

basedir_ref = datadir

for i = 1:length(filenames)
    Vname,fname = filenames[i]

    Tname = ROMS.metadata[Vname].Tname
    output = replace(replace(fname,filename_prefix => ""),".nc" => "")

    fname_ref = joinpath(basedir_ref,"liguriansea_$(output)_era_ref.nc")

    dsout = Dataset(fname)
    ds_ref = Dataset(fname_ref)

    #@show ds_ref[Vname][1,1,1]
    #@show dsout[Vname][1,1,1]

    tindex = 1:length(ds_ref[Tname])
    #tindex = 1:2
    #@show ds_ref[Tname][1:2]
    #@show dsout[Tname][1:2]

    diff = ds_ref[Tname][tindex] - dsout[Tname][tindex]
    @test all(Dates.value.(diff) .== 0)

    diff = ds_ref[Vname][:,:,tindex] - dsout[Vname][:,:,tindex]

    #@show std(ds_ref[Vname][:,:,end])
    #@show std(dsout[Vname][:,:,end])
    @test maximum(abs.(diff)) < 1e-4

    close(dsout)
    close(ds_ref)
end
