"""
     field = reduce_res(field,red);
reduce resolution of field `field` by a factor "red"
"""
function reduce_res(field::AbstractArray{T,N},red) where {T,N}
    sz = size(field)
    sz2 = floor.(Int,sz ./ red);

    out = zeros(T,sz2)
    R = CartesianIndices(out)
    Ifirst = first(R)

    I1 = oneunit(Ifirst)
    I2 = CartesianIndex{N}(red)
    min_count = prod(red)/2

    @inbounds for I in R
        n = 0
        s = zero(T)

        for rJ in I1:I2
            J = CartesianIndex{N}(red .* (Tuple(I - I1))) + rJ

            fieldJ = field[J]

            if !isnan(fieldJ)
                s += fieldJ
                n += 1
            end
        end

        if n < min_count
            out[I] = NaN
        else
            out[I] = s/n
        end
    end
    return out
end
