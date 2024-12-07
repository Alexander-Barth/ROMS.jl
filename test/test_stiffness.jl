using ROMS
using NCDatasets
using Test

grid_fname = expanduser("~/ROMS-implementation-test/roms_grd_liguriansea.nc")

opt = (
    Tcline = 50,   # m
    theta_s = 5,   # surface refinement
    theta_b = 0.4, # bottom refinement
    nlevels = 32,  # number of vertical levels
    Vtransform  = 2,
    Vstretching = 4,
)


domain = ROMS.Grid(grid_fname,opt);
rx0,rx1 = ROMS.stiffness_ratios(domain)

# sample values from ROMS 4.0

@test rx0 ≈ 3.636036e-01
@test rx1 ≈ 12.862159656699477
