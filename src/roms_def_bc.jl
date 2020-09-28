# domain.z_r and domain.mask

function nc = roms_def_bc(nc,domain,missing_value)

xi_rho = size(domain.z_r,1);
eta_rho = size(domain.z_r,2);
s_rho = size(domain.z_r,3);
mask = domain.mask;

d = {};

if any(mask(2:end-1,1)),    d{end+1} = 'south';  end
if any(mask(2:end-1,end)),  d{end+1} = 'north';  end
if any(mask(1,2:end-1)),    d{end+1} = 'west';   end
if any(mask(end,2:end-1)),  d{end+1} = 'east';   end
  

# dimensions

nc('xi_rho') = xi_rho;
nc('xi_u') = xi_rho-1;
nc('xi_v') = xi_rho;
nc('eta_rho') = eta_rho;
nc('eta_u') = eta_rho;
nc('eta_v') = eta_rho-1;
nc('s_rho') = s_rho;
nc('time') = 0;

#% Variables and attributes:

nc{'time'} = ncdouble('time'); 
nc{'time'}.long_name = ncchar('time');
nc{'time'}.units = ncchar('day');
nc{'time'}.field = ncchar('temp_time, scalar, series');
nc{'time'}.missing_value = ncdouble(missing_value);

for i=1:length(d)
  if strcmp(d{i},'south') || strcmp(d{i},'north')
    dim_rho = 'xi_rho';
    dim_u = 'xi_u';
    dim_v = 'xi_v';
  else
    dim_rho = 'eta_rho';
    dim_u = 'eta_u';
    dim_v = 'eta_v';
  end


nc{['zeta_' d{i}]} = ncdouble('time',dim_rho);  
nc{['zeta_' d{i}]}.long_name = ncchar('free-surface southern boundary condition');
nc{['zeta_' d{i}]}.units = ncchar('meter');
nc{['zeta_' d{i}]}.field = ncchar('zeta_south, scalar, series');
nc{['zeta_' d{i}]}.time = ncchar('time');
nc{['zeta_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['zeta_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['ubar_' d{i}]} = ncdouble('time',dim_u);  
nc{['ubar_' d{i}]}.long_name = ncchar('2D u-momentum southern boundary condition');
nc{['ubar_' d{i}]}.units = ncchar('meter second-1');
nc{['ubar_' d{i}]}.field = ncchar('ubar_south, scalar, series');
nc{['ubar_' d{i}]}.time = ncchar('time');
nc{['ubar_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['ubar_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['vbar_' d{i}]} = ncdouble('time',dim_v);  
nc{['vbar_' d{i}]}.long_name = ncchar('2D v-momentum southern boundary condition');
nc{['vbar_' d{i}]}.units = ncchar('meter second-1');
nc{['vbar_' d{i}]}.field = ncchar('vbar_south, scalar, series');
nc{['vbar_' d{i}]}.time = ncchar('time');
nc{['vbar_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['vbar_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['temp_' d{i}]} = ncdouble('time', 's_rho', dim_rho); 
nc{['temp_' d{i}]}.long_name = ncchar('potential temperature southern boundary condition');
nc{['temp_' d{i}]}.units = ncchar('Celsius');
nc{['temp_' d{i}]}.field = ncchar('temp_south, scalar, series');
nc{['temp_' d{i}]}.time = ncchar('time');
nc{['temp_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['temp_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['salt_' d{i}]} = ncdouble('time', 's_rho', dim_rho); 
nc{['salt_' d{i}]}.long_name = ncchar('salinity southern boundary condition');
nc{['salt_' d{i}]}.units = ncchar('PSU');
nc{['salt_' d{i}]}.field = ncchar('salt_south, scalar, series');
nc{['salt_' d{i}]}.time = ncchar('time');
nc{['salt_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['salt_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['u_' d{i}]} = ncdouble('time','s_rho',dim_u); 
nc{['u_' d{i}]}.long_name = ncchar('3D u-momentum southern boundary condition');
nc{['u_' d{i}]}.units = ncchar('meter second-1');
nc{['u_' d{i}]}.field = ncchar('u_south, scalar, series');
nc{['u_' d{i}]}.time = ncchar('time');
nc{['u_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['u_' d{i}]}.FillValue_ = ncdouble(missing_value);

nc{['v_' d{i}]} = ncdouble('time','s_rho',dim_v); 
nc{['v_' d{i}]}.long_name = ncchar('3D v-momentum southern boundary condition');
nc{['v_' d{i}]}.units = ncchar('meter second-1');
nc{['v_' d{i}]}.field = ncchar('v_south, scalar, series');
nc{['v_' d{i}]}.time = ncchar('time');
nc{['v_' d{i}]}.missing_value = ncdouble(missing_value);
nc{['v_' d{i}]}.FillValue_ = ncdouble(missing_value);

end

# global attributes

nc.type = ncchar('BOUNDARY FORCING file');
#nc.title = ncchar('West Florida Shelf Model');
