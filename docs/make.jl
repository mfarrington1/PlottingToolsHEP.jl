using Documenter
using DocumenterVitepress
using PlottingToolsHEP

repopath = if haskey(ENV, "GITHUB_ACTION")
    "github.com/mfarrington1/PlottingToolsHEP.jl"
else
    "gitlab.cern.ch/PlottingToolsHEP-jl"
end

deploy_url = if haskey(ENV, "GITHUB_ACTION")
    nothing
else
    "PlottingToolsHEP-jl.docs.cern.ch"
end

makedocs(;
         modules=[PlottingToolsHEP],
         format=DocumenterVitepress.MarkdownVitepress(; repo = repopath, devbranch = "main", devurl = "dev", deploy_url),
         pages=[
                "Introduction" => "index.md",
                "Internal APIs" => "internalapis.md",
               ],
         repo="https://$repopath/blob/{commit}{path}#L{line}",
         sitename="PlottingToolsHEP.jl",
         authors="Michael Farrington",
        )

        
deploydocs(;
           repo=repopath,
           branch = "gh-pages",
          )
