module ROMS

import Base: getindex
import Downloads: download
import STAC
using Base.Threads
using DIVAnd
using DataStructures
using Dates
using Interpolations
using NCDatasets
using Printf
using PythonPlot
using Random
using SHA
using Statistics
using URIs
using ZarrDatasets

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
include("stiffness_ratio.jl")

# Generate NetCDF files
include("def_grid.jl")
include("def_clim.jl")
include("def_ic.jl")
include("def_forcing.jl")
include("def_bc.jl")
include("def_nudgecoef.jl")

# Data sources
include("cdm.jl")
include("CMEMS.jl")
include("HYCOM.jl")
include("Atmosphere/thermodynamics.jl")
include("Atmosphere/prepare_ecmwf.jl")
include("Atmosphere/prepare_gfs.jl")

end
