using Documenter
using PlottingToolsHEP

makedocs(;
    modules  = [PlottingToolsHEP],
    sitename = "PlottingToolsHEP.jl",
    authors  = "Michael Farrington",
    repo     = "https://github.com/mfarrington1/PlottingToolsHEP.jl/blob/{commit}{path}#{line}",
    format   = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical  = "https://mfarrington1.github.io/PlottingToolsHEP.jl",
        edit_link  = "main",
    ),
    pages = [
        "Home"          => "index.md",
        "Usage"         => "usage.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo      = "github.com/mfarrington1/PlottingToolsHEP.jl",
    devbranch = "main",
    push_preview = true,
)
