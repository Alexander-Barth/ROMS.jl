

grdname = '/home/abarth/Models/LS2v/LS2v.nc';
fname = '/tmp/ocean_nud.nc';

varname = 'tracer_NudgeCoef';
nlevels = 32;

tscale = 10; % days

h = ncread(grdname,'h');
mask_rho = ncread(grdname,'mask_rho');

[xi_rho,eta_rho] = size(h);

coef = ones(xi_rho,eta_rho) / tscale;


delete(fname)
nccreate(fname,varname,'Dimensions',{'xi_rho',xi_rho,'eta_rho',eta_rho,'s_rho',nlevels});
ncwriteatt(fname,varname,'long_name','generic tracer inverse nudging coefficients');
ncwriteatt(fname,varname,'units','day-1');
# should be probably lon_rho lat_rho ...?
ncwriteatt(fname,varname,'coordinates','xi_rho eta_rho s_rho ');
ncwrite(fname,varname,coef);

