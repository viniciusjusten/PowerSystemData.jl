# based on MATPOWER's dcline data structure

Base.@kwdef mutable struct DCLine
    name::String = ""
    from_bus_idx::Int = 0
    to_bus_idx::Int = 0
    active_power::Float64 = 0.0 # p.u., flow scheduled to leave the from-bus terminal, before losses
    reactive_power_from::Float64 = 0.0 # p.u., scheduled reactive power injected at the from-bus terminal
    reactive_power_to::Float64 = 0.0 # p.u., scheduled reactive power injected at the to-bus terminal
    constant_loss::Float64 = 0.0 # p.u., constant term of the linear active power loss model
    loss_coefficient::Float64 = 0.0 # fraction of the from-bus flow lost in the line
    max_flow_from_to::Float64 = Inf # p.u., active power flow limit in the from -> to direction
    max_flow_to_from::Float64 = Inf # p.u., active power flow limit in the to -> from direction
    min_reactive_power_from::Float64 = -Inf # p.u.
    max_reactive_power_from::Float64 = Inf # p.u.
    min_reactive_power_to::Float64 = -Inf # p.u.
    max_reactive_power_to::Float64 = Inf # p.u.
end

function add_dcline!(input; kwargs...)
    push!(input.static.dclines, DCLine(; kwargs...))
    return nothing
end

dcline_name(input, idx::Int) = input.static.dclines[idx].name
dcline_from_bus_idx(input, idx::Int) = input.static.dclines[idx].from_bus_idx
dcline_to_bus_idx(input, idx::Int) = input.static.dclines[idx].to_bus_idx
dcline_active_power(input, idx::Int) = input.static.dclines[idx].active_power
dcline_reactive_power_from(input, idx::Int) = input.static.dclines[idx].reactive_power_from
dcline_reactive_power_to(input, idx::Int) = input.static.dclines[idx].reactive_power_to
dcline_constant_loss(input, idx::Int) = input.static.dclines[idx].constant_loss
dcline_loss_coefficient(input, idx::Int) = input.static.dclines[idx].loss_coefficient
dcline_max_flow_from_to(input, idx::Int) = input.static.dclines[idx].max_flow_from_to
dcline_max_flow_to_from(input, idx::Int) = input.static.dclines[idx].max_flow_to_from
dcline_min_reactive_power_from(input, idx::Int) =
    input.static.dclines[idx].min_reactive_power_from
dcline_max_reactive_power_from(input, idx::Int) =
    input.static.dclines[idx].max_reactive_power_from
dcline_min_reactive_power_to(input, idx::Int) = input.static.dclines[idx].min_reactive_power_to
dcline_max_reactive_power_to(input, idx::Int) = input.static.dclines[idx].max_reactive_power_to

num_dclines(input) = length(input.static.dclines)
