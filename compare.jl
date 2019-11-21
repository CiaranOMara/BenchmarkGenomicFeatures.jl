using Pkg
Pkg.activate(dirname(@__FILE__))
Pkg.instantiate()

using BSON: @save, @load
using BenchmarkTools


function load(path)
	@load path results
	return results
end

results_v1 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v1", "results.bson"))
results_v2 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2", "results.bson"))

# Quick print outs of merged results.
@info "intervals"
for (name, result) in [results_v1["intervals"] |> collect; results_v2["intervals"] |> collect] |> (xs) -> sort(xs, by=first)
    print(name, " ")
    display(result)
    println()
end

@info "collection/push"
for (name, result) in [results_v1["collection"]["push"] |> collect; results_v2["collection"]["push"] |> collect] |> (xs) -> sort(xs, by=first)
    print(name, " ")
    display(result)
    println()
end

@info "collection/bulk_insertion"
for (name, result) in [results_v1["collection"]["bulk_insertion"] |> collect; results_v2["collection"]["bulk_insertion"] |> collect] |> (xs) -> sort(xs, by=first)
    print(name, " ")
    display(result)
    println()
end

@info "collection/eachoverlap"
for (name, result) in [results_v1["collection"]["eachoverlap"] |> collect; results_v2["collection"]["eachoverlap"] |> collect] |> (xs) -> sort(xs, by=first)
    print(name, " ")
    display(result)
    println()
end
