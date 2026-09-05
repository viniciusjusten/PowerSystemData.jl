Base.@kwdef mutable struct Input
    base::SystemBase = SystemBase()
    static::Static = Static()
    dynamic::Dynamic = Dynamic()
end
