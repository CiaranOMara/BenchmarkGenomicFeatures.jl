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
for (name, result) in [results_v1["collection"]["eachoverlap"] |> collect; results_64336d55["collection"]["eachoverlap"] |> collect] |> (xs) -> sort(xs, by=first)
    print(name, " ")
    display(result)
    println()
end

@info "judgement"
results_0f5f14ab = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-0f5f14ab.bson")) # Remove deprecation warnings
results_09458d2e = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-09458d2e.bson")) # remove Remove superfluous types
results_06a7c47e = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-06a7c47e.bson")) # remove conversion
results_20e63fe6 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-20e63fe6.bson")) # Flatten compare_overlap
results_464ec2f5 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-464ec2f5.bson")) # Elucidate function return
results_5ff1da89 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-5ff1da89.bson")) # Flatten strand conversion
results_fb8e364a = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-fb8e364a.bson")) # Switch focus to eltype in overlap iterator
results_38ef699e = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-38ef699e.bson")) # Rename types so that Sa and Sb may be used for iterator states
results_1394d0cf = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-1394d0cf.bson")) # Condense OverlapIteratorState outer constructors
results_64336d55 = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-64336d55.bson")) # Use static types in subsequent OverlapIteratorState construction
results_71ae347b = load(joinpath(dirname(@__FILE__), "benchmark_GenomicFeatures_v2",  "results-71ae347b.bson")) # Work towards explicit conversion on OverlapIteratorState construction

descriptors = collect(leaves(results_v2)) |> (l) -> sort(l, by=first) .|> first

# Note newer is first parameter!

judgements = judge.(
	collect(leaves(results_fb8e364a)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_0f5f14ab)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.(
	collect(leaves(results_71ae347b)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_0f5f14ab)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)


judgements = judge.( # remove Remove superfluous types - regresses bulk insertion
	collect(leaves(results_09458d2e)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_0f5f14ab)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.( # remove conversion
	collect(leaves(results_06a7c47e)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_09458d2e)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.( # Flatten strand conversion
	collect(leaves(results_5ff1da89)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_464ec2f5)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.( # Switch focus to eltype in overlap iterator
	collect(leaves(results_fb8e364a)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_5ff1da89)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.( # Condense OverlapIteratorState outer constructors
	collect(leaves(results_1394d0cf)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_fb8e364a)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

judgements = judge.( # Use static types in subsequent OverlapIteratorState construction
	collect(leaves(results_64336d55)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_1394d0cf)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)


judgements = judge.( # Work towards explicit conversion on OverlapIteratorState construction
	collect(leaves(results_71ae347b)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_64336d55)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)


judgements = judge.( # Latest changes.
	collect(leaves(results_v2)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median,
	collect(leaves(results_71ae347b)) |> (l) -> sort(l, by=first) .|> last .|> BenchmarkTools.median
)

collect(zip(descriptors,judgements)) .|> (j) -> (display(j |> first); display(j |> last))
