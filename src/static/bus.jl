@enumx BusType begin
    PQ = 0
    PV = 1
    Slack = 2
end

Base.@kwdef mutable struct Bus
    name::String = ""
    type::BusType.T = BusType.PQ
    voltage::Float64 = 1.0 # p.u., magnitude, operating point
    voltage_angle::Float64 = 0.0 # rad, operating point
    shunt_susceptance::Float64 = 0.0 # p.u.
    min_voltage::Float64 = 0.0 # p.u.
    max_voltage::Float64 = Inf # p.u.
end

function add_bus!(input; kwargs...)
    push!(input.static.buses, Bus(; kwargs...))
    return nothing
end

bus_name(input, idx::Int) = input.static.buses[idx].name
bus_type(input, idx::Int) = input.static.buses[idx].type
bus_voltage(input, idx::Int) = input.static.buses[idx].voltage
bus_voltage_angle(input, idx::Int) = input.static.buses[idx].voltage_angle
bus_shunt_susceptance(input, idx::Int) = input.static.buses[idx].shunt_susceptance
bus_min_voltage(input, idx::Int) = input.static.buses[idx].min_voltage
bus_max_voltage(input, idx::Int) = input.static.buses[idx].max_voltage

num_buses(input) = length(input.static.buses)
