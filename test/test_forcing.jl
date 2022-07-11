using ROMS
using NCDatasets
using Test
using Dates


# reference values from https://en.wikipedia.org/w/index.php?title=Vapour_pressure_of_water&oldid=987479989
@test ROMS.vapor_pressure(20) ≈ 23.388 rtol=0.01
@test ROMS.vapor_pressure_Buck(20) ≈ 23.388 rtol=0.01


# Compare to d_ecmwf2roms.m (svn revision 1102)

# generate reference data:
# * apply patch d_ecmwf2roms.m.patch
# * run matlab d_ecmwf2roms.m script to generate gom_*_era.nc files


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

@show datadir
atmo_fname = joinpath(datadir,"ecmwf_sample_data.nc")
filename_prefix = joinpath(datadir,"liguriansea_")
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
    "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

filenames = @time ROMS.prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name)

# compare

basedir_ref = datadir

@testset "Compare to d_ecmwf2roms.m" begin
    for Vname = Vnames
        ncname = Vname
        if Vname in ("sustr","svstr")
            ncname = "sms"
        end
        if Vname in ("Uwind","Vwind")
            ncname = "wind"
        end
        if Vname == "lwrad_down"
            ncname = "lwrad"
        end

        ds_ref = NCDataset(joinpath(basedir_ref,"gom_$(ncname)_era.nc"))
        ds = NCDataset("$(filename_prefix)$(ncname).nc")

        Tname = ROMS.metadata[Vname].Tname

        data_ref = ds_ref[Vname][:,:,:]
        data = ds[Vname][:,:,:]

        diff = data - data_ref
        @test maximum(abs.(diff)) < 1e-6

        @test data_ref ≈ data
        @test ds_ref[Tname][:] == ds[Tname][:]

        close(ds)
        close(ds_ref)
    end
end
