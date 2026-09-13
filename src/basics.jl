function admittance(resistance::Float64, reactance::Float64)
    return 1 / (resistance + im * reactance)
end

function ybus(input)
    n = num_buses(input)
    Y = zeros(ComplexF64, n, n)

    for i in 1:num_branches(input)
        from = branch_from_bus_idx(input, i)
        to = branch_to_bus_idx(input, i)
        y = admittance(branch_resistance(input, i), branch_reactance(input, i))
        tap = branch_tap_ratio(input, i)
        shift = branch_phase_shift(input, i)
        g_sh = branch_shunt_conductance(input, i)
        b_sh = branch_shunt_susceptance(input, i)

        Y[from, from] += y * tap^2 + g_sh + im * b_sh
        Y[to, to] += y + g_sh + im * b_sh
        Y[from, to] -= y * tap * exp(im * shift)
        Y[to, from] -= y * tap * exp(-im * shift)
    end

    for i in 1:n
        Y[i, i] += im * bus_shunt_susceptance(input, i)
    end

    return Y
end

function zbus(input)
    return inv(ybus(input))
end

voltage_phasor(v::Float64, angle::Float64) = v * exp(im * angle)
voltage_real(v::Float64, angle::Float64) = v * cos(angle)
voltage_imag(v::Float64, angle::Float64) = v * sin(angle)

current_injection(V::AbstractVector{ComplexF64}, Ybus::AbstractMatrix{ComplexF64}) =
    Ybus * V
current_injection_real(v, angle, Ybus::AbstractMatrix{ComplexF64}) =
    real.(current_injection(voltage_phasor.(v, angle), Ybus))
current_injection_imag(v, angle, Ybus::AbstractMatrix{ComplexF64}) =
    imag.(current_injection(voltage_phasor.(v, angle), Ybus))

function power_injection(v, angle, Ybus::AbstractMatrix{ComplexF64})
    V = voltage_phasor.(v, angle)
    I = current_injection(V, Ybus)
    return V .* conj.(I)
end
