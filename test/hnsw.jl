using Test, TinyHNSW, TinyHNSW.Distances, TinyHNSW.Graphs, TinyHNSW.Random

using TinyHNSW: assignl, enterpoint

@testset "Constructor" begin
    M = 3
    M_max = 6 
    mL = 1/log(M)
    method = NaiveHeurestic()
    metric = Euclidean()
    efConstruction = 100
    data = [(1.0, 2.0)]
    hnsw = HNSW(data, M, M_max, efConstruction, mL, method, metric)

    @test hnsw.data == data

    ep = enterpoint(hnsw)

    @test ep == 1

    new_data = (1.0, 1.0)
    insert!(hnsw, new_data, method)
    @test hnsw.data == vcat(data[1],new_data)
    @test collect(edges(hnsw.graphs[1])) == [Edge(1 => 2)]
end

@testset "search layer" begin
    dist = Euclidean()
    ep = 1 # entry point
    ef = 3 # return closest 3 neighbors
    q = (0.0, 0.0)
    data = [
        (1.0, 2.0),
        (1.0, 1.0),
        (2.0, 1.0),
        (1.0, 0.0),
        (-1.0, 1.0),
        (-2.0, 0.0),
        (-2.0, -1.0),
        (-2.0, -2.0),
        (-1.0, -2.0),
        (1.0, -2.0),
        (2.0, -2.0),
    ]
    edge_vec =
        Edge.([
            (1 => 2),
            (1 => 3),
            (1 => 5),
            (2 => 3),
            (2 => 4),
            (2 => 5),
            (3 => 4),
            (3 => 11),
            (4 => 5),
            (4 => 6),
            (4 => 7),
            (4 => 9),
            (4 => 10),
            (4 => 11),
            (5 => 6),
            (5 => 7),
            (6 => 7),
            (7 => 8),
            (7 => 9),
            (8 => 9),
            (9 => 10),
            (10 => 11),
        ])
    g = SimpleGraphFromIterator(edge_vec)

    true_ans = [2, 4, 5]

    ans= search_layer(g, data, q, ep, ef, dist)
    @test true_ans == sort(ans)
end

@testset "select neighbors" begin
    dist = Euclidean()
    method = NaiveHeurestic()
    M = 5 # number of neighbors to return 
    target = (0.0, 0.0)
    db_sorted = [
        (0.0, 0.0),
        (1.0, 1.0),
        (2.0, 2.0),
        (3.0, 3.0),
        (4.0, 4.0),
        (5.0, 5.0),
        (6.0, 6.0),
        (7.0, 7.0),
        (8.0, 8.0),
        (9.0, 9.0),
    ]
    db_permuted = shuffle(db_sorted)

    selected_neighbors = select_neighbors(
        method, db_permuted, dist, target, 1:length(db_sorted), M
    )
    @test db_permuted[selected_neighbors] == db_sorted[1:M]

    M = 100 # number of neighbors to return 
    selected_neighbors = select_neighbors(
        method, db_permuted, dist, target, 1:(length(db_sorted)), M
    )
    @test db_permuted[selected_neighbors] == db_sorted[1:length(db_sorted)]
end


@testset "Utils" begin
    @test assignl(0) == 1
    levels = [assignl(0.33) for _ in 1:2^20]
    nis = [count(==(i), levels) for i in 1:8]

    ratios = [nis[i] / nis[i+1] for i in 1:7] # how to test this?
end