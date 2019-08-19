import MathOptInterface
const MOI = MathOptInterface

"""
    solve_time(model::Model)
If available, returns the solve time reported by the solver.
Returns "ArgumentError: ModelLike of type `Solver.Optimizer` does not support accessing
the attribute MathOptInterface.SolveTime()" if the attribute is
not implemented.
"""
function solve_time(model::Model)
    return MOI.get(model, MOI.SolveTime())
end

"""
    set_silent(model::Model)
Takes precedence over any other attribute controlling verbosity 
and requires the solver to produce no output.
"""
function set_silent(model::Model)
    return MOI.set(model, MOI.Silent(), true)
end