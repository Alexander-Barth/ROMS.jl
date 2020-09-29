
function extract_ic(domain,bigfile,icfile,t0)


    missing_value = -99999;

    if isfile(icfile)
        rm(icfile)
    end
    ic = def_ic(icfile,domain,missing_value);

    Dataset(bigfile,"r") do nc
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

    return nothing
end
