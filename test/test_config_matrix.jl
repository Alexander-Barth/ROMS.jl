using Dates
using ROMS
using Test
using NCDatasets
using CDSAPI
using Downloads: download

# name of the domain
domain_name = "LS2v";

#bath_name = expanduser("~/Data/Bathymetry/combined_emodnet_bathymetry.nc")
#bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1.nc")
# longitude from 5°E to 15°E and latitude from 40°N to 45°N
bath_name = expanduser("~/Data/Bathymetry/gebco_30sec_1_ligurian_sea.nc")

if !isfile(bath_name)
    mkpath(dirname(bath_name))
    download("https://dox.ulg.ac.be/index.php/s/piwSaFP3nhM8jSD/download",bath_name)
end

# range of longitude
xr = [7.6, 12.2];

# range of latitude
yr = [42, 44.5];


# change time range
# t0 start time
# t1 end time

t0 = DateTime(2019,1,2);
t1 = DateTime(2019,1,4);

# take one extra day
tr = [t0-Dates.Day(1), t1+Dates.Day(1)]

# reduce bathymetry in x and y direction
red = (4, 4)

# maximum normalized topographic variations
rmax = 0.4;

# minimal depth
hmin = 2; # m

# name of folders and files

# grid file
modeldir = expanduser("~/ROMS-implementation-test")
grid_fname = joinpath(modeldir,domain_name * ".nc")

basedir = expanduser("~/ROMS-implementation-test")


function ECMWF_oper(basedir)
    # ECMWF from 2019-01-01 03:00:00  to 2019-01-07 03:00:00
    ecmwf_fname = expanduser("~/Data/Atmosphere/ecmwf_sample_data.nc")

    if !isfile(ecmwf_fname)
        mkpath(dirname(ecmwf_fname))
        download("https://dox.ulg.ac.be/index.php/s/8NJsCfk53fDFtbz/download",ecmwf_fname)
    end

    filename_prefix = joinpath(basedir,"liguriansea_ECMWF_oper_2019_")
    domain_name = "Ligurian Sea Region"
    Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
              "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

    forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,filename_prefix,domain_name)
    return forcing_filenames
end

function ECMWF_ERA5(basedir)
    ecmwf_fname = expanduser("~/.julia/dev/ROMS/examples/ecmwf_era5_2018-12-31_2019-01-08.nc")
    filename_prefix = joinpath(basedir,"liguriansea_ECMWF_ERA5_2019_")
    domain_name = "Ligurian Sea Region"
    Vnames = ["sustr","svstr","shflux","swflux","swrad","Uwind","Vwind",
              "lwrad","lwrad_down","latent","sensible","cloud","rain","Pair","Tair","Qair"]

    forcing_filenames = ROMS.prepare_ecmwf(ecmwf_fname,Vnames,filename_prefix,domain_name)
    return forcing_filenames
end


function GFS(basedir)
    cachedir = joinpath(basedir,"AGCM")
    mkpath(cachedir)

    atmo_src = ROMS.download_gfs(xr,yr,tr,cachedir)

    # outdir = expanduser("~/tmp/GFS-roms")
    filename_prefix = joinpath(basedir,"liguriansea_GFS_2019_")
    domain_name = "Ligurian Sea Region"

    Vnames = ["sustr","svstr","swflux","swrad","Uwind","Vwind",
              "sensible","cloud","rain","Pair","Tair","Qair"]
    return ROMS.prepare_gfs(atmo_src,Vnames,filename_prefix,domain_name)
end

function CMEMS_motu(basedir)
    # CMEMS credentials
    # Replace ENV["CMEMS_USERNAME"] by "your_username" and likewise ENV["CMEMS_PASSWORD"]

    cmems_username = ENV["CMEMS_USERNAME"]
    cmems_password = ENV["CMEMS_PASSWORD"]

    outdir = joinpath(basedir,"OGCM")
    mkpath(outdir)

    # Locate the dataset at https://marine.copernicus.eu/

    # Example:
    # https://resources.marine.copernicus.eu/product-detail/MEDSEA_MULTIYEAR_PHY_006_004/INFORMATION
    # Then go to:
    # Data access -> select data set -> Download options -> Subsetter -> View Script

    service_id = "MEDSEA_MULTIYEAR_PHY_006_004-TDS"
    motu_server = "https://my.cmems-du.eu/motu-web/Motu"

    mapping = Dict(
        # var  product_id
        :sea_surface_height_above_geoid => ("zos","med-cmcc-ssh-rean-d"),
        :sea_water_potential_temperature => ("thetao", "med-cmcc-tem-rean-d"),
        :sea_water_salinity => ("so","med-cmcc-sal-rean-d"),
        :eastward_sea_water_velocity => ("uo", "med-cmcc-cur-rean-d"),
        :northward_sea_water_velocity => ("vo", "med-cmcc-cur-rean-d"),
    )

    dataset = ROMS.CMEMS(cmems_username,cmems_password,service_id,mapping,outdir,
                         motu_server = motu_server)

    return dataset
end


function CMEMS_opendap(basedir)
    outdir = joinpath(basedir,"OGCM")

    cmems_username = ENV["CMEMS_USERNAME"]
    cmems_password = ENV["CMEMS_PASSWORD"]

    mapping = Dict(
        # var  product_id
        :sea_surface_height_above_geoid => ("zos","med-cmcc-ssh-rean-d"),
        :sea_water_potential_temperature => ("thetao", "med-cmcc-tem-rean-d"),
        :sea_water_salinity => ("so","med-cmcc-sal-rean-d"),
        :eastward_sea_water_velocity => ("uo", "med-cmcc-cur-rean-d"),
        :northward_sea_water_velocity => ("vo", "med-cmcc-cur-rean-d"),
    )
    ROMS.CMEMS_opendap(cmems_username,cmems_password,mapping,outdir)
end


function HYCOM(basedir)
    url = "https://tds.hycom.org/thredds/dodsC/GLBy0.08/expt_93.0"
    outdir = joinpath(basedir,"OGCM")
    return ROMS.HYCOM(url,outdir);
end


agcm = ECMWF_oper
agcm = GFS
ogcm = CMEMS_motu
ogcm = HYCOM


# model specific parameters
opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)
ROMS.generate_grid(grid_fname,bath_name,xr,yr,red,opt,hmin,rmax);
mkpath(basedir);
domain = ROMS.Grid(grid_fname,opt);

# nudging coefficient

tscale = 7; # days
alpha = 0.3;
halo = 2;
Niter = 50
max_tscale = 5e5

nud_name = joinpath(basedir,"roms_nud_$(tscale)_$(Niter).nc")
tracer_NudgeCoef = ROMS.nudgecoef(domain,nud_name,alpha,Niter,
                                  halo,tscale; max_tscale = max_tscale);

mkpath(basedir);
mkpath(modeldir);

for ogcm in [CMEMS_motu,CMEMS_opendap,HYCOM]
    # GCM interpolated on model grid
    clm_name =  joinpath(basedir,"clim_$(ogcm)_2019.nc")

    # initial conditions
    ini_name =  joinpath(basedir,"ic_$(ogcm)_2019.nc")

    # boundary conditions
    bry_name =  joinpath(basedir,"bc_$(ogcm)_2019.nc")

    @info "domain size $(size(domain.mask))"

    dataset = ogcm(basedir)
    ROMS.interp_clim(domain,clm_name,dataset,tr)
    ROMS.extract_ic(domain,clm_name,ini_name, t0);
    ROMS.extract_bc(domain,clm_name,bry_name)
end

forcing_filenames = Dict()

for agcm in [ECMWF_oper,ECMWF_ERA5,GFS]
    # Prepare atmospheric forcings

    forcing_filenames[agcm] = agcm(basedir)
end

for ogcm in [CMEMS_motu,CMEMS_opendap,HYCOM]
    for agcm in [ECMWF_oper,ECMWF_ERA5,GFS]

        # GCM interpolated on model grid
        clm_name =  joinpath(basedir,"clim_$(ogcm)_2019.nc")
        ini_name =  joinpath(basedir,"ic_$(ogcm)_2019.nc")
        bry_name =  joinpath(basedir,"bc_$(ogcm)_2019.nc")


        romsdir = expanduser("~/src/roms")
        simulationdir = joinpath(basedir,"Simulation-$(ogcm)-$(agcm)")

        intemplate = joinpath(romsdir,"User","External","roms.in")
        var_name_template = joinpath(romsdir,"ROMS","External","varinfo.yaml")

        mkpath(simulationdir)
        infile = joinpath(simulationdir,"roms.in")
        var_name = joinpath(simulationdir,"varinfo.yaml")

        cp(var_name_template,var_name; force=true)

        frc_name = unique(getindex.(forcing_filenames[agcm],2))

        openbc = ROMS.openboundaries(domain.mask)

        directions = ["west","south","east","north"]

        whenopen(BC) = join(map(d -> (d in openbc ? BC : "Clo"),directions)," ")

        # time step (seconds)
        DT = 300.
        # output frequency of ROMS in time steps
        NHIS = round(Int,24*60*60 / DT)
        NRST = NAVG = NHIS
        # number of time steps
        NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))
        NtileI = 2
        NtileJ = 2
        NtileI = 1
        NtileJ = 1

        substitutions = Dict(
            "TITLE" => "My test",
            "TIME_REF" =>  "18581117",
            "NtileI" => NtileI,
            "NtileJ" => NtileJ,
            "VARNAME" => var_name,
            "GRDNAME" => grid_fname,
            "ININAME" => ini_name,
            "BRYNAME" => bry_name,
            "CLMNAME" => clm_name,
            "NFFILES" => length(frc_name),
            "FRCNAME" => join(frc_name,"  \\\n       "),
            "Vtransform" => opt.Vtransform,
            "Vstretching" => opt.Vstretching,
            "THETA_S" => opt.theta_s,
            "THETA_B" => opt.theta_b,
            "TCLINE" => opt.Tcline,
            "Lm" => size(domain.h,1)-2,
            "Mm" => size(domain.h,2)-2,
            "N" => opt.nlevels,
            "LBC(isFsur)" => whenopen("Cha"),
            "LBC(isUbar)" => whenopen("Fla"),
            "LBC(isVbar)" => whenopen("Fla"),
            "LBC(isUvel)" => whenopen("RadNud"),
            "LBC(isVvel)" => whenopen("RadNud"),
            "LBC(isMtke)" => whenopen("Rad"),
            "LBC(isTvar)" => whenopen("RadNud") * " \\\n" * whenopen("RadNud"),
            "DT" => DT,
            "NHIS" => NHIS,
            "NAVG" => NAVG,
            "NRST" => NRST,
            "NTIMES" => NTIMES,
            "NUDNAME" => nud_name,
            "TNUDG" => "10.0d0 10.0d0",
            "LtracerCLM" => "T T",
            "LnudgeTCLM" => "T T",
            "OBCFAC" => 10.0,
        )

        ROMS.infilereplace(intemplate,infile,substitutions)


        # NBCFILES and NCLMFILES missing in roms.in but required

        text = String(read(infile));
        index = findfirst("BRYNAME",text)[1]
        text = text[1:index-1] * "NBCFILES == 1\n     NCLMFILES == 1\n     " * text[index:end]
        write(infile,text);



        romsbin = expanduser("~/ROMS-implementation-test/romsM")

        @show ogcm agcm
        cd(simulationdir) do
            run(`mpirun -np $(NtileI*NtileJ) $romsbin roms.in`)
            @test isfile("roms_his.nc")
        end

        ds = NCDataset(joinpath(simulationdir,"roms_his.nc"))
        @test ds.dim["ocean_time"] == NTIMES ÷ NHIS + 1
    end
end
