abstract type DynamicGenerator end

Base.@kwdef mutable struct ClassicGenerator <: DynamicGenerator
    generator_idx::Int = 0 # links to Static.generators
    inertia_constant::Float64 = 0.0 # H, s
    damping_coefficient::Float64 = 0.0
    transient_reactance::Float64 = 0.0 # x'd, p.u.
end

add_dynamic_generator!(input, generator::DynamicGenerator) = push!(input.dynamic.generators, generator)

classic_generator_generator_idx(input, idx::Int) = input.dynamic.generators[idx].generator_idx
classic_generator_inertia_constant(input, idx::Int) = input.dynamic.generators[idx].inertia_constant
classic_generator_damping_coefficient(input, idx::Int) = input.dynamic.generators[idx].damping_coefficient
classic_generator_transient_reactance(input, idx::Int) = input.dynamic.generators[idx].transient_reactance

num_dynamic_generators(input) = length(input.dynamic.generators)
