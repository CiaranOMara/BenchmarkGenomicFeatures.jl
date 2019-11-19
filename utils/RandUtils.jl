using Distributions
import Random

# Test that an array of intervals is well ordered
function is_all_ordered(intervals::Vector{I}) where I <: Interval
    for i = 2:length(intervals)
        if !GenomicFeatures.isordered(intervals[i-1], intervals[i])
            return false
        end
    end
    return true
end

# Generate an array of n random Interval{Int} object.
# With sequence names, samples from seqnames, and intervals drawn to lie in [1, maxpos].
function random_intervals(seqnames, maxpos::Int, n::Int)
    seq_dist = Categorical(length(seqnames))
    strand_dist = Categorical(2)
    length_dist = Normal(1000, 1000)
    intervals = Vector{Interval{Int}}(undef, n)
    for i in 1:n
        intlen = maxpos
        while intlen >= maxpos || intlen <= 0
            intlen = ceil(Int, rand(length_dist))
        end
        first = rand(1:maxpos-intlen)
        last = first + intlen - 1
        strand = rand(strand_dist) == 1 ? STRAND_POS : STRAND_NEG
        intervals[i] = Interval{Int}(seqnames[rand(seq_dist)], first, last, strand, i)
    end
    return intervals
end

function random_positions(seqnames, maxpos::Int, n::Int)
    seq_dist = Categorical(length(seqnames))
    postions = Vector{GenomicPosition{Int}}(undef, n)
    for i in 1:n
        first = rand(1:maxpos)
        postions[i] = GenomicPosition{Int}(seqnames[rand(seq_dist)], first, i)
    end
    return postions
end

function random_mix(seqnames, maxpos::Int, n::Int, mix::Float64)

    split = ceil(Int, n * mix)

    intervals = random_intervals(seqnames, maxpos, split)
    positions = random_positions(seqnames, maxpos, n - split)

    return [intervals; positions]
end

# A simple interval intersection implementation to test against.
function simple_intersection(intervals_a, intervals_b; filter=(a,b)->true)
    sort!(intervals_a)
    sort!(intervals_b)
    intersections = Any[]
    i = 1
    j = 1
    while i <= length(intervals_a) && j <= length(intervals_b)
        ai = intervals_a[i]
        bj = intervals_b[j]
        if isless(seqname(ai), seqname(bj)) || (seqname(ai) == seqname(bj) && rightposition(ai) < leftposition(bj))
            i += 1
        elseif isless(seqname(bj), seqname(ai)) || (seqname(ai) == seqname(bj) && rightposition(bj) < leftposition(ai))
            j += 1
        else
            k = j
            while k <= length(intervals_b) && leftposition(intervals_b[k]) <= rightposition(ai)
                if isoverlapping(ai, intervals_b[k]) && filter(ai, intervals_b[k])
                    push!(intersections, (ai, intervals_b[k]))
                end
                k += 1
            end
            i += 1
        end
    end
    return intersections
end

function simple_coverage(intervals)
    seqlens = Dict{String, Int}()
    for interval in intervals
        if get(seqlens, seqname(interval), -1) < rightposition(interval)
            seqlens[seqname(interval)] = rightposition(interval)
        end
    end

    covarrays = Dict{String, Vector{Int}}()
    for (seqname, seqlen) in seqlens
        covarrays[seqname] = zeros(Int, seqlen)
    end

    for interval in intervals
        arr = covarrays[seqname(interval)]
        for i in leftposition(interval):rightposition(interval)
            arr[i] += 1
        end
    end

    covintervals = Interval{UInt32}[]
    for (seqname, arr) in covarrays
        i = j = 1
        while i <= length(arr)
            if arr[i] > 0
                j = i + 1
                while j <= length(arr) && arr[j] == arr[i]
                    j += 1
                end
                push!(covintervals, Interval{UInt32}(seqname, i, j - 1, STRAND_BOTH, arr[i]))
                i = j
            else
                i += 1
            end
        end
    end

    return covintervals
end

# end
