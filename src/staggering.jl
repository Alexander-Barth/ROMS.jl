
function stagger_mask!(mask_r,op,mask_u,mask_v,mask_psi)
    sz = size(mask_r)
    Rpost = CartesianIndices(sz[3:end])

    for Ipost in Rpost
        #= @inbounds =# for j = 1:sz[2]
            for i = 1:sz[1]-1
                mask_u[i,j,Ipost] = op(mask_r[i,j,Ipost],mask_r[i+1,j,Ipost])
            end
        end

        #= @inbounds =# for j = 1:sz[2]-1
            for i = 1:sz[1]
                mask_v[i,j,Ipost] = op(mask_r[i,j,Ipost],mask_r[i,j+1,Ipost])
            end
        end

        #= @inbounds =# for j = 1:sz[2]-1
            for i = 1:sz[1]-1
                mask_psi[i,j,Ipost] = op(mask_r[i,j,Ipost],mask_r[i,j+1,Ipost],
                                   mask_r[i+1,j,Ipost],mask_r[i+1,j+1,Ipost])
            end
        end
    end
end


function stagger_mask(mask_r,op = &)
    sz = size(mask_r)
    mask_u   = similar(mask_r,(sz[1]-1,sz[2],  sz[3:end]...))
    mask_v   = similar(mask_r,(sz[1],  sz[2]-1,sz[3:end]...))
    mask_psi = similar(mask_r,(sz[1]-1,sz[2]-1,sz[3:end]...))

    stagger_mask!(mask_r,op,mask_u,mask_v,mask_psi)
    return mask_u,mask_v,mask_psi
end

_avg(a,b) = (a+b)/2
_avg(a,b,c,d) = (a+b+c+d)/4

stagger(x_r) = stagger_mask(x_r,_avg)

function stagger_r2u(x_r)
    sz = [size(x_r)...]
    sz[1] = sz[1]-1
    x_u = (x_r[1:end-1,:,:] + x_r[2:end,:,:])/2
    # un-flatten trailling dimensions
    x_u = reshape(x_u,(sz...,))
    return x_u
end

function stagger_r2v(x_r)
    sz = [size(x_r)...]
    sz[2] = sz[2]-1
    x_v = (x_r[:,1:end-1,:] + x_r[:,2:end,:])/2
    # un-flatten trailling dimensions
    x_v = reshape(x_v,(sz...,))
    return x_v
end



# Copyright (C) 2009,2020 Alexander Barth <a.barth@ulg.ac.be>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; If not, see <http://www.gnu.org/licenses/>.
