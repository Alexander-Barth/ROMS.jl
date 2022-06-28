# Compare to d_ecmwf2roms.m (svn revision 1102)
# This is a local test only as it requires matlab


# get the file era_interim_2016_short.nc
# apply patch d_ecmwf2roms.m.patch
# run matlab d_ecmwf2roms.m script to generate gom_*_era.nc files


using ROMS
using NCDatasets
using Test

datadir = get(ENV,"ROMS_SAMPLE_DATA",expanduser("~/src/roms-matlab/forcing"))

atmo_fname = joinpath(datadir,"era_interim_2016_short.nc")

filename_prefix = "liguriansea_"
domain_name = "Ligurian Sea Region"
Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
          "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

filenames = @time ROMS.prepare_ecmwf(atmo_fname,Vnames,filename_prefix,domain_name)

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

        ds_ref = NCDataset("gom_$(ncname)_era.nc")
        ds = NCDataset("$(filename_prefix)$(ncname).nc")

        Tname = ROMS.metadata[Vname].Tname
        @test ds_ref[Vname][:,:,:] ≈ ds[Vname][:,:,:]
        @test ds_ref[Tname][:] == ds[Tname][:]

        close(ds)
        close(ds_ref)
    end
end
