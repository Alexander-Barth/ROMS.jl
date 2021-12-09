module ROMS

using Dates
using NCDatasets
using Interpolations
using Printf
using DataStructures
using DIVAnd
using Statistics
using PyPlot
import Base: getindex, download
using Base.Threads

include("constants.jl")
include("types.jl")
include("projections.jl")
include("findindex.jl")
include("gebco_load.jl")
include("reduce_res.jl")
include("smoothgrid.jl")
include("diffusion2.jl")
include("stretching.jl")
include("set_depth.jl")
include("generate_config.jl")
include("create_grid.jl")
include("staggering.jl")
include("interp_clim.jl")
include("interp1z.jl")
include("vinteg.jl")
include("model_interp3.jl")
include("vavg.jl")
include("extract_ic.jl")
include("read_time.jl")
include("metadata.jl")
include("extract_bc.jl")
include("generate_grid.jl")
include("infile.jl")
include("nudgecoef.jl")

# Generate NetCDF files
include("def_grid.jl")
include("def_clim.jl")
include("def_ic.jl")
include("def_forcing.jl")
include("def_bc.jl")
include("def_nudgecoef.jl")

# Data sources
include("CMEMS.jl")
include("opendap.jl")
include("HYCOM.jl")
include("Atmosphere/prepare_ecmwf.jl")

end
