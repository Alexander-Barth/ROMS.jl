using ROMS
using Test

theta_s =  5
theta_b =  0.4
Vtransform =  2
Vstretching =  4

hc = 50; N = 10; kgrid = 1;

s_ref = [-1.0,  -0.9,  -0.8,  -0.7,  -0.6,  -0.5,  -0.4,  -0.3,  -0.2,  -0.1, 0.]
C_ref = [-1.000000000000000, -0.648358846221329, -0.406115736567400, -0.247411330585220, -0.146615163717739, -0.083875204222181, -0.045433766989769, -0.022330684710868, -0.008987056975688, -0.002114389421634,  0.000000000000000]
s,C = ROMS.stretching(Vstretching, theta_s, theta_b, hc, N, kgrid)
@test s_ref ≈ s_ref
@test C_ref ≈ C_ref

for Vstretching = 1:5
    local s,C
    s,C = ROMS.stretching(Vstretching, theta_s, theta_b, hc, N, kgrid)
end

hc = 50
theta_s =  5
theta_b =  0.4
N = 10
Vtransform =  2
Vstretching =  4
igrid = 1
h = 100*ones(20,20)
zeta = zeros(20,20);
z = ROMS.set_depth(Vtransform, Vstretching, theta_s, theta_b, hc, N,  igrid, h;
                   zeta = zeta);

z_ref = [-85.6156490828721, -62.6705707676990, -46.2021211503469, -34.4112258271638, -25.7652178611963, -19.1514577479149, -13.8252107015086, -9.31253620976400, -5.32532093820320,  -1.70137067316492]

@test z[10,10,:] ≈ z_ref

for igrid = 1:5
    for Vstretching = 1:5
        for Vtransform = 1:2
            local z
            z = ROMS.set_depth(Vtransform, Vstretching, theta_s, theta_b, hc, N,  igrid, h;
                               zeta = zeta);
        end
    end
end
