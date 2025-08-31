module KvaserInterfaces

using CANalyze
import ..Interfaces

include("canlib.jl")
import .Canlib



"""
    KvaserInterface(channel::Int, bitrate::Int)

Setup Kvaser interface with channel number and bitrate(bps).
"""
struct KvaserInterface <: Interfaces.AbstractCANInterface
    handle::Cint

    function KvaserInterface(channel::Int, bitrate::Int;
        fd::Bool=false,
        stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
        extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

        # initialize library
        Canlib.canInitializeLibrary()

        # open channel 0
        hnd = Canlib.canOpenChannel(Cint(channel), Canlib.canOPEN_ACCEPT_VIRTUAL)
        if hnd < 0
            error("Kvaser: channel $channel open failed.")
        end

        # set bitrate
        status = Canlib.canSetBusParams(hnd, Clong(bitrate), Cuint(0), Cuint(0), Cuint(0), Cuint(0), Cuint(0))

        # set drivertype
        status = Canlib.canSetBusOutputControl(hnd, Canlib.canDRIVER_NORMAL)

        # set acceptance filter
        if stdfilter !== nothing
            Canlib.canSetAcceptanceFilter(hnd,
                stdfilter.code_id, stdfilter.mask, Cint(0))
        end
        if extfilter !== nothing
            Canlib.canSetAcceptanceFilter(hnd,
                extfilter.code_id, extfilter.mask, Cint(1))
        end

        # bus on 
        status = Canlib.canBusOn(hnd)

        new(hnd)
    end
end


function Interfaces.send(interface::KvaserInterface,
    frame::CANalyze.CANFrame)::Nothing
    pmsg_t = Ref(frame.data, 1)
    dlc = Cuint(size(frame.data, 1))
    id = Clong(frame.frame_id)
    flag = frame.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD
    status = Canlib.canWrite(interface.handle, id, pmsg_t, dlc, flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit.")
    end
    return nothing

end


function Interfaces.recv(interface::KvaserInterface)::Union{Nothing,CANalyze.CANFrame}
    msg_r = Vector{Cchar}(undef, 8)
    pid = Ref{Clong}(0)
    pmsg_r = Ref(msg_r, 1)
    pdlc = Ref{Cuint}(0)
    pflag = Ref{Cuint}(0)
    ptime = Ref{Culong}(0)
    status = Canlib.canRead(interface.handle, pid, pmsg_r, pdlc, pflag, ptime)
    if status == Canlib.canOK
        isext = (pflag[] & Canlib.canMSG_EXT) != 0

        frame = CANalyze.CANFrame(
            pid[],
            msg_r[1:pdlc[]],
            is_extended=isext
        )
        return frame
    end
    return nothing
end


function Interfaces.shutdown(interface::KvaserInterface)
    status = Canlib.canBusOff(interface.handle)
    status = Canlib.canClose(interface.handle)
    return nothing
end

end # KvaserInterfaces
