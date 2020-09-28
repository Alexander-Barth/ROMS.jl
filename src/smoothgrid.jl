"""

Smooth the topography to get a maximum r factor = rmax
Copyright (c) 2002-2006 by Pierrick Penven, GPL
"""
function smoothgrid(h,hmin,rmax)
    println(" Smooth the topography...")
    h = copy(h)

    in=findall(isnan.(h))
    if length(in) > 0
        println("NaN values found in interpolated h, set to mindepth");
        h[in] .= hmin;
    end

    h[h .< hmin] .= hmin;
    h = rotfilter(h,rmax);

    #println(["hmin = ",num2str(min(min(h)))])
    #
    #  Smooth the topography again
    #
    println(" Smooth the topography a bit more...")
    n=4;
    for i=1:n
        h=hanning(h);
    end
    println("  hmin = ",minimum(h))
    return h
end


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rotfilter(h,rmax)
    M,L = size(h);
    Mm = M-1;
    Mmm = M-2;
    Lm = L-1;
    Lmm = L-2;
    cff = 0.8;
    nu = 3/16;
    rx,ry = rfact(h);
    r = max(maximum(rx),maximum(ry))
    h = log.(h);
    i = 0;
    while r>rmax
        i = i+1;
        cx = Float64.((rx .> cff*rmax))
        cx = hanning(cx);
        cy = Float64.((ry .> cff*rmax))
        cy = hanning(cy);
        fx = cx.*FX(h);
        fy = cy.*FY(h);
        h[2:Mm,2:Lm] = h[2:Mm,2:Lm] + nu * (
            ((fx[2:Mm,2:Lm]-fx[2:Mm,1:Lmm]) +
             (fy[2:Mm,2:Lm]-fy[1:Mmm,2:Lm])))

        h[1,:] = h[2,:];
        h[M,:] = h[Mm,:];
        h[:,1] = h[:,2];
        h[:,L] = h[:,Lm];
        rx,ry = rfact(exp.(h));
        r = max(maximum(rx),maximum(ry))
    end
    println("  ",i," iterations - rmax = ",r)
    h = exp.(h);
    return h
end
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rfact(h);
    M,L = size(h);
    Mm = M-1;
    Mmm = M-2;
    Lm = L-1;
    Lmm = L-2;

    rx = abs.(h[1:M,2:L]-h[1:M,1:Lm]) ./ (h[1:M,2:L]+h[1:M,1:Lm]);
    ry = abs.(h[2:M,1:L]-h[1:Mm,1:L]) ./ (h[2:M,1:L]+h[1:Mm,1:L]);
    return rx,ry
end
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hanning(h);
    h = copy(h)
    M,L = size(h);
    Mm = M-1;
    Mmm = M-2;
    Lm = L-1;
    Lmm = L-2;

    h[2:Mm,2:Lm] = 0.125*(h[1:Mmm,2:Lm]+h[3:M,2:Lm] +
                          h[2:Mm,1:Lmm]+h[2:Mm,3:L] +
                          4*h[2:Mm,2:Lm]);
    h[1,:] = h[2,:];
    h[M,:] = h[Mm,:];
    h[:,1] = h[:,2];
    h[:,L] = h[:,Lm];
    return h
end
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FX(h);
    M,L = size(h);
    Mm = M-1;
    Mmm = M-2;
    Lm = L-1;
    Lmm = L-2;

    fx = zeros(M,Lm)
    fx[2:Mm,:] = (h[2:Mm,2:L]-h[2:Mm,1:Lm])*5/12 +
        (h[1:Mmm,2:L]-h[1:Mmm,1:Lm]+h[3:M,2:L]-h[3:M,1:Lm])/12;
    fx[1,:] = fx[2,:];
    fx[M,:] = fx[Mm,:];
    return fx
end

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FY(h)
    M,L = size(h);
    Mm = M-1;
    Mmm = M-2;
    Lm = L-1;
    Lmm = L-2;

    fy = zeros(Mm,L)
    fy[:,2:Lm] = (h[2:M,2:Lm]-h[1:Mm,2:Lm])*5/12 +
        (h[2:M,1:Lmm]-h[1:Mm,1:Lmm]+h[2:M,3:L]-h[1:Mm,3:L])/12;
    fy[:,1] = fy[:,2];
    fy[:,L] = fy[:,Lm];
    return fy
end
