using CANBus
using Documenter

DocMeta.setdocmeta!(CANBus, :DocTestSetup, :(using CANBus); recursive=true)

makedocs(;
    modules=[CANBus],
    authors="Soichiro Fukamachi <ichiro.kazusa@gmail.com>",
    sitename="CANBus.jl",
    format=Documenter.HTML(;
        canonical="https://ichiro-kazusa.github.io/CANBus.jl",
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
        ],
        "Changelog" => "changelog.md"
    ],
)

deploydocs(;
    repo="github.com/ichiro-kazusa/CANBus.jl",
    devbranch="main",
)
