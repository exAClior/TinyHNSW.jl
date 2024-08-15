using Graphs: AbstractSimpleGraph

struct ApproxDelaunayGraph{T} <: AbstractSimpleGraph{T}
    vtx_dict::Dict{T,Int}
    idx_dict::Dict{Int,T}
    sg::SimpleGraph{Int}
end

function ApproxDelaunayGraph()
    return ApproxDelaunayGraph(Dict{T,Int}(), Dict{Int,T}(), SimpleGraph{Int}())
end

function ApproxDelaunayGraph(vtx::T) where {T}
    return ApproxDelaunayGraph(
        Dict{T,Int}(vtx => 1), Dict{T,Int}(1 => vtx), SimpleGraph{Int}(1)
    )
end

Graphs.vertices(g::ApproxDelaunayGraph) = vertices(g.sg) 

function Graphs.add_vertex!(g::ApproxDelaunayGraph{T},vtx::T) where {T}
    vtx ∈ keys(g.vtx_dict) && return false
    add_vertex!(g.sg)
    new_vtx = nv(g.sg)
    g.vtx_dict[vtx] = new_vtx
    g.idx_dict[new_vtx] = vtx
    return vtx 
end

function Graphs.add_edge!(g::ApproxDelaunayGraph{T},s::T,d::T) where {T}
    s ∉ keys(g.vtx_dict) && return false
    d ∉ keys(g.vtx_dict) && return false
    add_edge!(g.sg, g.vtx_dict[s], g.vtx_dict[d])
    return true
end

function Graphs.neighbors(g::ApproxDelaunayGraph{T},vtx::T) where {T<:Integer}
    vtx ∉ keys(g.vtx_dict) && return Vector{Int}()
    return [g.idx_dict[n] for n in neighbors(g.sg, g.vtx_dict[vtx])]
end

function remove_edge!(g::ApproxDelaunayGraph{T},s::T,d::T) where {T}
    s ∉ keys(g.vtx_dict) && return false
    d ∉ keys(g.vtx_dict) && return false
    remove_edge!(g.sg, g.vtx_dict[s], g.vtx_dict[d])
    return true
end

function Graphs.edges(g::ApproxDelaunayGraph{T}) where {T}
    return [Edge(g.idx_dict[e.src] => g.idx_dict[e.dst]) for e in edges(g.sg)]
end