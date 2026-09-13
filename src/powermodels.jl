function _powermodels_bus_type(pm_type::Int)
    if pm_type == 2
        return BusType.PV
    elseif pm_type == 3
        return BusType.Slack
    else
        return BusType.PQ
    end
end

function _powermodels_generator_cost(gen::AbstractDict, base_power::Float64)
    # Only the linear term of a polynomial cost curve is kept, since Generator
    # has a single $/MWh field; the curve is stored per unit of base_power in
    # the PowerModels dict, so it is rescaled back to real $/MWh here.
    if Int(get(gen, "model", 2)) != 2
        return 0.0
    end
    coeffs = get(gen, "cost", Float64[])
    if length(coeffs) < 2
        return 0.0
    end
    return coeffs[end-1] / base_power
end

"""
    from_powermodels(data::AbstractDict) -> Input

Convert a PowerModels network data dictionary (as returned by
`PowerModels.parse_file`, with `data["per_unit"] == true`) into an `Input`.
Only the static `bus`, `branch`, `gen`, `load`, and `shunt` components are
translated; other components (storage, switches, DC lines, ...) are ignored.
"""
function from_powermodels(data::AbstractDict)
    if !get(data, "per_unit", true)
        error(
            "from_powermodels expects a per-unit PowerModels dict (call PowerModels.make_per_unit!(data) first)",
        )
    end

    base_power = Float64(data["baseMVA"])
    input = Input(; base = SystemBase(; power = base_power))

    bus_idx = Dict{Int,Int}()
    for bus in sort(collect(values(data["bus"])); by = b -> b["index"])
        bus_i = Int(bus["bus_i"])
        add_bus!(
            input;
            name = string(get(bus, "name", "Bus $bus_i")),
            type = _powermodels_bus_type(Int(bus["bus_type"])),
            voltage = Float64(bus["vm"]),
            voltage_angle = Float64(bus["va"]),
            shunt_susceptance = Float64(get(bus, "bs", 0.0)),
            min_voltage = Float64(get(bus, "vmin", 0.8)),
            max_voltage = Float64(get(bus, "vmax", 1.2)),
        )
        bus_idx[bus_i] = num_buses(input)
    end

    for shunt in values(get(data, "shunt", Dict{String,Any}()))
        if Int(get(shunt, "status", 1)) == 0
            continue
        end
        bus = input.static.buses[bus_idx[Int(shunt["shunt_bus"])]]
        bus.shunt_susceptance += Float64(get(shunt, "bs", 0.0))
    end

    for branch in sort(collect(values(data["branch"])); by = b -> b["index"])
        if Int(get(branch, "br_status", 1)) == 0
            continue
        end
        tap = Float64(get(branch, "tap", 1.0))
        if tap == 0.0
            tap = 1.0
        end
        # rate_a == 0 is the Matpower convention for "unlimited"; both that
        # and a missing key fall back to the 999.9 MVA sentinel.
        max_flow = 999.9
        if haskey(branch, "rate_a") && branch["rate_a"] > 0
            max_flow = Float64(branch["rate_a"]) * base_power
        end
        add_branch!(
            input;
            name = string(get(branch, "name", "Branch $(branch["index"])")),
            from_bus_idx = bus_idx[Int(branch["f_bus"])],
            to_bus_idx = bus_idx[Int(branch["t_bus"])],
            resistance = Float64(branch["br_r"]),
            reactance = Float64(branch["br_x"]),
            shunt_conductance = Float64(get(branch, "g_fr", 0.0)),
            shunt_susceptance = Float64(get(branch, "b_fr", 0.0)),
            tap_ratio = tap,
            phase_shift = Float64(get(branch, "shift", 0.0)),
            max_flow = max_flow,
            is_transformer = Bool(get(branch, "transformer", false)),
        )
    end

    for gen in sort(collect(values(data["gen"])); by = g -> g["index"])
        if Int(get(gen, "gen_status", 1)) == 0
            continue
        end
        add_generator!(
            input;
            name = string(get(gen, "name", "Gen $(gen["index"])")),
            bus_idx = bus_idx[Int(gen["gen_bus"])],
            active_power = Float64(get(gen, "pg", 0.0)),
            reactive_power = Float64(get(gen, "qg", 0.0)),
            voltage_setpoint = Float64(get(gen, "vg", 1.0)),
            min_active_power = Float64(get(gen, "pmin", 0.0)),
            max_active_power = Float64(get(gen, "pmax", 999.9)),
            min_reactive_power = Float64(get(gen, "qmin", -999.9)),
            max_reactive_power = Float64(get(gen, "qmax", 999.9)),
            cost = _powermodels_generator_cost(gen, base_power),
        )
    end

    for load in sort(collect(values(data["load"])); by = l -> l["index"])
        if Int(get(load, "status", 1)) == 0
            continue
        end
        add_load!(
            input;
            name = string(get(load, "name", "Load $(load["index"])")),
            bus_idx = bus_idx[Int(load["load_bus"])],
            active_power = Float64(get(load, "pd", 0.0)),
            reactive_power = Float64(get(load, "qd", 0.0)),
        )
    end

    return input
end
