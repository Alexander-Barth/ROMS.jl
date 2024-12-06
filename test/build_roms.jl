
romsdir = expanduser("~/src/roms")
modeldir = expanduser("~/ROMS-implementation-test")

build_env = Dict(
    "ROMS_APPLICATION" => "LigurianSea",
    "MY_PROJECT_DIR" => modeldir,
#    "MY_ROMS_SRC" => romsdir,
#    "COMPILERS" => joinpath(romsdir,"Compilers")
    "USE_MPI" => "on",         # distributed-memory parallelism
    "USE_MPIF90" => "on",      # compile with mpif90 script
    "which_MPI" => "openmpi",  # compile with OpenMPI library
    "FORT" => "gfortran",      # Fortran compiler
#    "USE_LARGE" => "on",       # activate 64-bit compilation
#    "STATIC" => "on",          # build libROMS.a
    "EXEC" => "on",            # build roms{G|M|O|S} executable
    "USE_NETCDF4" => "on",     # compile with NetCDF-4 library
    "MY_HEADER_DIR" => modeldir,
    "MY_ANALYTICAL_DIR" => modeldir,
    "BINDIR" => modeldir,
)

clean = true
jobs = 8
cd(romsdir) do
    withenv(build_env...) do
        if clean
            run(`make clean`)
        end
        run(`make -j $jobs`)
    end
end
