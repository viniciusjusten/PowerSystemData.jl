Base.@kwdef mutable struct Branch
    name::String = ""
    from_bus_idx::Int = 0
    to_bus_idx::Int = 0
    resistance::Float64 = 0.0 # p.u.
    reactance::Float64 = 0.0 # p.u.
    shunt_conductance::Float64 = 0.0 # p.u.
    shunt_susceptance::Float64 = 0.0 # p.u.
    tap_ratio::Float64 = 1.0
    min_tap_ratio::Float64 = tap_ratio
    max_tap_ratio::Float64 = tap_ratio
    phase_shift::Float64 = 0.0 # rad
    max_flow::Float64 = Inf # p.u.
    is_transformer::Bool = false
end

function add_branch!(input; kwargs...)
    push!(input.static.branches, Branch(; kwargs...))
    return nothing
end

branch_name(input, idx::Int) = input.static.branches[idx].name
branch_from_bus_idx(input, idx::Int) = input.static.branches[idx].from_bus_idx
branch_to_bus_idx(input, idx::Int) = input.static.branches[idx].to_bus_idx
branch_resistance(input, idx::Int) = input.static.branches[idx].resistance
branch_reactance(input, idx::Int) = input.static.branches[idx].reactance
branch_shunt_conductance(input, idx::Int) = input.static.branches[idx].shunt_conductance
branch_shunt_susceptance(input, idx::Int) = input.static.branches[idx].shunt_susceptance
branch_tap_ratio(input, idx::Int) = input.static.branches[idx].tap_ratio
branch_min_tap_ratio(input, idx::Int) = input.static.branches[idx].min_tap_ratio
branch_max_tap_ratio(input, idx::Int) = input.static.branches[idx].max_tap_ratio
branch_phase_shift(input, idx::Int) = input.static.branches[idx].phase_shift
branch_max_flow(input, idx::Int) = input.static.branches[idx].max_flow
branch_is_transformer(input, idx::Int) = input.static.branches[idx].is_transformer

num_branches(input) = length(input.static.branches)
