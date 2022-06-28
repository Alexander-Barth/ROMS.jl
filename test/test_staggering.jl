using Test
using ROMS

x_r = randn(40,42)
x_u,x_v,x_psi = ROMS.stagger(x_r);
@test x_u[1,1] ≈ (x_r[1,1] + x_r[2,1])/2
@test x_v[1,1] ≈ (x_r[1,1] + x_r[1,2])/2
@test x_psi[1,1] ≈ (x_r[1,1] + x_r[1,2] + x_r[2,1] + x_r[2,2])/4

x_r = trues(40,42)
x_u,x_v,x_psi = ROMS.stagger_mask(x_r);
@test size(x_u,1) == size(x_r,1)-1
@test size(x_u,2) == size(x_r,2)

