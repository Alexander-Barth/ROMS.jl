module ROMS

using Dates
using NCDatasets
using Interpolations
using Printf
using DataStructures
using DIVAnd
using Statistics
import Base: getindex, download

include("constants.jl")
include("types.jl")
include("CMEMS.jl")
include("projections.jl")
include("findindex.jl")
include("gebco_load.jl")
include("reduce_res.jl")
include("smoothgrid.jl")
include("stretching.jl")
include("set_depth.jl")
include("roms_generate_config.jl")
include("create_roms_grid.jl")
include("defgrid.jl")
include("stagger_mask.jl")
include("stagger_r2u.jl")
include("stagger_r2v.jl")
include("roms_interp_clim4.jl")
include("interp1z.jl")
include("def_clim3.jl")
include("uvinteg.jl")
include("model_interp3.jl")
include("roms_vavg.jl")
include("extract_ic.jl")
include("roms_def_ic.jl")
include("roms_read_time.jl")
include("def_forcing.jl")
include("roms_metadata.jl")
include("roms_extract_bc.jl")
include("roms_def_bc.jl")
include("generate_grid.jl")


include("Atmosphere/prepare_ecmwf.jl")

end
