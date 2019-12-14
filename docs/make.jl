using Documenter, PDFToc

makedocs(;
    modules=[PDFToc],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/jagot/PDFToc.jl/blob/{commit}{path}#L{line}",
    sitename="PDFToc.jl",
    authors="Stefanos Carlström <stefanos.carlstrom@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/jagot/PDFToc.jl",
)
