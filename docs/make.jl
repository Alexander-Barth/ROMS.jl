using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true"
using Documenter
using ROMS
import Literate

Literate.markdown(
    joinpath(@__DIR__, "..", "examples", "plots.jl"),
    joinpath(@__DIR__, "src"),
    execute = true,
    documenter = true,
    # We add the credit to Literate.jl the footer
    credit = false,
)

Literate.notebook(
    joinpath(@__DIR__, "..", "examples", "plots.jl"),
    joinpath(@__DIR__, "src"),
    execute = false,
)


makedocs(
    modules = [ROMS],
    sitename = "ROMS.jl",
    format = Documenter.HTML(
        prettyurls = CI,
        footer = "Powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl), [Literate.jl](https://github.com/fredrikekre/Literate.jl) and the [Julia Programming Language](https://julialang.org/)"

    ),
    pages = [
        "Tutorial" => "index.md",
        "Reference" => "reference.md",
        "Plots" => "plots.md",
    ],
)

deploydocs(repo = "github.com/Alexander-Barth/ROMS.jl.git",
           target = "build",
           devbranch = "roms-4.1",
           devurl = "JuliaEO25",
           )
