function vinteg(a,z::AbstractVector)
    z3 = repeat(reshape(z,(1,1,length(z))),inner=(size(a,1),size(a,2),1))
    return vinteg(a,z3)
end


function vinteg(a,z)
    imax = size(a,1);
    jmax = size(a,2);
    kmax = size(a,3);

    Zp = zeros(imax,jmax,kmax+1);
    dz = zeros(imax,jmax,kmax);

    # z must be negative in water and decreases with k
    if any(any(z[:,:,2] .> 0)) || any(any(z[:,:,2] .> z[:,:,1]))
        error("vinteg: not implemented/tested");
    end

    if false
        for k=kmax:-1:1
            Zp[:,:,k] = 2*z[:,:,k] - Zp[:,:,k+1];
            dz[:,:,k] = Zp[:,:,k+1] - Zp[:,:,k];
        end
    else
        # for MFS - NEMO

        for k=1:kmax
            Zp[:,:,k+1] = -2*z[:,:,k] - Zp[:,:,k];
            dz[:,:,k]= Zp[:,:,k+1] - Zp[:,:,k];
        end

    end

    #Zp(1,1,:)
    #rg(dz)

    if any(dz .< 0)
        error("vinteg: negative dz")
    end

    mask = isnan.(a) .| isnan.(z);

    dz[mask] .= 0;
    a[mask] .= 0;

    h = sum(dz,dims=3);
    b = sum(a.*dz,dims=3);

    return b,dz
end
