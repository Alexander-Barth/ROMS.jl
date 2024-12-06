"""
    ROMS.build(roms_application,modeldir;
               use_mpi = false,
               use_openmp = false,
               use_mpif90 = use_mpi,
               use_netcdf4 = true,
               my_header_dir = modeldir,
               my_analytical_dir = modeldir,
               fortran_compiler = "ifort",
               clean = true,
               jobs = 1,
               bindir = modeldir,
               extra_env = Dict(),
               )

Compile the ROMS source code with the application name  `roms_application`
and the ROMS project directory is the directory `modeldir` which will contain
the produced binaries.

See [build_roms.sh](https://github.com/myroms/roms/blob/roms-4.1/ROMS/Bin/build_roms.sh) for more information.

"""
function build(romsdir,roms_application,modeldir;
               use_mpi = false,
               use_openmp = false,
               use_mpif90 = use_mpi,
               use_netcdf4 = true,
               my_header_dir = modeldir,
               my_analytical_dir = modeldir,
               fortran_compiler = "ifort",
               extra_env = Dict(),
               clean = true,
               jobs = 1,
               bindir = modeldir,
               )

    ison(b) = (b ? "on" : "")

    build_env = Dict(
        "ROMS_APPLICATION" => roms_application,
        "USE_NETCDF4" => ison(use_netcdf4),
        "MY_HEADER_DIR" => my_header_dir,
        "MY_ANALYTICAL_DIR" => my_analytical_dir,
        "BINDIR" => bindir,
        "FORT" => fortran_compiler,         # Fortran compiler
        "USE_OpenMP" => ison(use_openmp),   # shared-memory parallelism
        "USE_MPI" => ison(use_mpi),         # distributed-memory parallelism
        "USE_MPIF90" => ison(use_mpif90),   # compile with mpif90 script
    )

    merge!(build_env,extra_env)

    cd(romsdir) do
        withenv(build_env...) do
            if clean
                run(`make clean`)
            end
            run(`make -j $jobs`)
        end
    end
    return nothing
end


"""
    ROMS.run_model(modeldir::AbstractString,romsin::AbstractString;
             use_mpi = false,
             use_openmp = false,
             stdout = stdout,
             mpiexec = "mpiexec",
             np = 1)


Executes ROMS with the model directory `modeldir` (containing the ROMS binary)
and the input file `romsin` using `np` processes (or threads for OpenMP).

"""
function run_model(modeldir::AbstractString,romsin::AbstractString;
             use_mpi = false,
             use_openmp = false,
             stdout = stdout,
             mpiexec = "mpiexec",
             np = 1)

    if use_mpi
        romsbin = joinpath(modeldir,"romsM")
        run(pipeline(`$mpiexec -np $np $romsbin $romsin`;stdout))
    elseif use_openmp
        romsbin = joinpath(modeldir,"romsO")
        withenv("OMP_NUM_THREADS" => np) do
            run(pipeline(`$romsbin`;stdin = romsin,stdout))
        end
    else
        romsbin = joinpath(modeldir,"romsS")
        run(pipeline(`$romsbin`;stdin = romsin,stdout))
    end

end
