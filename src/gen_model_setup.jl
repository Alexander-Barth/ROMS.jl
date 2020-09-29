
# setup dir

mkpath(basedir);
mkpath(modeldir);


ROMS.generate_grid(bath_name,xr,yr,red,opt,hmin,rmax)


#=
mkpath(basedir);
domain = ROMS.Grid(opt[:grid_fname],opt);

outdir = joinpath(basedir,"OGCM")
mkpath(outdir)


dataset = ROMS.CMEMS(cmems_username,cmems_password,outdir)

#=
ds_zeta = dataset[:sea_surface_height_above_geoid]

download(ds_zeta,longitude=xr,latitude=yr,time=tr)

sv,(sx,sy,st) = load(ds_zeta,longitude=xr,latitude=yr,time=tr)
=#

#if bc_model == "hycom"
#  roms_prep_clim_hycom(domain,clim_filename,[t0:1:t1],basedir);
#elseif bc_model == "mfs"
    tr = [t0, t1]
    time = tr[1]:bc_dt:tr[end]
    ROMS.roms_interp_clim4(clim_filename,domain,dataset,tr)
#end


ROMS.extract_ic(domain,clim_filename,ic_filename, t0);

@code_warntype ROMS.extract_bc(domain,clim_filename,bc_filename)

#=

# nccreate(parent_data,"theta_s")
# ncwriteatt(parent_data,"theta_s","long_name","S-coordinate surface control parameter")
# ncwrite(parent_data,"theta_s",opt.theta_s)

# nccreate(parent_data,"theta_b")
# ncwriteatt(parent_data,"theta_b","long_name","S-coordinate bottom control parameter")
# ncwrite(parent_data,"theta_b",opt.theta_b)

# nccreate(parent_data,"Tcline")
# ncwriteatt(parent_data,"Tcline","long_name","S-coordinate surface/bottom layer width")
# ncwriteatt(parent_data,"Tcline","units","meter")
# ncwrite(parent_data,"Tcline",opt.Tcline)

# nccreate(parent_data,"hc")
# ncwriteatt(parent_data,"hc","long_name","S-coordinate parameter, critical depth")
# ncwriteatt(parent_data,"hc","units","meter")
# ncwrite(parent_data,"hc",opt.Tcline)


roms_extract_bc(domain,clim_filename,bc_filename);


=#
