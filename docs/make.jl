using Swizzles
using Documenter
using Literate

function julia_files(dir)
  files = reduce(vcat, [joinpath(root, file) for (root, dirs, files) in walkdir(dir) for file in files])
  sort(filter(endswith(".jl"), files))
end

function generate_markdowns()
  dir = joinpath(@__DIR__, "src")
  Threads.@threads for file in julia_files(dir)
  Literate.markdown(
    file,
    dirname(file);
    documenter = true,
  )
  end
end

generate_markdowns()

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
    "Motivation" => "motivation.md",
    "Tutorial" => "tutorial.md",
    "Reference" => "reference.md",
  ],
)

deploydocs(;
  repo="github.com/serenity4/Swizzles.jl",
  devbranch="main",
)
