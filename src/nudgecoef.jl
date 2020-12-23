function roms_nudgecoef_bc!(f,mask,halo)
    bc = zeros(size(f));

    bc[[1:halo; end-halo+1:end],:] .= 1;
    bc[:,[1:halo; end-halo+1:end]] .= 1;

    f[bc .== 1 .& mask .== 1] .= 1;
end

function nudgecoef(domain,alpha,Niter,halo,tscale; max_tscale = 5e5)
    mask = domain.mask
    xi_rho,eta_rho = size(mask);
    s_rho = domain.nlevels

    coef = zeros(xi_rho,eta_rho);
    coef[domain.mask .== 0] .= NaN;

    roms_nudgecoef_bc!(coef,domain.mask,halo);

    a = (alpha*cosd(mean(domain.lat)),
         alpha)

    diffusion2!(
        coef,a,Niter,
        f -> roms_nudgecoef_bc!(f,domain.mask,halo));

    coef[domain.mask .== 0] .= NaN;

    coef = coef / tscale;
    coef[coef .< 1 / max_tscale] .= 0;
    coef[isnan.(coef)] .= 0;


    nsea = count(domain.mask)
    nnudge = count((coef .!= 0) .& domain.mask)
    nonudge = count((coef .== 0) .& domain.mask)

    @info "Number of sea grid cell:              $nsea"
    @info "Number sea grid cell with nudging:    $nnudge"
    @info "Number sea grid cell without nudging: $nonudge"

    tracer_NudgeCoef = repeat(coef,inner=(1,1,domain.nlevels));
    return tracer_NudgeCoef
end



"""
    nudgecoef(domain,nudge_filename,alpha,Niter,halo,tscale; max_tscale = 5e5)

Generate trace nudging coefficients with a value of `1/tscale` at the
open boundaries over a `halo` grid cells. coefficients field smoothed
spatially with a diffusion coefficient `alpha` over `Niter` iterations.
For grid cells where the nudging time scale exceeds `max_tscale`, nudging is
disabled (coefficient is set to zero).
"""
function nudgecoef(domain,nudge_filename::AbstractString,alpha,Niter,
                   halo,tscale; max_tscale = 5e5)

    xi_rho,eta_rho = size(domain.mask);
    s_rho = domain.nlevels

    tracer_NudgeCoef = nudgecoef(
        domain,alpha,Niter,halo,tscale;
        max_tscale = max_tscale)

    ds = def_nudgecoef(nudge_filename,xi_rho,eta_rho,s_rho)
    ds["tracer_NudgeCoef"][:,:,:] = tracer_NudgeCoef
    close(ds)
    return tracer_NudgeCoef
end
