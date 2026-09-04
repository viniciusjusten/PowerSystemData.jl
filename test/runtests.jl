using PowerSystemData
using LinearAlgebra
using Test

function build_test_system()
    input = PowerSystemData.Input()

    add_bus!(input; name = "Bus 1", type = BusType.Slack, voltage = 1.0, min_voltage = 0.9, max_voltage = 1.1)
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
        add_dynamic_load!(input, ZConstantLoad(; load_idx = 1, conductance = 0.1, susceptance = 0.05))
        add_perturbation!(input, BusShortCircuit(; bus_idx = 2, time = 1.0, clearing_time = 1.1))
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
end
