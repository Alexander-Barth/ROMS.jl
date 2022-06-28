using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true"
using Documenter, ROMS

makedocs(
    modules = [ROMS],
    sitename = "ROMS.jl",
    format = Documenter.HTML(
        prettyurls = CI,
    ),
    pages = [
        "Tutorial" => "index.md",
        "Plots" => "plots.md",
    ],

)

if CI
    deploydocs(repo = "github.com/Alexander-Barth/ROMS.jl.git",
               target = "build")
end
