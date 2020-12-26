"""
     diffusion2!(f,alpha,Niter)

Two-dimensional diffusion of field `f`. `f` is the initial condition of field.
`alpha` is a vector or tuple with two elements corresponding to the diffusion
coefficient (multiplied by grid spacing) for the two dimensions.
`Niter` is the number of iterations.
On output, `f` is the field after `Niter` iterations.
"""
function diffusion2!(f,alpha,Niter,bc! = nothing)

#if ndims(alpha) = 0
#  alpha = (alpha, alpha)
#end


imax,jmax = size(f)

mask = .!isnan.(f)
mask_u = zeros(imax+1,jmax)
mask_v = zeros(imax,jmax+1)
mask_u[2:imax,:],mask_v[:,2:jmax] = ROMS.stagger_mask(mask)

f[isnan.(f)] .= 0

F_u = zeros(imax+1,jmax)
F_v = zeros(imax,jmax+1)

for i=1:Niter
  F_u[2:end-1,:] = alpha[1] * (f[2:end,:]-f[1:end-1,:])
  F_v[:,2:end-1] = alpha[2] * (f[:,2:end]-f[:,1:end-1])

  F_u .= F_u .* mask_u
  F_v .= F_v .* mask_v

  f .= f + (F_u[2:end,:]-F_u[1:end-1,:] + F_v[:,2:end]-F_v[:,1:end-1])

  if bc! !== nothing
      bc!(f)
  end
end

    return f
end
