# # Run ROMS
#
# Run ROMS with 4 CPUs splitting the domain in 2 by 2 tiles

using Dates
using ROMS
using ROMS: whenopen


## create directories and configuration files

romsdir = expanduser("~/src/roms")
modeldir = expanduser("~/ROMS-implementation-test")
simulationdir = joinpath(modeldir,"Simulation1")
mkpath(simulationdir)


grd_name = joinpath(modeldir,"roms_grd_liguriansea.nc")
ini_name = joinpath(modeldir,"roms_ini_2023.nc")
bry_name = joinpath(modeldir,"roms_bry_2023.nc")
frc_name = joinpath.(modeldir,sort(filter(startswith("roms_frc"),readdir(modeldir))))

intemplate = joinpath(romsdir,"User","External","roms.in")
var_name_template = joinpath(romsdir,"ROMS","External","varinfo.yaml")

infile = joinpath(simulationdir,"roms.in")
var_name = joinpath(simulationdir,"varinfo.yaml")

cp(var_name_template,var_name; force=true)

domain = ROMS.Grid(grd_name,opt);

## time step (seconds)
DT = 300.
## output frequency of ROMS in time steps
NHIS = round(Int,24*60*60 / DT)
NRST = NAVG = NHIS
## number of time steps
NTIMES = floor(Int,Dates.value(t1-t0) / (DT * 1000))

NtileI = 1
NtileJ = 1

substitutions = Dict(
    "TITLE" => "My test",
    "NtileI" => NtileI,
    "NtileJ" => NtileJ,
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



modeldir = expanduser("~/ROMS-implementation-test")
simulationdir = joinpath(modeldir,"Simulation1")

np = NtileI*NtileJ

use_mpi = true

cd(simulationdir) do
    withenv("OPAL_PREFIX" => nothing) do
        ROMS.run_model(modeldir,"roms.in"; use_mpi, np)
    end
end
