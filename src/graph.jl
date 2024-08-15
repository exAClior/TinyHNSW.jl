using Graphs: AbstractSimpleGraph

struct ApproxDelaunayGraph{T} <: AbstractSimpleGraph{T}
    vtx_dict::Dict{T,Int}
    edges::Vector{Vector{Int}}
end

function ApproxDelaunayGraph()
    return ApproxDelaunayGraph(Dict{T,Int}(), Vector{Vector{Int}}())
end
function ApproxDelaunayGraph(vtx::T) where {T}
    return ApproxDelaunayGraph(Dict{T,Int}(vtx=>1), [Vector{Int}()])
end

Graphs.vertices(g::ApproxDelaunayGraph) = length(g.edges)

function Graphs.add_vertex!(g::ApproxDelaunayGraph{T},vtx::T) where {T}
    vtx ∈ keys(g.vtx_dict) && return false
    push!(g.edges, Vector{Int}())
    g.vtx_dict[vtx] = length(g.edges)
    return g.vtx_dict[vtx]
end

function Graphs.add_edge!(g::ApproxDelaunayGraph{T},s::T,d::T) where {T}
    s ∉ keys(g.vtx_dict) && return false
    d ∉ keys(g.vtx_dict) && return false
    push!(g.edges[g.vtx_dict[s]], g.vtx_dict[d])
    push!(g.edges[g.vtx_dict[d]], g.vtx_dict[s])
    return true
end

function Graphs.neighbors(g::ApproxDelaunayGraph{T},vtx::T) where {T}
    vtx ∉ keys(g.vtx_dict) && return Vector{Int}()
    return g.edges[g.vtx_dict[vtx]]
end

function remove_edge!(g::ApproxDelaunayGraph{T},s::T,d::T) where {T}
    s ∉ keys(g.vtx_dict) && return false
    d ∉ keys(g.vtx_dict) && return false
    deleteat!(g.edges[g.vtx_dict[s]], findfirst(g.edges[g.vtx_dict[s]], g.vtx_dict[d]))
    deleteat!(g.edges[g.vtx_dict[d]], findfirst(g.edges[g.vtx_dict[d]], g.vtx_dict[s]))
    return true
end