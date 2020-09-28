function interp1z(z,v,zi; extrap_surface = false, extrap_bottom = false);

    if z[1,1,1] > z[1,1,2]
        return interp1z(reverse(z,dims=3),reverse(v,dims=3),zi;
                        extrap_surface = extrap_surface,
                        extrap_bottom = extrap_bottom)
    end

    # vertical interpolation
    vii = fill(NaN,size(zi))
    tmpzi = zeros(size(zi,3))

    @inbounds for j=1:size(v,2)
        for i=1:size(v,1)
            tmpz = @view z[i,j,:]

            for k = 1:size(zi,3)
                tmpzi[k] = zi[i,j,k]

                if extrap_surface
                    max_tmpz = maximum(tmpz)
                    if tmpzi[k] > max_tmpz
                        tmpzi[k] = max_tmpz
                    end
                end

                if extrap_bottom
                    min_tmpz = minimum(tmpz)
                    if tmpzi[k] < min_tmpz
                        tmpzi[k] = min_tmpz
                    end
                end
            end
            itp = extrapolate(interpolate((tmpz,),(@view v[i,j,:]),Gridded(Linear())),NaN)

            for k = 1:size(zi,3)
                vii[i,j,k] = itp(tmpzi[k])
            end
        end
    end

    return vii
end
