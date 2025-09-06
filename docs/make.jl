using CAN
using Documenter

DocMeta.setdocmeta!(CAN, :DocTestSetup, :(using CAN); recursive=true)

makedocs(;
    modules=[CAN],
    authors="Soichiro Fukamachi <ichiro.kazusa@gmail.com>",
    sitename="CAN.jl",
    format=Documenter.HTML(;
        canonical="https://ichiro-kazusa.github.io/CAN.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Example Usage" => "examples.md",
        "Supported Hardwares" => "hardwares.md",
        "References" => [
            "Interfaces" => "interfaces.md",
            "Frames" => "frames.md",
            "Internals" => "internals.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/ichiro-kazusa/CAN.jl",
    devbranch="main",
)
