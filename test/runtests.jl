import PowerSystemData as PSD
using LinearAlgebra
using Test

function build_test_system()
    input = PSD.Input()

    PSD.add_bus!(
        input;
        name = "Bus 1",
        type = PSD.BusType.Slack,
        voltage = 1.0,
        min_voltage = 0.9,
        max_voltage = 1.1,
    )
    PSD.add_bus!(
        input;
        name = "Bus 2",
        type = PSD.BusType.PQ,
        shunt_susceptance = 0.05,
        min_voltage = 0.9,
        max_voltage = 1.1,
    )
    PSD.add_branch!(
        input;
        name = "L1-2",
        from_bus_idx = 1,
        to_bus_idx = 2,
        resistance = 0.01,
        reactance = 0.1,
        max_flow = 100.0,
    )
    PSD.add_generator!(
        input;
        name = "G1",
        bus_idx = 1,
        active_power = 1.0,
        max_active_power = 2.0,
        cost = 20.0,
    )
    PSD.add_load!(input; name = "Load 2", bus_idx = 2, active_power = 0.8, reactive_power = 0.3)

    return input
end

@testset verbose = true "PowerSystemData" begin
    @testset "system base" begin
        input = build_test_system()

        @test PSD.base_frequency(input) == 60.0
        @test PSD.base_power(input) == 100.0

        PSD.set_base_frequency!(input, 50.0)
        PSD.set_base_power!(input, 1000.0)
        @test PSD.base_frequency(input) == 50.0
        @test PSD.base_power(input) == 1000.0

        european =
            PSD.Input(; base = PSD.SystemBase(; frequency = 50.0, power = 250.0))
        @test PSD.base_frequency(european) == 50.0
        @test PSD.base_power(european) == 250.0
    end

    @testset "static collections" begin
        input = build_test_system()

        @test PSD.num_buses(input) == 2
        @test PSD.num_branches(input) == 1
        @test PSD.num_generators(input) == 1
        @test PSD.num_loads(input) == 1

        @test PSD.bus_name(input, 1) == "Bus 1"
        @test PSD.bus_type(input, 1) == PSD.BusType.Slack
        @test PSD.bus_type(input, 2) == PSD.BusType.PQ

        @test PSD.branch_max_flow(input, 1) == 100.0
        @test PSD.branch_min_angle_difference(input, 1) == -pi / 3
        @test PSD.branch_max_angle_difference(input, 1) == pi / 3
        @test PSD.generator_max_active_power(input, 1) == 2.0
        @test PSD.generator_cost(input, 1) == 20.0
        @test PSD.load_reactive_power(input, 1) == 0.3
    end

    @testset "dcline" begin
        input = build_test_system()
        PSD.add_dcline!(
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

        @test PSD.num_dclines(input) == 1
        @test PSD.dcline_name(input, 1) == "DC1"
        @test PSD.dcline_from_bus_idx(input, 1) == 1
        @test PSD.dcline_to_bus_idx(input, 1) == 2
        @test PSD.dcline_active_power(input, 1) == 0.4
        @test PSD.dcline_reactive_power_from(input, 1) == 0.05
        @test PSD.dcline_reactive_power_to(input, 1) == -0.02
        @test PSD.dcline_constant_loss(input, 1) == 0.01
        @test PSD.dcline_loss_coefficient(input, 1) == 0.02
        @test PSD.dcline_max_flow_from_to(input, 1) == 0.6
        @test PSD.dcline_max_flow_to_from(input, 1) == 0.5
        @test PSD.dcline_min_reactive_power_from(input, 1) == -0.2
        @test PSD.dcline_max_reactive_power_from(input, 1) == 0.2
        @test PSD.dcline_min_reactive_power_to(input, 1) == -0.2
        @test PSD.dcline_max_reactive_power_to(input, 1) == 0.2
    end

    @testset "dynamic collections" begin
        input = build_test_system()

        PSD.add_dynamic_generator!(
            input,
            PSD.ClassicGenerator(;
                generator_idx = 1,
                inertia_constant = 5.0,
                damping_coefficient = 1.0,
                transient_reactance = 0.2,
            ),
        )
        PSD.add_dynamic_load!(
            input,
            PSD.ZConstantLoad(; load_idx = 1, conductance = 0.1, susceptance = 0.05),
        )
        PSD.add_perturbation!(
            input,
            PSD.BusShortCircuit(; bus_idx = 2, time = 1.0, clearing_time = 1.1),
        )
        PSD.add_perturbation!(input, PSD.BranchTrip(; branch_idx = 1, time = 2.0))
        PSD.add_perturbation!(input, PSD.GeneratorTrip(; generator_idx = 1, time = 3.0))

        @test PSD.num_dynamic_generators(input) == 1
        @test PSD.num_dynamic_loads(input) == 1
        @test PSD.num_perturbations(input) == 3

        @test PSD.classic_generator_inertia_constant(input, 1) == 5.0
        @test PSD.z_constant_load_conductance(input, 1) == 0.1
        @test PSD.bus_short_circuit_bus_idx(input, 1) == 2
        @test PSD.branch_trip_time(input, 2) == 2.0
        @test PSD.generator_trip_generator_idx(input, 3) == 1
    end

    @testset "ybus / zbus" begin
        input = build_test_system()

        Y = PSD.ybus(input)
        y_series = 1 / (0.01 + im * 0.1)
        expected = [y_series -y_series; -y_series y_series+im*0.05]
        @test Y ≈ expected atol = 1e-10

        Z = PSD.zbus(input)
        @test Z * Y ≈ Matrix{ComplexF64}(I, 2, 2) atol = 1e-8
    end

    @testset "ybus follows makeYbus for a tapped branch with a shunt" begin
        input = PSD.Input()
        PSD.add_bus!(input; name = "B1")
        PSD.add_bus!(input; name = "B2")
        PSD.add_branch!(
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

        @test PSD.ybus(input) ≈ expected atol = 1e-10
    end

    @testset "voltage / current / power helpers" begin
        input = build_test_system()
        Y = PSD.ybus(input)

        v = [1.0, 0.98]
        angle = [0.0, -0.02]

        V = PSD.voltage_phasor.(v, angle)
        @test real.(V) ≈ PSD.voltage_real.(v, angle)
        @test imag.(V) ≈ PSD.voltage_imag.(v, angle)

        I = PSD.current_injection(V, Y)
        @test real.(I) ≈ PSD.current_injection_real(v, angle, Y)
        @test imag.(I) ≈ PSD.current_injection_imag(v, angle, Y)

        S = PSD.power_injection(v, angle, Y)
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
                    "angmin" => -0.5,
                    "angmax" => 0.4,
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

        input = PSD.from_powermodels(data)

        @test PSD.base_power(input) == 100.0
        @test PSD.num_buses(input) == 2
        @test PSD.num_branches(input) == 1
        @test PSD.num_generators(input) == 1
        @test PSD.num_loads(input) == 1
        @test PSD.num_dclines(input) == 1

        @test PSD.bus_type(input, 1) == PSD.BusType.Slack
        @test PSD.bus_type(input, 2) == PSD.BusType.PQ
        @test PSD.bus_shunt_susceptance(input, 2) == 5.0

        @test PSD.branch_from_bus_idx(input, 1) == 1
        @test PSD.branch_to_bus_idx(input, 1) == 2
        @test PSD.branch_max_flow(input, 1) == 1.0
        @test PSD.branch_min_angle_difference(input, 1) == -0.5
        @test PSD.branch_max_angle_difference(input, 1) == 0.4
        @test PSD.branch_tap_ratio(input, 1) == 1.02
        @test PSD.branch_is_transformer(input, 1) == true

        @test PSD.dcline_from_bus_idx(input, 1) == 1
        @test PSD.dcline_to_bus_idx(input, 1) == 2
        @test PSD.dcline_active_power(input, 1) == 0.3
        @test PSD.dcline_reactive_power_from(input, 1) == -0.05
        @test PSD.dcline_reactive_power_to(input, 1) == 0.02
        @test PSD.dcline_constant_loss(input, 1) == 0.01
        @test PSD.dcline_loss_coefficient(input, 1) == 0.02
        @test PSD.dcline_max_flow_from_to(input, 1) == 0.4
        @test PSD.dcline_max_flow_to_from(input, 1) ≈ 0.1
        @test PSD.dcline_min_reactive_power_from(input, 1) == -0.15
        @test PSD.dcline_max_reactive_power_from(input, 1) == 0.25
        @test PSD.dcline_min_reactive_power_to(input, 1) == -0.1
        @test PSD.dcline_max_reactive_power_to(input, 1) == 0.1

        @test PSD.generator_bus_idx(input, 1) == 1
        @test PSD.generator_max_active_power(input, 1) == 2.0
        @test PSD.generator_max_reactive_power(input, 1) == 999.9
        @test PSD.generator_cost(input, 1) == 2000.0

        @test PSD.load_bus_idx(input, 1) == 2
        @test PSD.load_reactive_power(input, 1) == 0.3
    end

    @testset "sis45b" begin
        include(joinpath(@__DIR__, "..", "examples", "sis45b.jl"))
        input = build_sis45b()

        @test PSD.num_buses(input) == 45
        @test PSD.num_branches(input) == 72
        @test PSD.num_generators(input) == 10
        @test PSD.num_loads(input) == 24
        @test count(i -> PSD.bus_type(input, i) == PSD.BusType.Slack, 1:PSD.num_buses(input)) == 1

        # The case carries the operating point Simulight solved for it, so the
        # injections implied by Ybus must match generation minus load at every
        # bus. This is what pins down the conversion out of the .fdx file.
        v = [PSD.bus_voltage(input, i) for i in 1:PSD.num_buses(input)]
        angle = [PSD.bus_voltage_angle(input, i) for i in 1:PSD.num_buses(input)]
        scheduled = zeros(ComplexF64, PSD.num_buses(input))
        for i in 1:PSD.num_generators(input)
            scheduled[PSD.generator_bus_idx(input, i)] +=
                PSD.generator_active_power(input, i) + im * PSD.generator_reactive_power(input, i)
        end
        for i in 1:PSD.num_loads(input)
            scheduled[PSD.load_bus_idx(input, i)] -=
                PSD.load_active_power(input, i) + im * PSD.load_reactive_power(input, i)
        end

        mismatch = PSD.power_injection(v, angle, PSD.ybus(input)) .- scheduled
        @test maximum(abs, mismatch) * PSD.base_power(input) < 1e-4 # MVA

        add_sis45b_dynamics!(input)
        @test PSD.num_dynamic_generators(input) == 10
        @test PSD.num_dynamic_loads(input) == 24
        @test all(
            PSD.classic_generator_inertia_constant(input, k) > 0 &&
            PSD.classic_generator_transient_reactance(input, k) > 0 for k in 1:10
        )
    end
end
