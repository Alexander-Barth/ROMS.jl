"""
    rx0,rx1 = ROMS.stiffness_ratios(mask_u,mask_v,z_w)
    rx0,rx1 = ROMS.stiffness_ratios(domain)

Compute maximum grid stiffness ratios following [Beckmann and Haidvogel](https://doi.org/10.1175/1520-0485(1993)023<1736:NSOFAA>2.0.CO;2)
(`rx0`) and [Haney](https://doi.org/10.1175/1520-0485(1991)021<0610:OTPGFO>2.0.CO;2) (`rx1`).
"""
function stiffness_ratios(mask_u,mask_v,z_w::AbstractArray{T,3}) where T
    # u -> julia j = 2: Fortran Jstr=1
    # u -> julia i = 3: Fortran IstrU=2

    rx0 = T(0)
    rx1 = T(0)


    #IstrU,Iend           2         136
    # Jstr,Jend           1          73

    # Fortran               | julia
    # z_w(2,2,0)            | z_w[3,3,1]
    # z_w(IstrU,Jstr,0)     | z_w[3,2,1]
    # z_w(IstrU+1,Jstr,0)   | z_w[4,2,1]
    # z_w(IstrU,Jstr+1,0)   | z_w[3,3,1]
    # z_w(IstrU+1,Jstr+1,0) | z_w[4,3,1]

    # z_w(IstrU,Jstr,0)     | z_w[3,2,1]
    # z_w(IstrU,Jstr,1)     | z_w[3,2,2]


    for j = 2:size(mask_u,2)
        for i = 3:size(mask_u,1)+1
            if mask_u[i-1,j]
                local_rx0 = (
                    (z_w[i,j,1]-z_w[i-1,j,1])
                    /
                        (z_w[i,j,1]+z_w[i-1,j,1])
                )
                rx0=max(rx0,abs(local_rx0))

                for k = 2:size(z_w,3)
                    local_rx1 = (
                        (z_w[i,j,k]-z_w[i-1,j,k] + z_w[i,j,k-1]-z_w[i-1,j,k-1])
                        /
                            (z_w[i,j,k]+z_w[i-1,j,k] - z_w[i,j,k-1]-z_w[i-1,j,k-1])
                    )
                    rx1=max(rx1,abs(local_rx1))
                end
            end
        end
    end


    for j = 3:size(mask_v,2)+1
        for i = 2:size(mask_v,1)
            if mask_v[i,j-1]
                local_rx0 = (
                    (z_w[i,j,1]-z_w[i,j-1,1])
                    /
                        (z_w[i,j,1]+z_w[i,j-1,1])
                )
                rx0=max(rx0,abs(local_rx0))

                for k = 2:size(z_w,3)
                    local_rx1 = (
                        (z_w[i,j,k]-z_w[i,j-1,k] + z_w[i,j,k-1]-z_w[i,j-1,k-1])
                        /
                            (z_w[i,j,k]+z_w[i,j-1,k] - z_w[i,j,k-1]-z_w[i,j-1,k-1])
                    )
                    rx1=max(rx1,abs(local_rx1))
                end
            end
        end
    end

    return rx0,rx1
end


stiffness_ratios(domain::Grid) = stiffness_ratios(domain.mask_u,domain.mask_v,domain.z_w)
