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


function readtoc(filename, patterns...)
    headings = open(filename, "r") do file
        map(eachline(file)) do line
            for (p,f) in patterns
                m = match(p, line)
                isnothing(m) && continue
                return f(m)
            end
            println(line)
        end
    end
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

function pdfmarks(io::IO, h::Heading; offset=0)
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

function addtoc(pdffile, tocfile, patterns...; kwargs...)
    toc = readtoc(tocfile, patterns...)
    filename = first(splitext(pdffile))
    open("$(filename).pdfmarks", "w") do file
        pdfmarks(file, toc; kwargs...)
    end
    run(`gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$(filename)-out.pdf $(pdffile) $(filename).pdfmarks`)
end

export readtoc, pdfmarks, addtoc

end # module
