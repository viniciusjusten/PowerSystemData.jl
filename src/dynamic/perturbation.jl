abstract type Perturbation end

Base.@kwdef mutable struct BusShortCircuit <: Perturbation
    bus_idx::Int = 0
    time::Float64 = 0.0 # s
    fault_resistance::Float64 = 0.0 # p.u.
    fault_reactance::Float64 = 0.0 # p.u.
    clearing_time::Float64 = Inf # s
end

Base.@kwdef mutable struct BranchTrip <: Perturbation
    branch_idx::Int = 0
    time::Float64 = 0.0 # s
end

Base.@kwdef mutable struct GeneratorTrip <: Perturbation
    generator_idx::Int = 0
    time::Float64 = 0.0 # s
end

add_perturbation!(input, perturbation::Perturbation) = push!(input.dynamic.perturbations, perturbation)

bus_short_circuit_bus_idx(input, idx::Int) = input.dynamic.perturbations[idx].bus_idx
bus_short_circuit_time(input, idx::Int) = input.dynamic.perturbations[idx].time
bus_short_circuit_fault_resistance(input, idx::Int) = input.dynamic.perturbations[idx].fault_resistance
bus_short_circuit_fault_reactance(input, idx::Int) = input.dynamic.perturbations[idx].fault_reactance
bus_short_circuit_clearing_time(input, idx::Int) = input.dynamic.perturbations[idx].clearing_time

branch_trip_branch_idx(input, idx::Int) = input.dynamic.perturbations[idx].branch_idx
branch_trip_time(input, idx::Int) = input.dynamic.perturbations[idx].time

generator_trip_generator_idx(input, idx::Int) = input.dynamic.perturbations[idx].generator_idx
generator_trip_time(input, idx::Int) = input.dynamic.perturbations[idx].time

num_perturbations(input) = length(input.dynamic.perturbations)
