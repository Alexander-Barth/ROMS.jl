using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true"
using Documenter
using ROMS
import Literate

# Literate.markdown(
#     joinpath(@__DIR__, "..", "examples", "04_plots.jl"),
#     joinpath(@__DIR__, "src"),
#     execute = true,
#     documenter = true,
#     # We add the credit to Literate.jl the footer
#     credit = false,
# )


files = joinpath.(@__DIR__, "..", "examples", [
    "01_build_roms.jl",
    "02_prep_roms.jl",
    "03_run_roms.jl",
    "04_plots.jl",
    "05_plots_makie.jl",
])

all_notebooks = joinpath(mktempdir(),"all.jl")
write(all_notebooks, join(read.(files,String),"\n"))
push!(files,all_notebooks)

for file in files
    Literate.notebook(
        file,
        joinpath(@__DIR__, "src"),
        execute = false,
    )

    if !endswith(file,"all.jl")
        Literate.markdown(
            file,
            joinpath(@__DIR__, "src"),
            execute = true,
            #execute = false,
            documenter = true,
            # We add the credit to Literate.jl the footer
            credit = false,
        )
    end
end


makedocs(
    modules = [ROMS],
    sitename = "ROMS.jl",
    format = Documenter.HTML(
        prettyurls = CI,
        footer = "Powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl), [Literate.jl](https://github.com/fredrikekre/Literate.jl) and the [Julia Programming Language](https://julialang.org/)",
        #size_threshold = 400_000,

    ),
    pages = [
        "Tutorial" => "index.md",
        "Compilation" => "01_build_roms.md",
        "Preparation" =>  "02_prep_roms.md",
        "Running ROMS"=> "03_run_roms.md",
        "Plots" => "04_plots.md",
        "Plots (Makie)" => "05_plots_makie.md",
        "Additional information" => "additional_info.md",
        "Reference" => "reference.md",
    ],
)

deploydocs(repo = "github.com/Alexander-Barth/ROMS.jl.git",
           target = "build",
           devbranch = "roms-4.1",
           devurl = "JuliaEO25",
           )
