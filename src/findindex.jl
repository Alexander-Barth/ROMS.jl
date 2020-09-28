function findindex(x,xi,tol = nothing)

    if length(x) == 1
        index = 1;
    else
        index = argmin(abs.(x .- xi))

        #index = interp1(x,[1:length(x)],xi,'nearest','extrap');
        #index = index[1]:index[end]
    end

    if tol != nothing
        if abs(x(index[1]) - xi) > tol
            error("findindex: no index");
        end
    end

    return index
end
