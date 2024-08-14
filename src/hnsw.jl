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
    graphs = [SimpleGraph{Int}(1) for _ in 1:assignl(mL)]
    hnsw = HNSW([data[1]], M, M_max, mL, efConstruction, graphs, method, distance)
    for pt in view(data,2:length(data))
        insert!(hnsw, pt, hnsw.method)
    end
    return hnsw
end

assignl(mL::F) where {F<:Real} = Int(floor(-log(rand()) * mL)) + 1

enterpoint(hnsw::HNSW) = vertices(hnsw.graphs[end])[1]

function Base.insert!(hnsw::HNSW{T,G,F}, q::T, method::SelectMethod) where {T,G,F}
    new_idx = length(hnsw.data) + 1 # index of new point in graphs
    W = T[]
    ep = enterpoint(hnsw)
    l = assignl(hnsw.mL) 

    for _ in length(hnsw.graphs):l
        push!(hnsw.graphs, SimpleGraph{Int}(new_idx))
    end

    L = length(hnsw.graphs)

    for lc in L:-1:l+1
        W = search_layer(hnsw.graphs[lc], hnsw.data, q, ep, hnsw.efConstruction, hnsw.distance)
        ep = sort(W; by = x-> hnsw.distance(q, hnsw.data[x]))[2]
    end

    for lc in min(L,l):-1:1
        W = search_layer(hnsw[lc], hnsw.data, q, ep, hnsw.efConstruction, hnsw.distance)
        neighbors = select_neighbors(method, q, hnsw.data, W, hnsw.M)
        for n in neighbors
            add_edge!(hnsw.graphs[lc], n, new_idx)
        end
        for e in neighbors
            eneighbors = neighbors(hnsw.graphs[lc], e)  
            if length(eneighbors) > hnsw.M_max
                eNewConn = select_neighbors(method, hnsw.data, eneighbors, hnsw.M_max, hnsw.M_max)
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

function select_neighbors(method::NNHeurestic,q::T,C::Vector{P},M::Int,g::G) where{P,G,T} end

function knn_search(hnsw::HNSW, q::T, K::Int, ef::Int) where {T}
    W = T[]
    ep = enterpoint(hnsw)
    L = length(hnsw.graphs)
    for lc in L:-1:1
        W = search_layer(hnsw[lc], hnsw.data, q, ep, 1, hnsw.distance)
        ep = sort(W; by = x -> hnsw.distance(q, hnsw.data[x]))[1]
    end
    W = search_layer(hnsw[1], hnsw.data, q, ep, ef, hnsw.distance)
    return sort(W; by = x -> hnsw.distance(q, hnsw.data[x]))[1:K]
end