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
