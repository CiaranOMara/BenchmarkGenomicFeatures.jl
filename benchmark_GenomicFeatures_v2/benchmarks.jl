using Pkg

Pkg.add(PackageSpec(url="https://github.com/BioJulia/GenomicFeatures.jl", rev="release/v2.0.0"))
Pkg.instantiate()

using BenchmarkTools

using GenomicFeatures

include("utils.jl")

# Define a parent BenchmarkGroup to contain our SUITE.
const SUITE = BenchmarkGroup()


# n = 1000
# n = 10000
n = 100000
Random.seed!(1234)

# The following intervals will be the same every time because we're seeding the RNG.
intervals_a = random_intervals(["one", "two", "three"], 1000000, n)
intervals_b = random_intervals(["one", "two", "three"], 1000000, n)

positions_a = random_positions(["one", "two", "three"], 1000000, n)
positions_b = random_positions(["one", "two", "three"], 1000000, n)

mixed_a = random_mix(["one", "two", "three"], 1000000, n, 0.5)
mixed_b = random_mix(["one", "two", "three"], 1000000, n, 0.5)

As = Any[
    intervals_a,
    positions_a,
    mixed_a
]

Bs = Any[
    intervals_b,
    positions_b
]
 #Note: not using mixed_b as the Queue is sensitive to parameter order.

intervals_a_iter = map(x -> (x, string(typeof(x))), As)
intervals_b_iter = map(x -> (x, string(typeof(x))), Bs)

# Add some benchmarks to the "intervals" group.
g = addgroup!(SUITE, "intervals", [])
for (A, str) in intervals_a_iter
    g["sort", str] = @benchmarkable sort($A)
    g["leftposition", str] = @benchmarkable leftposition.($A)
    g["rightposition", str] = @benchmarkable rightposition.($A)
    g["metadata", str] = @benchmarkable metadata.($A)
end

# Add some benchmarks to the "collection" group.
g = addgroup!(SUITE, "collection", [])
g = addgroup!(SUITE["collection"], "push", [])
for (A, str) in intervals_a_iter
    col = GenomicIntervalCollection{eltype(A)}()
    g["push", str] = @benchmarkable [push!($col, a) for a in $A]
end

# Add some benchmarks to the "bulk_insertion" group.
g = addgroup!(SUITE["collection"], "bulk_insertion", [])
for (A, str) in intervals_a_iter
    sort!(A)
    g["GenomicIntervalCollection", str] = @benchmarkable GenomicIntervalCollection($A)
    g["GenomicIntervalCollection{eltype(A)}", str] = @benchmarkable GenomicIntervalCollection{eltype($A)}($A)
end

# Add some benchmarks to the "eachoverlap" group.
g = addgroup!(SUITE["collection"], "eachoverlap", [])
for (A, str_A) in map(x -> (x, string(typeof(x))), (sort(intervals_a), GenomicIntervalCollection(intervals_a, true)))
    for (B, str_B) in map(x -> (x, string(typeof(x))), (sort(intervals_b), GenomicIntervalCollection(intervals_b, true)))
        g[str_A,str_B] = @benchmarkable $collect(GenomicFeatures.eachoverlap($A, $B))
    end
end

# for (A, str_A) in map(x -> (x, string(typeof(x))), (mixed_a, GenomicIntervalCollection(mixed_a, true)))
#     for (B, str_B) in map(x -> (x, string(typeof(x))), (mixed_b, GenomicIntervalCollection(mixed_b, true)))
#         g[str_A,str_B] = @benchmarkable $collect(GenomicFeatures.eachoverlap($A, $B))
#     end
# end


# If a cache of tuned parameters already exists, use it, otherwise, tune and cache the benchmark parameters.
# Reusing cached parameters is faster and more reliable than re-tuning `SUITE` every time the file is included.
paramspath = joinpath(dirname(@__FILE__), "params.json")

if isfile(paramspath)
    loadparams!(SUITE, BenchmarkTools.load(paramspath)[1], :evals);
else
    tune!(SUITE)
    BenchmarkTools.save(paramspath, BenchmarkTools.params(SUITE)); #TODO: make RandUtils a module to hide Distributions.params.
end

results = run(SUITE, verbose = true)

using BSON: @save, @load

# @save joinpath(dirname(@__FILE__), "results-$(now()).bson") results
@save joinpath(dirname(@__FILE__), "results.bson") results

@info "results"
display(results)
