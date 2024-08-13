struct HNSW{T}
    data::Vector{T}
    M::Int
    mL::Float64
    graphs::Vector{}
    distance::Metric
end


function insert!(hnsw::HNSW{T}, item::T) where T
end

function search_layer()
end

function select_neighbors()
end

function select_neighbors_2() end

function knn_search()
end