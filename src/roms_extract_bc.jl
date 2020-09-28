function roms_extract_bc(domain,clim_filename,bc_filename)

clim = netcdf(clim_filename,'r');
nc = netcdf(bc_filename,'c');

mask = domain.mask;
missing_value = 9999;

nc = roms_def_bc(nc,domain,missing_value);

for i=1:length(clim{'time'})
  nc{'time'}(i) = clim{'time'}(i);
  
  if any(mask(2:end-1,1))
    nc{'zeta_south'}(i,:) = squeeze(clim{'zeta'}(i,1,:));
    nc{'ubar_south'}(i,:) = squeeze(clim{'ubar'}(i,1,:));
    nc{'vbar_south'}(i,:) = squeeze(clim{'vbar'}(i,1,:));
    nc{'temp_south'}(i,:,:) = squeeze(clim{'temp'}(i,:,1,:));
    nc{'salt_south'}(i,:,:) = squeeze(clim{'salt'}(i,:,1,:));
    nc{'u_south'}(i,:,:) = squeeze(clim{'u'}(i,:,1,:));
    nc{'v_south'}(i,:,:) = squeeze(clim{'v'}(i,:,1,:));
  end
  
  if any(mask(2:end-1,end))
    nc{'zeta_north'}(i,:) = squeeze(clim{'zeta'}(i,end,:));
    nc{'ubar_north'}(i,:) = squeeze(clim{'ubar'}(i,end,:));
    nc{'vbar_north'}(i,:) = squeeze(clim{'vbar'}(i,end,:));
    nc{'temp_north'}(i,:,:) = squeeze(clim{'temp'}(i,:,end,:));
    nc{'salt_north'}(i,:,:) = squeeze(clim{'salt'}(i,:,end,:));
    nc{'u_north'}(i,:,:) = squeeze(clim{'u'}(i,:,end,:));
    nc{'v_north'}(i,:,:) = squeeze(clim{'v'}(i,:,end,:));
  end
  
  if any(mask(end,2:end-1))
    nc{'zeta_east'}(i,:) = squeeze(clim{'zeta'}(i,:,end));
    nc{'ubar_east'}(i,:) = squeeze(clim{'ubar'}(i,:,end));
    nc{'vbar_east'}(i,:) = squeeze(clim{'vbar'}(i,:,end));
    nc{'temp_east'}(i,:,:) = squeeze(clim{'temp'}(i,:,:,end));
    nc{'salt_east'}(i,:,:) = squeeze(clim{'salt'}(i,:,:,end));
    nc{'u_east'}(i,:,:) = squeeze(clim{'u'}(i,:,:,end));
    nc{'v_east'}(i,:,:) = squeeze(clim{'v'}(i,:,:,end));
  end
  
  if any(mask(1,2:end-1))
    nc{'zeta_west'}(i,:) = squeeze(clim{'zeta'}(i,:,1));
    nc{'ubar_west'}(i,:) = squeeze(clim{'ubar'}(i,:,1));
    nc{'vbar_west'}(i,:) = squeeze(clim{'vbar'}(i,:,1));
    nc{'temp_west'}(i,:,:) = squeeze(clim{'temp'}(i,:,:,1));
    nc{'salt_west'}(i,:,:) = squeeze(clim{'salt'}(i,:,:,1));
    nc{'u_west'}(i,:,:) = squeeze(clim{'u'}(i,:,:,1));
    nc{'v_west'}(i,:,:) = squeeze(clim{'v'}(i,:,:,1));
  end
end

close(nc)
close(clim)
