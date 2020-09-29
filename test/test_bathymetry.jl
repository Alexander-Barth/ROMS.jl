    i = ROMS.findindex([10.,20.,30.],20.1)
    @test i == 2

    A = Float64.(reshape(1:16,(4,4)))
    A2 = ROMS.reduce_res(A,(2,2))
    A2r = mean(mean(reshape(A,(2,2,2,2)),dims=1),dims=3)[1,:,1,:]
    @test A2 ≈ A2r

    h = Float64.(reshape(1:64,(8,8)))
    hs = ROMS.smoothgrid(h,5.,0.2)
    @test hs[4,4] ≈ 26.6854178605039
