function roms_vavg(d,u,v);

    dz = d.z_w[:,:,2:end] - d.z_w[:,:,1:end-1]
    dz_u = stagger_r2u(dz);
    dz_v = stagger_r2v(dz);

    ubar = sum(dz_u .* u,dims=3) ./ sum(dz_u,dims=3);
    vbar = sum(dz_v .* v,dims=3) ./ sum(dz_v,dims=3);

    return ubar,vbar
end
