module PDFToc
struct Heading
    title::String
    page::Int
    children::Vector{Heading}
end
Heading(title, page) = Heading(title, page, Vector{Heading}())

function Base.show(io::IO, ::MIME"text/plain", h::Heading)
    write(io, "$(h.title) ... $(h.page)")
    buf = IOBuffer()
    for c in h.children
        write(buf, "\n")
        show(buf, MIME"text/plain"(), c)
    end
    for l in split(String(take!(buf)), "\n")
        write(io, "    $(l)\n")
    end
end

function Base.show(io::IO, ::MIME"text/plain", hs::Vector{Heading})
    foreach(h -> show(io, MIME"text/plain"(), h), hs)
end

function clean_hierarchy!(headings)
    nh = length(headings)
    i = 1
    while i < nh
        li = headings[i][end]
        j = i+1
        lj = headings[j][end]
        if lj-li > 1
            k = something(findfirst(h -> h[end]≠lj, view(headings, j:nh)), nh-j) + j - 1
            for l in j:k-1
                title, page = headings[l]
                headings[l] = (title, page, li+1)
            end
            i = k
        end
        i += 1
    end
end

function readtoc(filename, patterns...)
    headings = open(filename, "r") do file
        map(eachline(file)) do line
            for (p,f) in patterns
                m = match(p, line)
                isnothing(m) && continue
                return f(m)
            end
            println("No pattern matching: ", line)
        end
    end
    clean_hierarchy!(headings)
    s = [Vector{Heading}()]
    for h in headings
        title,page,level = h[1], h[2], h[3]
        level > length(s) && push!(s, s[end][end].children)
        while level < length(s)
            pop!(s)
        end
        push!(s[end], Heading(title, page))
    end

    first(s)
end

function psescape(s)
    if isascii(s)
        "("*replace(replace(s, "(" => "\\("), ")" => "\\)")*")"
    else
        cus = vcat(0xfeff, transcode(UInt16, s))
        "<"*join(map(c -> string(c, base=16, pad=4), cus), " ")*">"
    end
end

function pdfmarks(io::IO, h::Heading; offset=0, kwargs...)
    write(io, "[")
    c = length(h.children)
    c > 0 && write(io, "/Count $(c) ")
    write(io, "/Title $(psescape(h.title)) /Page $(h.page+offset)")
    write(io, " /OUT pdfmark\n")
    foreach(hc -> pdfmarks(io, hc; offset=offset), h.children)
end

function pdfmarks(io::IO, hs::Vector{Heading};
                  title=nothing, author=nothing, year=nothing,
                  kwargs...)
    foreach(h -> pdfmarks(io, h; kwargs...), hs)
    metadata = String[]
    !isnothing(title) && push!(metadata, "/Title $(psescape(title))")
    !isnothing(author) && push!(metadata, "/Author $(psescape(author))")
    !isnothing(year) && push!(metadata, "/Year ($(year))")
    if !isempty(metadata)
        push!(metadata, "/DOCINFO pdfmark")
        write(io, "[ "*join(metadata, "\n  "))
    end
end

pdfmarks(h; kwargs...) = pdfmarks(stdout, h; kwargs...)

# https://tex.stackexchange.com/a/390337
function pdfpages(io::IO; pages=[], kwargs...)
    isempty(pages) && return
    spec = join(["$i << $s >>" for (i,s) in pages], "\n        ")
    s = """

[
  {Catalog} <<
    /PageLabels <<
      /Nums [
        $spec
      ]
    >>
  >>
/PUT pdfmark
"""
    write(io, s)
end

page_common(style, n=1; prefix=nothing) =
    (isnothing(prefix) ?
     "" : "/P $(prefix) ")*"/S /$(style) /St $(n)"

arabic(args...;kwargs...) = page_common("D", args...; kwargs...)
Roman(args...;kwargs...) = page_common("R", args...; kwargs...)
roman(args...;kwargs...) = page_common("r", args...; kwargs...)
Alph(args...;kwargs...) = page_common("A", args...; kwargs...)
alph(args...;kwargs...) = page_common("a", args...; kwargs...)

function addtoc(pdffile, tocfile, patterns...; debug=false, kwargs...)
    toc = readtoc(tocfile, patterns...)
    filename = first(splitext(pdffile))
    open("$(filename).pdfmarks", "w") do file
        pdfmarks(file, toc; kwargs...)
        pdfpages(file; kwargs...)
    end
    debug || run(`gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$(filename)-out.pdf $(pdffile) $(filename).pdfmarks`)
end

export readtoc, pdfmarks, addtoc,
    arabic, Roman, roman, Alph, alph

end # module
