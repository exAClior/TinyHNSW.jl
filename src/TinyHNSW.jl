module TinyHNSW

using Distances, Graphs
using Random

export NaiveHeurestic, NNHeurestic, HNSW, insert!

include("hnsw.jl")
# include("graph.jl")

end
