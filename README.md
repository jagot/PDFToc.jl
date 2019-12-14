# PDFToc

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jagot.github.io/PDFToc.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jagot.github.io/PDFToc.jl/dev)
[![Build Status](https://travis-ci.com/jagot/PDFToc.jl.svg?branch=master)](https://travis-ci.com/jagot/PDFToc.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/jagot/PDFToc.jl?svg=true)](https://ci.appveyor.com/project/jagot/PDFToc-jl)
[![Codecov](https://codecov.io/gh/jagot/PDFToc.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jagot/PDFToc.jl)

Small helper library to generate PDF table of contents according to http://blog.tremily.us/posts/PDF_bookmarks_with_Ghostscript/

Usage:

```julia
using PDFToc

addtoc("document.pdf", "document.toc",
       r"regex pattern 1" => m -> ("title", page, level),
       r"regex pattern 2" => m -> ("title", page, level),
       ...;
       title="Document title",
       author="Document author",
       offset=4)
```

The result will be saved to `document-out.pdf`. The file
`document.toc` is a plain text file, where each line represents one
entry in the ToC. The regex patterns will be tested on each line; the
first one that matches will have its corresponding lambda function
applied to the regex match. The return value is assumed to return a
`Tuple{String,Int,Int}` containing the title, page, and level,
respectively of the ToC entry. One can also add metadata such as
document title and author(s), as well as custom ones
(e.g. year). Finally, `offset` will be added to each page number.
