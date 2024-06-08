
function generate_config(grid_fname,x,y,h,mask,pm,pn,dndx,dmde,opt)

    hmin = minimum(h)

    if opt.Vtransform == 1
        hc = min(hmin,opt.Tcline)
    else
        hc = opt.Tcline
    end

    report = true;
    z_r = set_depth(opt.Vtransform, opt.Vstretching,
                    opt.theta_s, opt.theta_b, hc, opt.nlevels,
                    1, h, zeta=zeros(size(h)), report=report);

    z_w = set_depth(opt.Vtransform, opt.Vstretching,
                    opt.theta_s, opt.theta_b, hc, opt.nlevels,
                    5, h, zeta=zeros(size(h)), report=report);

    angle = zeros(size(h));

    # Coriolis parameter
    #omega = 2*pi/(24*60*60);
    #f = 2*omega * cos.(pi*y/180);
    omega = 7.2921150e-5;
    f = 2*omega * sind.(y);

    @debug "create_grid"
    create_grid(grid_fname,h,f,x,y,mask,angle,pm,pn,dndx,dmde);

    return z_r,z_w
end
