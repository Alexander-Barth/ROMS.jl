using ROMS
using Test

z = reshape(-10:0,(1,1,11))
v = 2*z
zi = reshape(-10:0,(1,1,11))

vi = ROMS.interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);
@test vi ≈ 2*zi


kmax = 10
z_w = zeros(1,1,kmax+1)
z_w[1,1,:] = range(0,-100,length = kmax+1)
z = (z_w[:,:,1:end-1] + z_w[:,:,2:end])/2

v = 2*z + (z/10).^2
integ,dz = ROMS.vinteg(v,z)
@test dz ≈ z_w[:,:,1:end-1] - z_w[:,:,2:end]


integ2,dz2 = ROMS.vinteg(reverse(v,dims=3),reverse(z,dims=3))

@test integ2 ≈ integ
@test dz2 ≈ dz
