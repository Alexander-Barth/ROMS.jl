# interpolate climatology
# option:
# x,y,z_r: coordinates on rho points
# angle: local rotation of grid
# h: depth

function roms_interp_clim4(clim_filename,domain,dataset,tr; padding = 0.5)

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
        time = tr,
        longitude = wider(x),
        latitude = wider(y),
    )

    zeta,(zx,zy,zt) = load(dataset[:sea_surface_height_above_geoid]; query...)
    temp,(tx,ty,tz,tt) = load(dataset[:sea_water_potential_temperature]; query...)
    salt,(sx,sy,sz,st) = load(dataset[:sea_water_salinity]; query...)
    u,(ux,uy,uz,ut) = load(dataset[:eastward_sea_water_velocity]; query...)
    v,(vx,vy,vz,vt) = load(dataset[:northward_sea_water_velocity]; query...)


    angle = repeat(domain.angle,inner = (1, 1, size(z_r,3)))

    missing_value = -9999;

    time = st;
    N = length(st);
    first = true;

    ds = ROMS.def_clim3(clim_filename,missing_value,size(x,1),size(x,2),size(z_r,3));

    climtime = ds["time"]
    czeta = ds["zeta"]
    cubar = ds["ubar"]
    cvbar = ds["vbar"]
    cu = ds["u"]
    cv = ds["v"]
    ctemp = ds["temp"]
    csalt = ds["salt"]

    for ni = 1:N
        t = time[ni];
        @info "load $t"

        zz = zeros(size(zeta,1),size(zeta,2));

        @info "loaded $t"
        climtime[ni] = time[ni]
        czeta[:,:,ni] = ROMS.model_interp3(zx,zy,zz,nomissing(zeta[:,:,ni],NaN),
                                           x,y,z_r[:,:,end],missing = :ufill);

        sv = nomissing(salt[:,:,:,ni],NaN)
        csalt[:,:,:,ni] = ROMS.model_interp3(sx,sy,sz,sv,x,y,z_r,missing = :ufill);

        tv = nomissing(temp[:,:,:,ni],NaN)
        ctemp[:,:,:,ni] = ROMS.model_interp3(tx,ty,tz,tv,x,y,z_r,missing = :ufill);

        uv = nomissing(u[:,:,:,ni],NaN)
        vv = nomissing(v[:,:,:,ni],NaN)

        ui_rc = ROMS.model_interp3(ux,uy,uz,uv,x,y,z_r,missing = :zero);
        vi_rc = ROMS.model_interp3(vx,vy,vz,vv,x,y,z_r,missing = :zero);


        # rotate velocity
        ui_r =  cos.(angle) .* ui_rc + sin.(angle) .* vi_rc;
        vi_r = -sin.(angle) .* ui_rc + cos.(angle) .* vi_rc;

        # stagger on C grid
        ui =  (ui_r[1:end-1,:,:] + ui_r[2:end,:,:])/2;
        vi =  (vi_r[:,1:end-1,:] + vi_r[:,2:end,:])/2;


        # depth-averaged current
        U, = ROMS.uvinteg(uv,uz);
        V, = ROMS.uvinteg(vv,vz);

        @show size(U)
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

        ubar2,vbar2 = ROMS.roms_vavg(domain,ui,vi);

        # make ubar and ui consistent
        ui = ui .+ (ubar-ubar2)
        vi = vi .+ (vbar-vbar2)

        @debug begin
            ubar2c,vbar2c = ROMS.roms_vavg(domain,ui,vi);
            @show maximum(abs.(ubar - ubar2c))
            @show maximum(abs.(vbar - vbar2c))
        end

        cu[:,:,:,ni] = ui;
        cv[:,:,:,ni] = vi;

        cubar[:,:,ni] = ubar;
        cvbar[:,:,ni] = vbar;

    end

    close(ds)
end
