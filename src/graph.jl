struct ApproxDelauneGraph <: AbstractGraph
    vertices::Vector{Vector{Int}}
    edges::Vector{Vector{Int}}
end