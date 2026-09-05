Base.@kwdef mutable struct SystemBase
    frequency::Float64 = 60.0 # Hz, system nominal frequency
    power::Float64 = 100.0 # MVA, system base power for the p.u. quantities
end

set_base_frequency!(input, frequency::Float64) = (input.base.frequency = frequency; nothing)
set_base_power!(input, power::Float64) = (input.base.power = power; nothing)

base_frequency(input) = input.base.frequency
base_power(input) = input.base.power
