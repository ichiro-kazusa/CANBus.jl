using CANalyze
using CANBus
using Test

function main()

    frm = CANBus.Frame(0x0e, [1, 2, 3, 4])

    signal = CANalyze.Signals.NamedSignal("myfloat", nothing, nothing,
        CANalyze.Signals.Float32Signal(start=0; byte_order=:little_endian))
    msg = CANalyze.Messages.Message(0x0e, 4, "msg1", signal)

    d = CANalyze.Decode.decode(msg, CANalyze.Frames.CANFrame(frm))
    println(d)


    true
end

@test main()