using Dates
using ROMS


# create directories and configuration files

romsdir = expanduser("~/src/roms")
simulationdir = joinpath(basedir,"Simulation1")

intemplate = joinpath(romsdir,"User","External","roms.in")
var_name_template = joinpath(romsdir,"ROMS","External","varinfo.dat")

mkpath(simulationdir)
infile = joinpath(simulationdir,"roms.in")
var_name = joinpath(simulationdir,"varinfo.dat")

cp(var_name_template,var_name; force=true)

forc_filenames  = unique(getindex.(forcing_filenames,2))

openbc = ROMS.openboundaries(domain.mask)

@show openbc
directions = ["west","south","east","north"]

whenopen(BC) = join(map(d -> (d in openbc ? BC : "Clo"),directions)," ")

# time step (seconds)
DT = 300.
# output frequency of ROMS in time steps
NHIS = round(Int,24*60*60 / DT)
NRST = NAVG = NHIS
# number of time steps
NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))

substitutions = Dict(
    "TITLE" => "My test",
    "TIME_REF" =>  "18581117",
    "VARNAME" => var_name,
    "GRDNAME" => grid_fname,
    "ININAME" => ini_name,
    "BRYNAME" => bry_name,
    "CLMNAME" => clm_name,
    "NFFILES" => length(forc_filenames),
    "FRCNAME" => join(forc_filenames,"  \\\n       "),
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


nothing
