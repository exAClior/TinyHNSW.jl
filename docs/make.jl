using TinyHNSW
using Documenter

DocMeta.setdocmeta!(TinyHNSW, :DocTestSetup, :(using TinyHNSW); recursive=true)

makedocs(;
    modules=[TinyHNSW],
    authors="Yusheng Zhao",
    sitename="TinyHNSW.jl",
    format=Documenter.HTML(;
        canonical="https://exAClior.github.io/TinyHNSW.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/exAClior/TinyHNSW.jl",
    devbranch="main",
)
