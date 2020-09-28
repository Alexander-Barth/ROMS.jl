function out = ncarray_myocean_medsea_motu(username,password,stdname,xr,yr,tr,extra,outdir)



xr(1) = xr(1) - extra;
xr(2) = xr(2) + extra;

yr(1) = yr(1) - extra;
yr(2) = yr(2) + extra;

tchunk = 60;

# adapt service_id, motu_server and ds(i).prduct_id
# for different CMEMS products

#service_id = 'MEDSEA_ANALYSIS_FORECAST_PHYS_006_001-TDS';
service_id = 'MEDSEA_ANALYSIS_FORECAST_PHY_006_013-TDS'
#motu_server = 'http://cmems-med-mfc.eu/mis-gateway-servlet/Motu'
motu_server = 'http://nrt.cmems-du.eu/motu-web/Motu'

ds(1).var = 'zos';
ds(1).product_id = 'med00-cmcc-ssh-an-fc-d';
ds(1).stdname = 'sea_surface_height';

ds(2).var = 'thetao';
ds(2).product_id = 'med00-cmcc-tem-an-fc-d';
ds(2).stdname = 'sea_water_potential_temperature';

ds(3).var = 'so';
ds(3).product_id = 'med00-cmcc-sal-an-fc-d';
ds(3).stdname = 'sea_water_salinity';

ds(4).var = 'uo';
ds(4).product_id = 'med00-cmcc-cur-an-fc-d';
ds(4).stdname = 'eastward_sea_water_velocity';

ds(5).var = 'vo';
ds(5).product_id = 'med00-cmcc-cur-an-fc-d';
ds(5).stdname = 'northward_sea_water_velocity';

i = find(strcmp(stdname,{ds.stdname}));

# Put here the path of the script motu-client-wrapper
motu_program = fullfile(getenv('HOME'),'matlab','share','motu-client-wrapper');

teps = 1/24;

filenames = {};

for time = tr(1):tchunk:(tr(end) + teps)
   tr2 = [time min(time+tchunk,(tr(end)+teps) )];
   
   fname = [ds(i).var '_' num2str(time) '.nc'];

  
   cmd = [motu_program '  ' ... 
         '-u "' username '" ' ...
         '-p "' password '" ' ...
         '-m "' motu_server '" ' ...
         '-s "' service_id '" ' ...
         '-d "' ds(i).product_id '" ' ...
         '-x "' num2str(xr(1)) '" ' ...
         '-X "' num2str(xr(2)) '" ' ...
         '-y "' num2str(yr(1)) '" ' ...
         '-Y "' num2str(yr(2)) '" ' ...         
         '--date-min="' datestr(tr2(1),'yyyy-mm-dd HH:MM:SS') '" ' ...
         '--date-max="' datestr(tr2(end)-teps,'yyyy-mm-dd HH:MM:SS') '" ' ...
         '--depth-min=0 ' ...
         '--depth-max=1000000 ' ...
          '-v "' ds(i).var '" ' ...
         '-o "' outdir '" ' ...
         '-f "' fname '" '];

   disp(cmd)
   [status] = system(cmd);

#   [status] = system(['unset LD_LIBRARY_PATH; ' cmd]);

  
   filenames{end+1} = fullfile(outdir,fname);
end

info = ncinfo(filenames{1},ds(i).var);
stdname = ncreadatt(filenames{1},ds(i).var,'standard_name')
out = ncCatArray(length(info.Size),filenames,ds(i).var,'SameAttributes',false);


# function mfs_download(mfs_filename,xr,yr,tr,extra)


# mfs_load_var = @mfs_load_var_ftp;

# chunk = 20;

# % extend domain



# scal.url = 'http://gnoodap.bo.ingv.it:8080/thredds/dodsC/MFS_BestEstimate_T';
# scal.xname = 'nav_lon';
# scal.yname = 'nav_lat';
# scal.zname = 'deptht';
# scal.tname = 'time_counter';

# [scal.x,scal.y,scal.z,scal.t,scal.zeta] = mfs_load_var(scal.url,scal.xname,scal.yname,scal.zname,scal.tname,'sossheig',xr,yr,tr);
# [scal.x,scal.y,scal.z,scal.t,scal.temp] = mfs_load_var(scal.url,scal.xname,scal.yname,scal.zname,scal.tname,'votemper',xr,yr,tr);
# [scal.x,scal.y,scal.z,scal.t,scal.salt] = mfs_load_var(scal.url,scal.xname,scal.yname,scal.zname,scal.tname,'vosaline',xr,yr,tr);


# uvel.url = 'http://gnoodap.bo.ingv.it:8080/thredds/dodsC/MFS_BestEstimate_U';
# uvel.xname = 'nav_lon';
# uvel.yname = 'nav_lat';
# uvel.zname = 'depthu';
# uvel.tname = 'time_counter';
# uvel.varname = 'vozocrtx';

# [uvel.x,uvel.y,uvel.z,uvel.t,uvel.u] = mfs_load_var(uvel.url,uvel.xname,uvel.yname,uvel.zname,uvel.tname,uvel.varname,xr,yr,tr);

# vvel.url = 'http://gnoodap.bo.ingv.it:8080/thredds/dodsC/MFS_BestEstimate_V';
# vvel.xname = 'nav_lon';
# vvel.yname = 'nav_lat';
# vvel.zname = 'depthv';
# vvel.tname = 'time_counter';
# vvel.varname = 'vomecrty';

# [vvel.x,vvel.y,vvel.z,vvel.t,vvel.v] = mfs_load_var(vvel.url,vvel.xname,vvel.yname,vvel.zname,vvel.tname,vvel.varname,xr,yr,tr);

# save(mfs_filename,'scal','uvel','vvel')
