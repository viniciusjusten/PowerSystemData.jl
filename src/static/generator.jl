Base.@kwdef mutable struct Generator
    name::String = ""
    bus_idx::Int = 0
    active_power::Float64 = 0.0 # p.u., scheduled output
    reactive_power::Float64 = 0.0 # p.u.
    voltage_setpoint::Float64 = 1.0 # p.u., used when bus is PV/Slack
    min_active_power::Float64 = 0.0 # p.u.
    max_active_power::Float64 = Inf # p.u.
    min_reactive_power::Float64 = -Inf # p.u.
    max_reactive_power::Float64 = Inf # p.u.
    cost::Float64 = 0.0 # $ per p.u. of active power (matches the p.u. convention used for Pg)
end

function add_generator!(input; kwargs...)
    push!(input.static.generators, Generator(; kwargs...))
    return nothing
end

generator_name(input, idx::Int) = input.static.generators[idx].name
generator_bus_idx(input, idx::Int) = input.static.generators[idx].bus_idx
generator_active_power(input, idx::Int) = input.static.generators[idx].active_power
generator_reactive_power(input, idx::Int) = input.static.generators[idx].reactive_power
generator_voltage_setpoint(input, idx::Int) = input.static.generators[idx].voltage_setpoint
generator_min_active_power(input, idx::Int) = input.static.generators[idx].min_active_power
generator_max_active_power(input, idx::Int) = input.static.generators[idx].max_active_power
generator_min_reactive_power(input, idx::Int) =
    input.static.generators[idx].min_reactive_power
generator_max_reactive_power(input, idx::Int) =
    input.static.generators[idx].max_reactive_power
generator_cost(input, idx::Int) = input.static.generators[idx].cost

num_generators(input) = length(input.static.generators)
