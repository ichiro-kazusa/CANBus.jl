"""Internal module for BitTiming calculation and setting."""
module BitTiming


#=
    calc_fdbittiming(bitrate::Float64, samplepoint_percent::Float64,
        tseg1_max::Int, tseg2_max::Int)::NTuple{3,Int64}

Calculate CAN FD bit timing parameters.

* clock: clock frequency in Hz
* bitrate: target bit rate in bit/s
* samplepoint_percent: target sample point in percent (50-100) 
* tseg1_max: maximum TSEG1 value
* tseg2_max: maximum TSEG2 value

returns (prescaler, TSEG1, TSEG2, SJW) tuple.
=#
function calc_bittiming(clock::Int64, bitrate::Real, samplepoint_percent::Real,
    tseg1_max::Int, tseg2_max::Int)::NTuple{4,Int64}

    # check arguments
    if bitrate <= 0
        error("BitTiming: bitrate must be positive.")
    end
    if samplepoint_percent <= 50 || samplepoint_percent >= 100
        error("BitTiming: samplepoint_percent must be in (50, 100).")
    end

    Prescaler_x_NumofQuanta = round(Int64, clock / bitrate) # 80MHz clock

    for i in 1:Prescaler_x_NumofQuanta
        # check prescaler_candidate is valid
        prescaler_candidate = i
        quo, rem = divrem(Prescaler_x_NumofQuanta, prescaler_candidate)
        if rem != 0
            continue
        end

        # calculate TSEG1, TSEG2 candidates
        TSEG2cand = round(Int64, quo * (1 - samplepoint_percent / 100))
        TSEG1cand = quo - TSEG2cand - 1

        # calculate prescaler, TSEG1, TSEG2
        prescaler = gcd(TSEG1cand + 1, TSEG2cand)
        TSEG1 = Int64((TSEG1cand + 1) / prescaler) - 1
        TSEG2 = Int64(TSEG2cand / prescaler)

        # check TSEG1 and TSEG2
        if 1 <= TSEG1 <= tseg1_max && 1 <= TSEG2 <= tseg2_max
            SJW = ceil(TSEG2 / 2)
            return (prescaler, TSEG1, TSEG2, SJW)
        end
    end

    error("BitTiming: cannot find valid bit timing parameters.")
end


end # module BitTiming