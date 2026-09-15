Base.@kwdef mutable struct Static
    buses::Vector{Bus} = Bus[]
    branches::Vector{Branch} = Branch[]
    generators::Vector{Generator} = Generator[]
    loads::Vector{Load} = Load[]
    dclines::Vector{DCLine} = DCLine[]
end
