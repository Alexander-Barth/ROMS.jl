"""
    ROMS.extract_ic(domain,clim_filename,icfile,t0::DateTime;
                    time_origin = DateTime(1858,11,17))


From the climatology `clim_filename` extract a single time instance at the time
`t0` (or the nearest) and save the result into `icfile`.
"""
function extract_ic(domain,clim_filename,icfile,t0;
                    time_origin = DateTime(1858,11,17))


    missing_value = -99999;

    if isfile(icfile)
        rm(icfile)
    end
    ic = def_ic(icfile,domain,missing_value; time_origin = time_origin);

    Dataset(clim_filename,"r") do nc
        ic["ocean_time"][1] = t0;

        # all variables for which IC must be provided
        vars = ["zeta","ubar","vbar","u","v","temp","salt"]

        # try to retrieve last model forecast

        time = read_time(nc);

        if length(time) == 1
            index = 1
        else
            index = argmin(abs.(time - t0))
        end

        @info "Request to initalize from $t0"
        @info "Try to initalize from $(time[index])"

        # copy all variables

        for i=1:length(vars)
            println("copy $(vars[i])")

            ncv = nc[vars[i]];

            if ndims(ncv) == 3
                v = nomissing(ncv[:,:,index],NaN)
            else
                v = nomissing(ncv[:,:,:,index],NaN)
            end

            v = DIVAnd.ufill(v,isfinite.(v))

            if ndims(ncv) == 3
                ic[vars[i]][:,:,1] = v
            else
                ic[vars[i]][:,:,:,1] = v
            end
        end

    end
    close(ic)

    dstart = Dates.value(t0 - time_origin) / (24*60*60*1000)
    @info "DSTART = $dstart"

    return nothing
end
