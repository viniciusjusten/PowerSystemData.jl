Base.@kwdef mutable struct Load
    name::String = ""
    bus_idx::Int = 0
    active_power::Float64 = 0.0 # p.u., constant-power for the static power flow
    reactive_power::Float64 = 0.0 # p.u.
end

function add_load!(input; kwargs...)
    push!(input.static.loads, Load(; kwargs...))
    return nothing
end

load_name(input, idx::Int) = input.static.loads[idx].name
load_bus_idx(input, idx::Int) = input.static.loads[idx].bus_idx
load_active_power(input, idx::Int) = input.static.loads[idx].active_power
load_reactive_power(input, idx::Int) = input.static.loads[idx].reactive_power

num_loads(input) = length(input.static.loads)
