abstract type SelectMethod end

struct NaiveHeurestic <: SelectMethod end

struct NNHeurestic <: SelectMethod 
    extendCandidate::Bool
    keepCandidate::Bool
end

struct HNSW{T,VG<:AbstractVector{<:Graphs.AbstractSimpleGraph},F<:Real}
    data::Vector{T}
    M::Int # numbers of neighbors to consider 
    M_max::Int # maximum number of neighbors
    mL::F
    efConstruction::Int
    graphs::VG # lower level at smaller index
    method::SelectMethod
    distance::Metric
end

function HNSW(
    data::Vector{T},
    M::Int,
    M_max::Int,
    efConstruction::Int,
    mL::Float64,
    method::SelectMethod,
    distance::Metric,
) where {T}
    graphs = [ApproxDelaunayGraph(1) for _ in 1:assignl(mL)]
    hnsw = HNSW([data[1]], M, M_max, mL, efConstruction, graphs, method, distance)
    for pt in view(data,2:length(data))
        insert!(hnsw, pt, hnsw.method)
    end
    return hnsw
end

# assigned highest level to a new point
assignl(mL::F) where {F<:Real} = Int(floor(-log(rand()) * mL)) + 1

# gets the first point in the highest level graph
enterpoint(hnsw::HNSW) = vertices(hnsw.graphs[end])[1]

function Base.insert!(hnsw::HNSW{T,G,F}, q::T, method::SelectMethod) where {T,G,F}
    new_idx = length(hnsw.data) + 1 # index of new point in graphs
    W = T[]
    ep = enterpoint(hnsw)
    l = assignl(hnsw.mL) 

    for _ in length(hnsw.graphs):l
        push!(hnsw.graphs, ApproxDelaunayGraph(new_idx))
    end

    L = length(hnsw.graphs)

    # get enterpoint on the highest level q appears
    for lc in L:-1:l+1
        W = search_layer(hnsw.graphs[lc], hnsw.data, q, ep, hnsw.efConstruction, hnsw.distance)
        ep = W[findmin([(hnsw.distance(q, hnsw.data[w]), w) for w in W])[2]]
    end

    for lc in l:-1:1
        W = search_layer(hnsw.graphs[lc], hnsw.data, q, ep, hnsw.efConstruction, hnsw.distance)
        qneighbors = select_neighbors(method, hnsw.data, hnsw.distance, q, W, hnsw.M)
        add_vertex!(hnsw.graphs[lc],new_idx)
        for n in qneighbors
            add_edge!(hnsw.graphs[lc], n, new_idx)
        end
        for e in qneighbors
            eneighbors = neighbors(hnsw.graphs[lc], e)  

            if length(eneighbors) > (lc == 1 ? typemax(Int) : hnsw.M_max)
                eNewConn = select_neighbors(
                    method,hnsw.distance, hnsw.data, eneighbors, hnsw.M_max, hnsw.M_max
                )
                for en in eneighbors
                    if en ∉ eNewConn
                        remove_edge!(hnsw.graphs[lc], e, en)
                    end
                end
            end
        end
    end

    # ep = W # what is the point?

    push!(hnsw.data, q)
    return hnsw
end

function search_layer(
    g::G, data::AbstractVector{T}, q::T, ep::P, ef::Int, dist::Metric
) where {G,P,T}
    visited = [ep] # vector of graph nodes
    candidate = [ep]
    nearest_neighbors = [ep]
    while length(candidate) > 0
        c_dist, c_idx = findmin([dist(q, data[c]) for c in candidate])
        f_dist, f_idx = findmax([dist(q, data[c]) for c in candidate])

        c_dist > f_dist && break

        for e in neighbors(g, candidate[c_idx])

            e ∈ visited && continue

            union!(visited, e)
            f_dist, f_idx = findmax([dist(q, data[c]) for c in nearest_neighbors])

            dist(q, data[e]) >= f_dist && length(nearest_neighbors) >= ef && continue

            union!(nearest_neighbors, e)
            union!(candidate, e)

            length(candidate) <= ef && continue

            f_idx = findmax([dist(q, data[c]) for c in candidate])[2]
            deleteat!(nearest_neighbors, f_idx)
        end
        deleteat!(candidate, c_idx)
    end
    return nearest_neighbors
end


"""
    select_neighbors(heuristic, dist, q, C, M)

Selects the M nearest neighbors from the given set of candidates C based on the distance metric dist and query point q using the NaiveHeuristic.

# Arguments
- `heuristic::NaiveHeuristic`: The heuristic to use for neighbor selection.
- `dist::Metric`: The distance metric to use for calculating distances between points.
- `q::T`: The query point.
- `C::AbstractVector{T}`: The set of candidate points.
- `M::Int`: The number of nearest neighbors to select.

# Returns
An array of indices representing the M nearest neighbors from the candidate set C.
"""
function select_neighbors(
    ::NaiveHeurestic,
    data::AbstractVector{T},
    dist::Metric,
    q::T,
    C::AbstractVector{P},
    M::Int,
) where {T,P}
    return sort(C; by=x -> dist(q, data[x]))[1:min(M,length(C))]
end

function select_neighbors(
    method::NNHeurestic, q::T, C::AbstractVector{T}, M::Int, g::G
) where {G,T} error("Unimplemented yet") end

function knn_search(hnsw::HNSW, q::T, K::Int, ef::Int) where {T}
    W = T[]
    ep = enterpoint(hnsw)
    L = length(hnsw.graphs)
    for lc in L:-1:1
        W = search_layer(hnsw.graphs[lc], hnsw.data, q, ep, 1, hnsw.distance)
        ep = findmin([(hnsw.distance(q, hnsw.data[w]), w) for w in W])[2]
    end
    W = search_layer(hnsw.graphs[1], hnsw.data, q, ep, ef, hnsw.distance)
    return sort(W; by=x -> hnsw.distance(q, hnsw.data[x]))[1:min(K, length(W))]
end