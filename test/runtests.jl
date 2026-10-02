using PowerSystemData
using LinearAlgebra
using Test

function build_test_system()
    input = PowerSystemData.Input()

    add_bus!(
        input;
        name = "Bus 1",
        type = BusType.Slack,
        voltage = 1.0,
        min_voltage = 0.9,
        max_voltage = 1.1,
    )
    add_bus!(
        input;
        name = "Bus 2",
        type = BusType.PQ,
        shunt_susceptance = 0.05,
        min_voltage = 0.9,
        max_voltage = 1.1,
    )
    add_branch!(
        input;
        name = "L1-2",
        from_bus_idx = 1,
        to_bus_idx = 2,
        resistance = 0.01,
        reactance = 0.1,
        max_flow = 100.0,
    )
    add_generator!(
        input;
        name = "G1",
        bus_idx = 1,
        active_power = 1.0,
        max_active_power = 2.0,
        cost = 20.0,
    )
    add_load!(input; name = "Load 2", bus_idx = 2, active_power = 0.8, reactive_power = 0.3)

    return input
end

@testset verbose = true "PowerSystemData" begin
    @testset "system base" begin
        input = build_test_system()

        @test base_frequency(input) == 60.0
        @test base_power(input) == 100.0

        set_base_frequency!(input, 50.0)
        set_base_power!(input, 1000.0)
        @test base_frequency(input) == 50.0
        @test base_power(input) == 1000.0

        european =
            PowerSystemData.Input(; base = SystemBase(; frequency = 50.0, power = 250.0))
        @test base_frequency(european) == 50.0
        @test base_power(european) == 250.0
    end

    @testset "static collections" begin
        input = build_test_system()

        @test num_buses(input) == 2
        @test num_branches(input) == 1
        @test num_generators(input) == 1
        @test num_loads(input) == 1

        @test bus_name(input, 1) == "Bus 1"
        @test bus_type(input, 1) == BusType.Slack
        @test bus_type(input, 2) == BusType.PQ

        @test branch_max_flow(input, 1) == 100.0
        @test generator_max_active_power(input, 1) == 2.0
        @test generator_cost(input, 1) == 20.0
        @test load_reactive_power(input, 1) == 0.3
    end

    @testset "dcline" begin
        input = build_test_system()
        add_dcline!(
            input;
            name = "DC1",
            from_bus_idx = 1,
            to_bus_idx = 2,
            active_power = 0.4,
            reactive_power_from = 0.05,
            reactive_power_to = -0.02,
            constant_loss = 0.01,
            loss_coefficient = 0.02,
            max_flow_from_to = 0.6,
            max_flow_to_from = 0.5,
            min_reactive_power_from = -0.2,
            max_reactive_power_from = 0.2,
            min_reactive_power_to = -0.2,
            max_reactive_power_to = 0.2,
        )

        @test num_dclines(input) == 1
        @test dcline_name(input, 1) == "DC1"
        @test dcline_from_bus_idx(input, 1) == 1
        @test dcline_to_bus_idx(input, 1) == 2
        @test dcline_active_power(input, 1) == 0.4
        @test dcline_reactive_power_from(input, 1) == 0.05
        @test dcline_reactive_power_to(input, 1) == -0.02
        @test dcline_constant_loss(input, 1) == 0.01
        @test dcline_loss_coefficient(input, 1) == 0.02
        @test dcline_max_flow_from_to(input, 1) == 0.6
        @test dcline_max_flow_to_from(input, 1) == 0.5
        @test dcline_min_reactive_power_from(input, 1) == -0.2
        @test dcline_max_reactive_power_from(input, 1) == 0.2
        @test dcline_min_reactive_power_to(input, 1) == -0.2
        @test dcline_max_reactive_power_to(input, 1) == 0.2
    end

    @testset "dynamic collections" begin
        input = build_test_system()

        add_dynamic_generator!(
            input,
            ClassicGenerator(;
                generator_idx = 1,
                inertia_constant = 5.0,
                damping_coefficient = 1.0,
                transient_reactance = 0.2,
            ),
        )
        add_dynamic_load!(
            input,
            ZConstantLoad(; load_idx = 1, conductance = 0.1, susceptance = 0.05),
        )
        add_perturbation!(
            input,
            BusShortCircuit(; bus_idx = 2, time = 1.0, clearing_time = 1.1),
        )
        add_perturbation!(input, BranchTrip(; branch_idx = 1, time = 2.0))
        add_perturbation!(input, GeneratorTrip(; generator_idx = 1, time = 3.0))

        @test num_dynamic_generators(input) == 1
        @test num_dynamic_loads(input) == 1
        @test num_perturbations(input) == 3

        @test classic_generator_inertia_constant(input, 1) == 5.0
        @test z_constant_load_conductance(input, 1) == 0.1
        @test bus_short_circuit_bus_idx(input, 1) == 2
        @test branch_trip_time(input, 2) == 2.0
        @test generator_trip_generator_idx(input, 3) == 1
    end

    @testset "ybus / zbus" begin
        input = build_test_system()

        Y = ybus(input)
        y_series = 1 / (0.01 + im * 0.1)
        expected = [y_series -y_series; -y_series y_series+im*0.05]
        @test Y ≈ expected atol = 1e-10

        Z = zbus(input)
        @test Z * Y ≈ Matrix{ComplexF64}(I, 2, 2) atol = 1e-8
    end

    @testset "ybus follows makeYbus for a tapped branch with a shunt" begin
        input = Input()
        add_bus!(input; name = "B1")
        add_bus!(input; name = "B2")
        add_branch!(
            input;
            name = "T12",
            from_bus_idx = 1,
            to_bus_idx = 2,
            resistance = 0.01,
            reactance = 0.1,
            shunt_susceptance = 0.03,
            tap_ratio = 1.05,
            phase_shift = 0.02,
            is_transformer = true,
        )

        # Matpower makeYbus.m, with tap = ratio * exp(im * shift):
        #   Ytt = Ys + im * Bc / 2   Yff = Ytt / (tap * conj(tap))
        #   Yft = -Ys / conj(tap)    Ytf = -Ys / tap
        y_series = 1 / (0.01 + im * 0.1)
        tap = 1.05 * exp(im * 0.02)
        Ytt = y_series + im * 0.03
        expected = [Ytt/(tap * conj(tap)) -y_series/conj(tap); -y_series/tap Ytt]

        @test ybus(input) ≈ expected atol = 1e-10
    end

    @testset "voltage / current / power helpers" begin
        input = build_test_system()
        Y = ybus(input)

        v = [1.0, 0.98]
        angle = [0.0, -0.02]

        V = voltage_phasor.(v, angle)
        @test real.(V) ≈ voltage_real.(v, angle)
        @test imag.(V) ≈ voltage_imag.(v, angle)

        I = current_injection(V, Y)
        @test real.(I) ≈ current_injection_real(v, angle, Y)
        @test imag.(I) ≈ current_injection_imag(v, angle, Y)

        S = power_injection(v, angle, Y)
        @test S ≈ V .* conj.(I)
    end

    @testset "from_powermodels" begin
        data = Dict{String,Any}(
            "per_unit" => true,
            "baseMVA" => 100.0,
            "bus" => Dict{String,Any}(
                "1" => Dict{String,Any}(
                    "index" => 1,
                    "bus_i" => 1,
                    "bus_type" => 3,
                    "vm" => 1.0,
                    "va" => 0.0,
                    "vmin" => 0.9,
                    "vmax" => 1.1,
                ),
                "2" => Dict{String,Any}(
                    "index" => 2,
                    "bus_i" => 2,
                    "bus_type" => 1,
                    "vm" => 1.0,
                    "va" => 0.0,
                    "bs" => 5.0,
                    "vmin" => 0.9,
                    "vmax" => 1.1,
                ),
            ),
            "branch" => Dict{String,Any}(
                "1" => Dict{String,Any}(
                    "index" => 1,
                    "f_bus" => 1,
                    "t_bus" => 2,
                    "br_r" => 0.01,
                    "br_x" => 0.1,
                    "rate_a" => 1.0,
                    "tap" => 1.02,
                    "transformer" => true,
                ),
            ),
            "dcline" => Dict{String,Any}(
                "1" => Dict{String,Any}(
                    "index" => 1,
                    "f_bus" => 1,
                    "t_bus" => 2,
                    "br_status" => 1,
                    "pf" => 0.3,
                    "pt" => -0.284,
                    "qf" => -0.05,
                    "qt" => 0.02,
                    "loss0" => 0.01,
                    "loss1" => 0.02,
                    "pminf" => -0.1,
                    "pmaxf" => 0.4,
                    "qminf" => -0.15,
                    "qmaxf" => 0.25,
                    "qmint" => -0.1,
                    "qmaxt" => 0.1,
                ),
            ),
            "gen" => Dict{String,Any}(
                "1" => Dict{String,Any}(
                    "index" => 1,
                    "gen_bus" => 1,
                    "pg" => 1.0,
                    "qg" => 0.0,
                    "pmax" => 2.0,
                    "model" => 2,
                    "cost" => [0.0, 2000.0, 0.0],
                ),
            ),
            "load" => Dict{String,Any}(
                "1" => Dict{String,Any}(
                    "index" => 1,
                    "load_bus" => 2,
                    "pd" => 0.8,
                    "qd" => 0.3,
                ),
            ),
        )

        input = from_powermodels(data)

        @test base_power(input) == 100.0
        @test num_buses(input) == 2
        @test num_branches(input) == 1
        @test num_generators(input) == 1
        @test num_loads(input) == 1
        @test num_dclines(input) == 1

        @test bus_type(input, 1) == BusType.Slack
        @test bus_type(input, 2) == BusType.PQ
        @test bus_shunt_susceptance(input, 2) == 5.0

        @test branch_from_bus_idx(input, 1) == 1
        @test branch_to_bus_idx(input, 1) == 2
        @test branch_max_flow(input, 1) == 1.0
        @test branch_tap_ratio(input, 1) == 1.02
        @test branch_is_transformer(input, 1) == true

        @test dcline_from_bus_idx(input, 1) == 1
        @test dcline_to_bus_idx(input, 1) == 2
        @test dcline_active_power(input, 1) == 0.3
        @test dcline_reactive_power_from(input, 1) == -0.05
        @test dcline_reactive_power_to(input, 1) == 0.02
        @test dcline_constant_loss(input, 1) == 0.01
        @test dcline_loss_coefficient(input, 1) == 0.02
        @test dcline_max_flow_from_to(input, 1) == 0.4
        @test dcline_max_flow_to_from(input, 1) ≈ 0.1
        @test dcline_min_reactive_power_from(input, 1) == -0.15
        @test dcline_max_reactive_power_from(input, 1) == 0.25
        @test dcline_min_reactive_power_to(input, 1) == -0.1
        @test dcline_max_reactive_power_to(input, 1) == 0.1

        @test generator_bus_idx(input, 1) == 1
        @test generator_max_active_power(input, 1) == 2.0
        @test generator_max_reactive_power(input, 1) == 999.9
        @test generator_cost(input, 1) == 2000.0

        @test load_bus_idx(input, 1) == 2
        @test load_reactive_power(input, 1) == 0.3
    end

    @testset "sis45b" begin
        include(joinpath(@__DIR__, "..", "examples", "sis45b.jl"))
        input = build_sis45b()

        @test num_buses(input) == 45
        @test num_branches(input) == 72
        @test num_generators(input) == 10
        @test num_loads(input) == 24
        @test count(i -> bus_type(input, i) == BusType.Slack, 1:num_buses(input)) == 1

        # The case carries the operating point Simulight solved for it, so the
        # injections implied by Ybus must match generation minus load at every
        # bus. This is what pins down the conversion out of the .fdx file.
        v = [bus_voltage(input, i) for i in 1:num_buses(input)]
        angle = [bus_voltage_angle(input, i) for i in 1:num_buses(input)]
        scheduled = zeros(ComplexF64, num_buses(input))
        for i in 1:num_generators(input)
            scheduled[generator_bus_idx(input, i)] +=
                generator_active_power(input, i) + im * generator_reactive_power(input, i)
        end
        for i in 1:num_loads(input)
            scheduled[load_bus_idx(input, i)] -=
                load_active_power(input, i) + im * load_reactive_power(input, i)
        end

        mismatch = power_injection(v, angle, ybus(input)) .- scheduled
        @test maximum(abs, mismatch) * base_power(input) < 1e-4 # MVA

        add_sis45b_dynamics!(input)
        @test num_dynamic_generators(input) == 10
        @test num_dynamic_loads(input) == 24
        @test all(
            classic_generator_inertia_constant(input, k) > 0 &&
            classic_generator_transient_reactance(input, k) > 0 for k in 1:10
        )
    end
end
