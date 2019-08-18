# Code vendored from release 0.1.0 of https://github.com/rdeits/ConditionalJuMP.jl
# This allows us to upgrade just the relevant parts to be compatible with JuMP >= 0.19

using JuMP
using JuMP: GenericAffExpr, Variable
using IntervalArithmetic: Interval

"""
Simplification function that chooses the appropriate algorithm based on the number
of variables.
"""
function simplify!(e::JuMP.GenericAffExpr{T, Variable}) where T
    n = length(e.vars)
    ((n < 100) ? simplify_inplace! : simplify_dict!)(e)
end

"""
Naive O(N^2) simplification. Slower for very large expressions, but allocates
no memory and is solidly faster for expressions with < 100 variables.
"""
function simplify_inplace!(e::JuMP.GenericAffExpr{T, Variable}) where T
    i1 = 1
    iend = length(e.vars)
    while i1 < iend
        i2 = i1 + 1
        while i2 <= iend
            if e.vars[i1].col == e.vars[i2].col
                e.coeffs[i1] += e.coeffs[i2]
                e.vars[i2] = e.vars[iend]
                e.coeffs[i2] = e.coeffs[iend]
                iend -= 1
            else
                i2 += 1
            end
        end
        i1 += 1
    end
    resize!(e.vars, iend)
    resize!(e.coeffs, iend)
    if iszero(e.constant)
        # Ensure that we always use the canonical (e.g. positive) zero
        e.constant = zero(e.constant)
    end
    e
end

"""
O(N) simplification, but with a substantially larger constant cost due to the
need to construct a Dict.
"""
function simplify_dict!(e::JuMP.GenericAffExpr{T, Variable}) where T
    vars = Variable[]
    coeffs = T[]

    var_map = Dict{Int, Int}()
    for i in eachindex(e.vars)
        v, c = e.vars[i], e.coeffs[i]
        idx = v.col
        if c != 0
            if haskey(var_map, idx)
                coeffs[var_map[idx]] += c
            else
                push!(vars, v)
                push!(coeffs, c)
                var_map[idx] = length(vars)
            end
        end
    end
    constant = e.constant
    if iszero(constant)
        constant = zero(constant)
    end
    e.vars = vars
    e.coeffs = coeffs
    e.constant = constant
    AffExpr(vars, coeffs, constant)
end

getmodel(x::JuMP.Variable) = x.m
getmodel(x::JuMP.GenericAffExpr) = first(x.vars).m

lowerbound(x::Number) = x
upperbound(x::Number) = x
lowerbound(x::Variable) = JuMP.getlowerbound(x)
upperbound(x::Variable) = JuMP.getupperbound(x)

interval(x::Number, simplify=true) = Interval(x, x)
interval(x::Variable, simplify=true) = Interval(JuMP.getlowerbound(x), JuMP.getupperbound(x))

function interval(e::JuMP.GenericAffExpr, needs_simplification=true)
    if needs_simplification
        simplify!(e)
    end
    if isempty(e.coeffs)
        return Interval(e.constant, e.constant)
    else
        result = Interval(e.constant, e.constant)
        for i in eachindex(e.coeffs)
            var = e.vars[i]
            coef = e.coeffs[i]
            result += Interval(coef, coef) * Interval(getlowerbound(var), getupperbound(var))
        end
        return result
    end
end

upperbound(e::GenericAffExpr, simplify=true) = upperbound(interval(e, simplify))
lowerbound(e::GenericAffExpr, simplify=true) = lowerbound(interval(e, simplify))
lowerbound(i::Interval) = i.lo
upperbound(i::Interval) = i.hi