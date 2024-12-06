using Dates
using ROMS
using ROMS: whenopen


# create directories and configuration files

romsdir = expanduser("~/src/roms")
simulationdir = joinpath(basedir,"Simulation1")

intemplate = joinpath(romsdir,"User","External","roms.in")
var_name_template = joinpath(romsdir,"ROMS","External","varinfo.yaml")

mkpath(simulationdir)
infile = joinpath(simulationdir,"roms.in")
var_name = joinpath(simulationdir,"varinfo.yaml")

cp(var_name_template,var_name; force=true)

frc_name = unique(getindex.(forcing_filenames,2))

# time step (seconds)
DT = 300.
# output frequency of ROMS in time steps
NHIS = round(Int,24*60*60 / DT)
NRST = NAVG = NHIS
# number of time steps
NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))

substitutions = Dict(
    "TITLE" => "My test",
    "TIME_REF" => "18581117",
    "VARNAME" => var_name,
    "GRDNAME" => grd_name,
    "ININAME" => ini_name,
    "BRYNAME" => bry_name,
    "CLMNAME" => clm_name,
    "NFFILES" => length(frc_name),
    "FRCNAME" => join(frc_name,"  \\\n       "),
    "Vtransform" => domain.Vtransform,
    "Vstretching" => domain.Vstretching,
    "THETA_S" => domain.theta_s,
    "THETA_B" => domain.theta_b,
    "TCLINE" => domain.Tcline,
    "Lm" => size(domain.h,1)-2,
    "Mm" => size(domain.h,2)-2,
    "N" => domain.nlevels,
    "LBC(isFsur)" => whenopen(domain,"Cha"),
    "LBC(isUbar)" => whenopen(domain,"Fla"),
    "LBC(isVbar)" => whenopen(domain,"Fla"),
    "LBC(isUvel)" => whenopen(domain,"RadNud"),
    "LBC(isVvel)" => whenopen(domain,"RadNud"),
    "LBC(isMtke)" => whenopen(domain,"Rad"),
    "LBC(isTvar)" => whenopen(domain,"RadNud") * " \\\n" * whenopen(domain,"RadNud"),
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


nothing
