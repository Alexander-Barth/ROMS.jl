
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

    # Earth rotation
    # https://web.archive.org/web/20160706153021/https://www.teos-10.org/pubs/gsw/pdf/f.pdf
    omega = 7.2921150e-5

    # Coriolis parameter
    f = 2*omega * sind.(y);

    @debug "create_grid"
    create_grid(grid_fname,h,f,x,y,mask,angle,pm,pn,dndx,dmde;
                opt = opt)

    return z_r,z_w
end
