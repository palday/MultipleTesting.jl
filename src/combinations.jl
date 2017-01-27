### Combination methods for p-values ###


## Fisher combination ##

immutable FisherCombination <: PValueCombinationMethod
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::FisherCombination)
    fisher_combination(pValues)
end

function fisher_combination{T<:AbstractFloat}(pValues::Vector{T})
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    if minimum(pValues) == 0.0
        return NaN
    end
    x = -2 * sum(log(pValues)) # p = 0 => Inf
    p = ccdf(Chisq(2k), x)
    return p
end


## Logit combination ##

immutable LogitCombination <: PValueCombinationMethod
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::LogitCombination)
    logit_combination(pValues)
end

function logit_combination{T<:AbstractFloat}(pValues::Vector{T})
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    pmin, pmax = extrema(pValues)
    if pmin == 0.0 || pmax == 1.0
        return NaN
    end
    c = sqrt( (5k+2)*k*pi^2 / ((5k+4)*3) )
    x = -sum(log(pValues./(1-pValues))) / c
    p = ccdf(TDist(5k+4), x)
    return p
end


## Stouffer combination ##

immutable StoufferCombination <: PValueCombinationMethod
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::StoufferCombination)
    stouffer_combination(pValues)
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, weights::Vector{T}, method::StoufferCombination)
    stouffer_combination(pValues, weights)
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, weights::WeightVec, method::StoufferCombination)
    stouffer_combination(pValues, values(weights))
end

function stouffer_combination{T<:AbstractFloat}(pValues::Vector{T})
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    pmin, pmax = extrema(pValues)
    if pmin == 0.0 || pmax == 1.0
        return NaN
    end
    z = cquantile(Normal(), pValues)
    z = sum(z) ./ sqrt(k)
    p = ccdf(Normal(), z)
    return p
end

function stouffer_combination{T<:AbstractFloat}(pValues::Vector{T}, weights::Vector{T})
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    pmin, pmax = extrema(pValues)
    if pmin == 0.0 || pmax == 1.0
        return NaN
    end
    z = cquantile(Normal(), pValues) .* weights
    z = sum(z) ./ sqrt(sum(weights.^2))
    p = ccdf(Normal(), z)
    return p
end


## Tippett combination ##

immutable TippettCombination <: PValueCombinationMethod
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::TippettCombination)
    tippett_combination(pValues)
end

function tippett_combination{T<:AbstractFloat}(pValues::Vector{T})
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    p = 1.0 - (1.0 - minimum(pValues))^k
    return p
end


## Wilkinson combination ##

immutable WilkinsonCombination <: PValueCombinationMethod
    rank::Int

    function WilkinsonCombination(rank)
        if rank < 1
            throw(ArgumentError("Rank must be positive."))
        end
        return new(rank)
    end
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::WilkinsonCombination)
    wilkinson_combination(pValues, method.rank)
end

function wilkinson_combination{T<:AbstractFloat}(pValues::Vector{T}, rank::Int)
    validPValues(pValues)
    k = length(pValues)
    if rank < 1 || rank > k
        throw(ArgumentError("Rank must be in 1,..,$(k)"))
    end
    if k == 1
        return pValues[1]
    end
    p_rank = sort(pValues)[rank]
    p = cdf(Beta(rank, k-rank+1), p_rank)
    return p
end


## Generalised minimum combination ##

immutable MinimumCombination <: PValueCombinationMethod
    method::PValueAdjustmentMethod
end

function combine{T<:AbstractFloat}(pValues::Vector{T}, method::MinimumCombination)
    minimum_combination(pValues, method.method)
end

function minimum_combination{T<:AbstractFloat}(pValues::Vector{T}, pAdjustMethod::PValueAdjustmentMethod)
    validPValues(pValues)
    k = length(pValues)
    if k == 1
        return pValues[1]
    end
    padj = adjust(pValues, pAdjustMethod)
    p = minimum(padj)
    return p
end
