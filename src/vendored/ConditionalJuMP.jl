# Code vendored from release 0.1.0 of https://github.com/rdeits/ConditionalJuMP.jl
# This allows us to upgrade just the relevant parts to be compatible with JuMP >= 0.19

using JuMP
using IntervalArithmetic: Interval

getmodel(x::VariableRef) = x.model
getmodel(x::GenericAffExpr) = first(x.terms)[1].model

lowerbound(x::Number) = x
upperbound(x::Number) = x
lowerbound(x::VariableRef) = lower_bound(x)
upperbound(x::VariableRef) = upper_bound(x)

interval(x::Number) = Interval(x, x)
interval(x::VariableRef) = Interval(lower_bound(x), upper_bound(x))

function interval(e::GenericAffExpr)
    result = interval(e.constant)
    for t in e.terms
        var, coef = t
        result += interval(coef) * interval(var)
    end
    return result
end

upperbound(e::GenericAffExpr) = upperbound(interval(e))
lowerbound(e::GenericAffExpr) = lowerbound(interval(e))
lowerbound(i::Interval) = i.lo
upperbound(i::Interval) = i.hi