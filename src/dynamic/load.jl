abstract type DynamicLoad end

Base.@kwdef mutable struct ZConstantLoad <: DynamicLoad
    load_idx::Int = 0 # links to Static.loads
    conductance::Float64 = 0.0 # G, p.u.
    susceptance::Float64 = 0.0 # B, p.u.
end

add_dynamic_load!(input, load::DynamicLoad) = push!(input.dynamic.loads, load)

z_constant_load_load_idx(input, idx::Int) = input.dynamic.loads[idx].load_idx
z_constant_load_conductance(input, idx::Int) = input.dynamic.loads[idx].conductance
z_constant_load_susceptance(input, idx::Int) = input.dynamic.loads[idx].susceptance

num_dynamic_loads(input) = length(input.dynamic.loads)
