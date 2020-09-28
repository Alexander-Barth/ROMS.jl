
function domain = load_domain(filename);

#default parameters
domain.Tcline = 50;
domain.theta_s = 5;
domain.theta_b = 0.4;
domain.nlevels = 32;
domain.Vtransform  = 2;
domain.Vstretching = 4;


if strcmp(filename,'LigurianSea')
  domain.grid_fname = [getenv('HOME') '/Models/LigurianSea/LigurianSea.nc'];
else
  domain.grid_fname = filename;
end

if which('ncread')
  domain.h = ncread(domain.grid_fname,'h');
  domain.mask = ncread(domain.grid_fname,'mask_rho');
  domain.mask_u = ncread(domain.grid_fname,'mask_u');
  domain.mask_v = ncread(domain.grid_fname,'mask_v');
  domain.pm = ncread(domain.grid_fname,'pm');
  domain.pn = ncread(domain.grid_fname,'pn');
  domain.lon = ncread(domain.grid_fname,'lon_rho');
  domain.lat = ncread(domain.grid_fname,'lat_rho');
  domain.lon_u = ncread(domain.grid_fname,'lon_u');
  domain.lat_u = ncread(domain.grid_fname,'lat_u');
  domain.lon_v = ncread(domain.grid_fname,'lon_v');
  domain.lat_v = ncread(domain.grid_fname,'lat_v');
  domain.lon_psi = ncread(domain.grid_fname,'lon_psi');
  domain.lat_psi = ncread(domain.grid_fname,'lat_psi');
  domain.angle = ncread(domain.grid_fname,'angle');
else
  nc = netcdf(domain.grid_fname,'r');
  domain.h = nc{'h'}(:)';
  domain.mask = nc{'mask_rho'}(:)';
  domain.pm = nc{'pm'}(:)';
  domain.pn = nc{'pn'}(:)';
  domain.lon = nc{'lon_rho'}(:)';
  domain.lat = nc{'lat_rho'}(:)';
  domain.lon_u = nc{'lon_u'}(:)';
  domain.lat_u = nc{'lat_u'}(:)';
  domain.lon_v = nc{'lon_v'}(:)';
  domain.lat_v = nc{'lat_v'}(:)';
  domain.lon_psi = nc{'lon_psi'}(:)';
  domain.lat_psi = nc{'lat_psi'}(:)';
  domain.angle = nc{'angle'}(:)';
  close(nc);  
end


hmin = min(domain.h(:));
hc=min(hmin,domain.Tcline);

report = 0;
domain.z_r = set_depth(domain.Vtransform, domain.Vstretching, ...
                              domain.theta_s, domain.theta_b, hc, domain.nlevels, ...
                              1, domain.h, zeros(size(domain.h)), report);

domain.z_w = set_depth(domain.Vtransform, domain.Vstretching, ...
                              domain.theta_s, domain.theta_b, hc, domain.nlevels, ...
                              5, domain.h, zeros(size(domain.h)), report);

#[sc_r,Cs_r,sc_w,Cs_w] = my_scoord(domain.nlevels,domain.theta_s,domain.theta_b);


#domain.z_r = makez(domain.h,hc,sc_r,Cs_r);
#domain.z_w = makez(domain.h,hc,sc_w,Cs_w);

[domain.angle_u,domain.angle_v,domain.angle_psi] = stagger(domain.angle);

[domain.pm_u,domain.pm_v,domain.pm_psi] = stagger(domain.pm);
[domain.pn_u,domain.pn_v,domain.pn_psi] = stagger(domain.pn);

domain.lon_rho = domain.lon;
domain.lat_rho = domain.lat;
domain.z_rho = domain.z_r;

[domain.z_u] = stagger_r2u(domain.z_rho);
[domain.z_v] = stagger_r2v(domain.z_rho);

[domain.h_u] = stagger_r2u(domain.h);
[domain.h_v] = stagger_r2v(domain.h);