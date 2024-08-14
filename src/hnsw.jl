abstract type SelectMethod end

struct NaiveHeurestic <: SelectMethod end

struct NNHeurestic <: SelectMethod 
    extendCandidate::Bool
    keepCandidate::Bool
end

struct HNSW{T,G<:AbstractGraph,F<:Real}
    data::Vector{T}
    M::Int # numbers of neighbors to consider 
    M_max::Int # maximum number of neighbors
    mL::F
    efConstruction::Int
    graphs::Vector{G} # lower level at smaller index
    distance::Metric
end

function HNSW{T}(
    data::Vector{T}, M::Int, M_max::Int, mL::Float64, distance::Metric
) where {T}
    l_init = assignl(mL)
    graphs = [SimpleGraph{Int}(1) for l in l_init]
    hnsw = HNSW(data[1], M, M_max, mL, efConstruction, graphs, distance)
    for pt in data
        insert!(hnsw, pt)
    end
    return hnsw
end

assignl(mL::F) where {F<:Real} = floor(-log(rand()) * mL)

enterpoint(hnsw::HNSW) = vertices(hnsw.graphs[end])[1]

function insert!(hnsw::HNSW{T,G,F}, q::T) where {T,G,F}
    new_idx = length(hnsw.data) + 1 # index of new point in graphs
    W = T[]
    ep = enterpoint(hnsw)
    l = assignl(hnsw.mL) 

    for _ in length(hnsw.graphs):l
        push!(hnsw.graphs, SimpleGraph{Int}(new_idx))
    end

    L = length(hnsw.graphs)

    for lc in L:-1:l+1
        W = search_layer(hnsw[lc], hnsw.data, q, ep, hnsw.efConstruction, hnsw.distance)
    end

    push!(hnsw.data, q)
    return hnsw
end

function search_layer(g::G,data::AbstractVector{T}, q::T, ep::P, ef::Int,dist::Metric) where {G,P,T}
    visited = [ep] # vector of graph nodes
    candidate = [ep] 
    nearest_neighbors = [ep]
    while length(candidate) > 0
        c_dist, c_idx = findmin([dist(q, data[c]) for c in candidate])
        f_dist, f_idx = findmax([dist(q, data[c]) for c in candidate])

        c_dist > f_dist && break

        for e in neighbors(g,candidate[c_idx])
            if e ∉ visited
                union!(visited,e)
                f_dist, f_idx = findmax([dist(q, data[c]) for c in nearest_neighbors])
                if dist(q,data[e]) < f_dist || length(nearest_neighbors) < ef
                    union!(nearest_neighbors, e)
                    union!(candidate, e)
                    if length(candidate) > ef
                        f_idx = findmax([dist(q, data[c]) for c in candidate])[2]
                        pop!(candidate, f_idx)
                    end
                end
            end
        end
    end
    return nearest_neighbors
end

function select_neighbors(
    ::NaiveHeurestic, q::T, data::AbstractVector{T}, C::Vector{P}, M::Int
) where {T,P}
    return sort(C; by=x -> dist(q, data[x]))[1:M]
end

function select_neighbors(method::NNHeurestic,q::T,C::Vector{P},M::Int) end

function knn_search()
end