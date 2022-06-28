function model_interp3(x::AbstractVector,y::AbstractVector,z::AbstractVector,v,xi,yi,zi; kwargs...)
    # normalize arguments
    z3 = repeat(reshape(z,(1,1,length(z))),inner=(length(x),length(y),1))
    return model_interp3(x,y,z3,v,xi,yi,zi; kwargs...)
end


function asrange(x,tol)
    xr = range(x[1],stop=x[end],length=length(x))
    if maximum(abs.(x .- xr)) < tol
        return xr
    else
        return x
    end
end

function model_interp3(x::AbstractVector,y::AbstractVector,z,v,xi,yi,zi;
                       tol = 1e-5,
                       kwargs...)

    x = asrange(x,tol)
    y = asrange(y,tol)

    return model_interp3_(x,y,z,v,xi,yi,zi;kwargs...)
end

function model_interp3_(x::AbstractVector,y::AbstractVector,z,v,xi,yi,zi;
                       #=)
                       extrap_surface = false
                       extrap_bottom = false
                       missing = :none
=#

                       tol = 1e-5,
                        extrap_surface = true,
                       extrap_bottom = false,
                       missing = :none,
                       )

    xi_rho = size(zi,1);
    eta_rho = size(zi,2);

    kmax = size(v,3);
    vt = zeros(xi_rho, eta_rho, kmax);
    zt = zeros(xi_rho, eta_rho, kmax);

    # horizontal interpolation
    @debug "horizontal interpolation"
    @inbounds for k = 1:kmax
        v_k = v[:,:,k]
        if any(isfinite.(v_k))
            v_k = DIVAnd.ufill(v_k,isfinite.(v_k))
        end

        itpv = interpolate((x,y),v_k,Gridded(Linear()))
        itpz = interpolate((x,y),view(z,:,:,k),Gridded(Linear()))

        Threads.@threads for j = 1:eta_rho
            for i = 1:xi_rho
                vt[i,j,k] = itpv(xi[i,j],yi[i,j]);
                zt[i,j,k] = itpz(xi[i,j],yi[i,j]);
            end
        end
    end

    if kmax == 1
        vii = vt;
    else
        @debug "vertical interpolation"
        # vertical interpolation

        vii = interp1z(zt,vt,zi;
                       extrap_surface = extrap_surface,
                       extrap_bottom = extrap_bottom)
    end

    #@show extrema(vii[isfinite.(vii)])

    if missing == :ufill
        vii = DIVAnd.ufill(vii,isfinite.(vii))
    elseif missing == :zero
        vii[isnan.(vii)] .= 0
    end
    @debug "end model_interp3"

    #@show extrema(vii)
    return vii
end



function model_interp3(x::AbstractMatrix,y::AbstractMatrix,z,v,xi,yi,zi;
                       tol = 1e-5,
                       kwargs...)

    sz = size(v)
    @assert repeat(x[:,1:1],inner=(1,sz[2])) == x
    @assert repeat(y[1:1,:],inner=(sz[1],1)) == y

    if (zi isa AbstractVector) && (xi isa AbstractMatrix)
        szi = size(xi)
        zi = repeat(reshape(zi,(1,1,length(zi))),inner=(szi[1],szi[2],1))
    end

    model_interp3(x[:,1],y[1,:],z,v,xi,yi,zi; kwargs...)
end
