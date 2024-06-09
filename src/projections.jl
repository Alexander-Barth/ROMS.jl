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

function map_to_grid(lon, lat, xshift, yshift)
    dlat_m = 110.574e3
    dlon_m = 111.320e3 .* cosd.(lat)

    # Initialize y with zeros and preallocate memory
    y = similar(lat)
    fill!(y, 0)

    # Calculate y values
    for j = 2:size(lon, 2)
        y[:, j] .= dlat_m .* (lat[:, j] .- lat[:, j-1]) .+ y[:, j-1]
    end
    for i = 2:size(lon, 1)
        y[i,:] .+= yshift * (y[i, 2] - y[i, 1])
    end

    # Initialize x with zeros and preallocate memory
    x = similar(lon)
    fill!(x, 0)

    # Calculate x values
    for i = 2:size(lon, 1)
        x[i, :] .= dlon_m[i, :] .* (lon[i, :] .- lon[i-1, :]) .+ x[i-1, :]
    end
    for j = 2:size(lon, 2)
        x[:,j] .+= xshift * (x[2, j] - x[1, j])
    end

    # center the x-grid
    for j = 1:size(lon,2)
        x[:, j] .+=  - dlon_m[:, j].* (lon[end, j] - lon[1, j])/2
    end

    return x, y
end
