
function roms_generate_config(grid_fname,x,y,h,mask,pm,pn,dndx,dmde,opt)

    hmin = minimum(h)
    hc=min(hmin,opt.Tcline)


    report = true;
    z_r = set_depth(opt.Vtransform, opt.Vstretching,
                    opt.theta_s, opt.theta_b, hc, opt.nlevels,
                    1, h, zeta=zeros(size(h)), report=report);

    z_w = set_depth(opt.Vtransform, opt.Vstretching,
                    opt.theta_s, opt.theta_b, hc, opt.nlevels,
                    5, h, zeta=zeros(size(h)), report=report);

    angle = zeros(size(h));

    # Earth rotation
    omega = 2*pi/(24*60*60);
    # Coriolis parameter
    f = 2*omega * cos.(pi*y/180);

    @debug "create_roms_grid"
    create_roms_grid(grid_fname,h,f,x,y,mask,angle,pm,pn,dndx,dmde);

    return z_r,z_w
end
