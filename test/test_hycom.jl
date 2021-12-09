using ROMS
using Test

import Base: getindex, size

function combine_ind(sz,ind1,ind2)
    ind = ntuple(i -> (1:sz[i]) ,length(ind1))
    ind = getindex.(ind,ind1)
    ind = getindex.(ind,ind2)
    return ind
end

mutable struct SubView6{T,N,TA,TI} <: AbstractArray{T,N} where TA <: AbstractArray{T,N}
    data::TA
    ind::TI
end

myview(A::AbstractArray{T,N},ind...) where {T,N} = SubView6{T,N,typeof(A),typeof(ind)}(A,ind)
function getindex(A::SubView6,ind...)
    indices = combine_ind(size(A.data),A.ind,ind)
    return A.data[indices...]
end

size(A::SubView6) = size(A.data)

# URL from https://www.hycom.org/data/glbu0pt08/expt-91pt0
url = "http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_91.0"

data = rand(Int,4,5)

ind1 = (:,2:3)
ind2 = (2:4,1)

ind = combine_ind(size(data),ind1,ind2)
@test data[ind...] ==  data[ind1...][ind2...]


ind1 = (:,1:3)
ind2 = (2:2,:)

ind = combine_ind(size(data),ind1,ind2)
@test data[ind...] ==  data[ind1...][ind2...]

@test myview(data,ind1...)[ind2...] == data[ind1...][ind2...]


#=
h = ROMS.HYCOM(url)

name = :sea_water_potential_temperature

v,(x,y,z,t) = load(h,name; query...)

v,(x,y,z,t) = load(h,:sea_water_salinity; query...)

v,(x,y,t) = load(h,:sea_surface_height_above_geoid; query...)

@test ndims(v) == 3
=#
