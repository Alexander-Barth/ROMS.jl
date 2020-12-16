"""
    ROMS.interp_clim(domain,clim_filename,dataset,timerange;
                     padding = 0.5,
                     missing_value = -9999.)

Interpolate `dataset` on the the model grid `domain` and creating the
climatology file `clim_filename` for all dates between `timerange[1]` and
`timerange[2]`.
"""
function interp_clim(domain,clim_filename,dataset,timerange;
                     padding = 0.5,
                     missing_value = -9999.)

    x = domain.lon;
    y = domain.lat;
    z_r = domain.z_r;
    angle = domain.angle;
    h = domain.h;
    h_u = domain.h_u
    h_v = domain.h_v

    function wider(x)
        xmin,xmax = extrema(x)
        return xmin-padding,xmax+padding
    end

    query = (
        time = timerange,
        longitude = wider(x),
        latitude = wider(y),
    )

    zeta,(zx,zy,zt) = load(dataset[:sea_surface_height_above_geoid]; query...)
    temp,(tx,ty,tz,tt) = load(dataset[:sea_water_potential_temperature]; query...)
    salt,(sx,sy,sz,st) = load(dataset[:sea_water_salinity]; query...)
    u,(ux,uy,uz,ut) = load(dataset[:eastward_sea_water_velocity]; query...)
    v,(vx,vy,vz,vt) = load(dataset[:northward_sea_water_velocity]; query...)

    angle = repeat(domain.angle,inner = (1, 1, size(z_r,3)))

    time = st;
    N = length(st);
    first = true;

    ds = ROMS.def_clim(clim_filename,missing_value,size(x,1),size(x,2),size(z_r,3));

    climtime = ds["time"]
    czeta = ds["zeta"]
    cubar = ds["ubar"]
    cvbar = ds["vbar"]
    cu = ds["u"]
    cv = ds["v"]
    ctemp = ds["temp"]
    csalt = ds["salt"]


    #netcdf_lock = ReentrantLock()

    #Threads.@threads for ni = 1:N
    for ni = 1:N
        zz = zeros(size(zeta,1),size(zeta,2));

        # lock(netcdf_lock) do
        # global t
        # global zv
        # global sv
        # global tv
        # global uv
        # global vv

            t = time[ni];
            @info "load $t"
            zv = nomissing(zeta[:,:,ni],NaN)
            sv = nomissing(salt[:,:,:,ni],NaN)
            tv = nomissing(temp[:,:,:,ni],NaN)
            uv = nomissing(u[:,:,:,ni],NaN)
            vv = nomissing(v[:,:,:,ni],NaN)
            @debug "loaded $t"
#        end

        @info "interpolate $t"
        @debug "zeta $t"
        zetai = ROMS.model_interp3(zx,zy,zz,zv,x,y,z_r[:,:,end],missing = :ufill);

        @debug "salt $t"
        salti = ROMS.model_interp3(sx,sy,sz,sv,x,y,z_r,missing = :ufill);

        @debug "temp $t"
        tempi = ROMS.model_interp3(tx,ty,tz,tv,x,y,z_r,missing = :ufill);

        @debug "vel $t"
        ui_rc = ROMS.model_interp3(ux,uy,uz,uv,x,y,z_r,missing = :zero);
        vi_rc = ROMS.model_interp3(vx,vy,vz,vv,x,y,z_r,missing = :zero);

        @debug "rotate $t"

        # rotate velocity
        ui_r =  cos.(angle) .* ui_rc + sin.(angle) .* vi_rc;
        vi_r = -sin.(angle) .* ui_rc + cos.(angle) .* vi_rc;

        @debug "stagger $t"
        # stagger on C grid
        ui =  (ui_r[1:end-1,:,:] + ui_r[2:end,:,:])/2;
        vi =  (vi_r[:,1:end-1,:] + vi_r[:,2:end,:])/2;

        @debug "ubar/vbar $t"

        # depth-averaged current
        U, = ROMS.vinteg(uv,uz);
        V, = ROMS.vinteg(vv,vz);

        @debug "stagger $t"
        Ui_rc = ROMS.model_interp3(ux,uy,uz,U,x,y,z_r[:,:,end],missing = :zero);
        Vi_rc = ROMS.model_interp3(vx,vy,vz,V,x,y,z_r[:,:,end],missing = :zero);

        # rotate velocity
        Ui_r =  cos.(domain.angle) .* Ui_rc + sin.(domain.angle) .* Vi_rc;
        Vi_r = -sin.(domain.angle) .* Ui_rc + cos.(domain.angle) .* Vi_rc;

        # stagger on C grid
        Ui = (Ui_r[1:end-1,:,:] + Ui_r[2:end,:,:])/2;
        Vi = (Vi_r[:,1:end-1,:] + Vi_r[:,2:end,:])/2;

        ubar = Ui ./ h_u;
        vbar = Vi ./ h_v;

        ubar2,vbar2 = ROMS.vavg(domain,ui,vi);

        # make ubar and ui consistent
        ui = ui .+ (ubar-ubar2)
        vi = vi .+ (vbar-vbar2)

        @debug begin
            ubar2c,vbar2c = ROMS.vavg(domain,ui,vi);
            @show maximum(abs.(ubar - ubar2c))
            @show maximum(abs.(vbar - vbar2c))
        end

        # write to NetCDF files
        # the lock will become unnecessary once netcdf is thread safe
        # https://github.com/Unidata/netcdf-c/issues/1373
#        lock(netcdf_lock) do
            @debug "saving $t"
            climtime[ni] = t
            czeta[:,:,ni] = zetai
            csalt[:,:,:,ni] = salti
            ctemp[:,:,:,ni] = tempi

            cu[:,:,:,ni] = ui
            cv[:,:,:,ni] = vi

            cubar[:,:,ni] = ubar
            cvbar[:,:,ni] = vbar
            @debug "saved $t"
 #       end
    end
    close(ds)
end
