"""
    x,y,b = gebco_load(bath_name,xr,yr)

Loads GEBCO bathymetry with lon and lat range xr, yr.
"""
function gebco_load(bath_name,xr,yr)
    NCDataset(bath_name,"r") do ds
        x = nomissing(ds["lon"][:]);
        y = nomissing(ds["lat"][:]);

        i = findindex(x,xr[1]):findindex(x,xr[2])
        j = findindex(y,yr[1]):findindex(y,yr[2])

        b = nomissing(ds["bat"][i,j],NaN);
        x = x[i];
        y = y[j];

        return x,y,Float64.(b)
    end
end
