using Pkg

Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()

using BenchmarkTools

using GenomicFeatures

include(joinpath(dirname(@__FILE__), "..", "utils", "RandUtils.jl"))

# Define a parent BenchmarkGroup to contain our suite.
const suite = BenchmarkGroup()

# Add some child groups to our benchmark suite.
suite["collection"] = BenchmarkGroup()
suite["collection"]["eachoverlap"] = BenchmarkGroup()

# n = 1000
# n = 10000
n = 100000
Random.seed!(1234)

# The following intervals will be the same every time because we're seeding the RNG.
intervals_a = random_intervals(["one", "two", "three"], 1000000, n)
intervals_b = random_intervals(["one", "two", "three"], 1000000, n)

for intervals in (intervals_a, intervals_b)
    sort!(intervals)
end

suite["collection"]["eachoverlap"][string(typeof(intervals_a)),string(typeof(intervals_b))] = @benchmarkable $collect(GenomicFeatures.eachoverlap($intervals_a, $intervals_b))

# If a cache of tuned parameters already exists, use it, otherwise, tune and cache the benchmark parameters.
# Reusing cached parameters is faster and more reliable than re-tuning `suite` every time the file is included.
paramspath = joinpath(dirname(@__FILE__), "params.json")

if isfile(paramspath)
    loadparams!(suite, BenchmarkTools.load(paramspath)[1], :evals);
else
    tune!(suite)
    BenchmarkTools.save(paramspath, BenchmarkTools.params(suite)); #TODO: make RandUtils a module to hide Distributions.params.
end

results = run(suite, verbose = true)

@info "results"
for (name, result) in results["collection"]["eachoverlap"]
    print(name, " ")
    display(result)
    println()
end
