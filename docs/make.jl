using CANBus
import CANalyze
using Documenter
using DocumenterMermaid

DocMeta.setdocmeta!(CANBus, :DocTestSetup, :(using CANBus); recursive=true)

makedocs(;
    modules=[CANBus],
    authors="Soichiro Fukamachi <ichiro.kazusa@gmail.com>",
    sitename="CANBus.jl",
    format=Documenter.HTML(;
        canonical="https://ichiro-kazusa.github.io/CANBus.jl",
        edit_link="main",
        assets=[
            Documenter.HTMLWriter.RawHTMLHeadContent("""
               <meta name="google-site-verification" content="QxLomniwDlUJDp7nGuHXoaQFlSdZxmLtb-8lxSeh2p8" />
            """)
        ]
    ),
    pages=[
        "Home" => "index.md",
        "Example Usage" => "examples.md",
        "Supported Hardwares" => "hardwares.md",
        "References" => [
            "Interfaces" => "interfaces.md",
            "InterfaceCfgs" => "interfacecfgs.md",
            "Frames" => "frames.md",
            "Error Handling" => "errors.md",
            "Internals" => "internals.md"
        ],
        "Changelog" => "changelog.md"
    ],
)

deploydocs(;
    repo="github.com/ichiro-kazusa/CANBus.jl",
    devbranch="main",
)
