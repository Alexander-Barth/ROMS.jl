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
    @inbounds for k = 1:kmax
        itpv = interpolate((x,y),view(v,:,:,k),Gridded(Linear()))
        itpz = interpolate((x,y),view(z,:,:,k),Gridded(Linear()))

        for j = 1:eta_rho
            for i = 1:xi_rho
                vt[i,j,k] = itpv(xi[i,j],yi[i,j]);
                zt[i,j,k] = itpz(xi[i,j],yi[i,j]);
            end
        end
    end

    if kmax == 1
        vii = vt;
    else
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

    #@show extrema(vii)
    return vii
end
