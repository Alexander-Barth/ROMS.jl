function extract_bc(domain,clim_filename,bc_filename; missing_value = 9999)
    clim = NCDataset(clim_filename,"r")
    mask = domain.mask

    ds = roms_def_bc(bc_filename,domain,missing_value)

    for i = 1:length(clim["time"])
        ds["time"][i] = clim["time"][i]

        if any(mask[2:end-1,1])
            ds["zeta_south"][:,i] = clim["zeta"][:,1,i]
            ds["ubar_south"][:,i] = clim["ubar"][:,1,i]
            ds["vbar_south"][:,i] = clim["vbar"][:,1,i]
            ds["temp_south"][:,:,i] = clim["temp"][:,1,:,i]
            ds["salt_south"][:,:,i] = clim["salt"][:,1,:,i]
            ds["u_south"][:,:,i] = clim["u"][:,1,:,i]
            ds["v_south"][:,:,i] = clim["v"][:,1,:,i]
        end

        if any(mask[2:end-1,end])
            ds["zeta_north"][:,i] = clim["zeta"][:,end,i]
            ds["ubar_north"][:,i] = clim["ubar"][:,end,i]
            ds["vbar_north"][:,i] = clim["vbar"][:,end,i]
            ds["temp_north"][:,:,i] = clim["temp"][:,end,:,i]
            ds["salt_north"][:,:,i] = clim["salt"][:,end,:,i]
            ds["u_north"][:,:,i] = clim["u"][:,end,:,i]
            ds["v_north"][:,:,i] = clim["v"][:,end,:,i]
        end

        if any(mask[end,2:end-1])
            ds["zeta_east"][:,i] = clim["zeta"][end,:,i]
            ds["ubar_east"][:,i] = clim["ubar"][end,:,i]
            ds["vbar_east"][:,i] = clim["vbar"][end,:,i]
            ds["temp_east"][:,:,i] = clim["temp"][end,:,:,i]
            ds["salt_east"][:,:,i] = clim["salt"][end,:,:,i]
            ds["u_east"][:,:,i] = clim["u"][end,:,:,i]
            ds["v_east"][:,:,i] = clim["v"][end,:,:,i]
        end

        if any(mask[1,2:end-1])
            ds["zeta_west"][:,i] = clim["zeta"][1,:,i]
            ds["ubar_west"][:,i] = clim["ubar"][1,:,i]
            ds["vbar_west"][:,i] = clim["vbar"][1,:,i]
            ds["temp_west"][:,:,i] = clim["temp"][1,:,:,i]
            ds["salt_west"][:,:,i] = clim["salt"][1,:,:,i]
            ds["u_west"][:,:,i] = clim["u"][1,:,:,i]
            ds["v_west"][:,:,i] = clim["v"][1,:,:,i]
        end
    end

    close(ds)
    close(clim)

    return nothing
end
