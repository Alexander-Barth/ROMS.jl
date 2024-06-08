function sg_mercator(lon::Number,lat::Number)
    return lon*pi/180, log(tand(45 + lat/2))
end

function sg_mercator(lon,lat)
    x = similar(lon)
    y = similar(lon)
    for i in eachindex(lon)
        x[i],y[i] = sg_mercator(lon[i],lat[i])
    end
    return x,y
end


function map_to_grid(lon,lat,xshift,yshift)

    dlat_m = 110.574e3
    dlon_m = 111.320e3.*cosd(lat)
    y = similar(lat)
    x = similar(lon)
    y = 0
    x = 0

    for j ∈ 2:size(lon,2)
        y[:,j] = dlat_m.*(lat[:,j]-lat[:,j-1])+ y[:,j-1]
    end
    y = y + yshift.*(y[:,2]-y[:,1])

    for i ∈ 2:size(lon,1)
        x[i,:] = dlon_m[i,:].*(lon[i,:]-lon[i-1,:])+ x[i-1,:];
    end
    x = x + xshift.*(x[2,:]-x[1,:]);

    return x,y
end
