using ROMS
using Test

x,y = ROMS.sg_mercator(5,50)
x_ref =  0.0872664625997165
y_ref =  1.01068318868302

@test x_ref ≈ x
@test y_ref ≈ y_ref
