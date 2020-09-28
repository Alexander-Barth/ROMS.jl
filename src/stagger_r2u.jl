function stagger_r2u(x_r)
    sz = [size(x_r)...]
    sz[1] = sz[1]-1
    x_u = (x_r[1:end-1,:,:] + x_r[2:end,:,:])/2    
    # un-flatten trailling dimensions
    x_u = reshape(x_u,(sz...,))
    return x_u
end

# Copyright (C) 2017 Alexander Barth <a.barth@ulg.ac.be>
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

