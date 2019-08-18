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
    e
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