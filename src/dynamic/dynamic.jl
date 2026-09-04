Base.@kwdef mutable struct Dynamic
    generators::Vector{DynamicGenerator} = DynamicGenerator[]
    loads::Vector{DynamicLoad} = DynamicLoad[]
    perturbations::Vector{Perturbation} = Perturbation[]
end
