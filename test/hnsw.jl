using Test, TinyHNSW, TinyHNSW.Distances, TinyHNSW.Graphs

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

    insert!(hnsw, (2.0, 3.0), method)
end


@testset "Utils" begin
    @test assignl(0) == 1
    levels = [assignl(0.33) for _ in 1:2^20]
    nis = [count(==(i), levels) for i in 1:8]

    ratios = [nis[i] / nis[i+1] for i in 1:7] # how to test this?


end