using ROMS
using Test

z = reshape(-10:0,(1,1,11))
v = 2*z
zi = reshape(-10:0,(1,1,11))

vi = ROMS.interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);
@test vi ≈ 2*zi
