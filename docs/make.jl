using Swizzles
using Documenter

DocMeta.setdocmeta!(Swizzles, :DocTestSetup, :(using Swizzles); recursive=true)

makedocs(;
    modules=[Swizzles],
    authors="Cédric BELMANT",
    repo="https://github.com/serenity4/Swizzles.jl/blob/{commit}{path}#{line}",
    sitename="Swizzles.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://serenity4.github.io/Swizzles.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/serenity4/Swizzles.jl",
    devbranch="main",
)
