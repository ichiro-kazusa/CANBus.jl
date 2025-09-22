module KvaserInterfaces

import ..Interfaces
import ...Frames
import ...core: BitTiming

include("canlib.jl")
import .Canlib


"""
    KvaserInterface(channel::Int, bitrate::Int;
        silent::Bool, stdfilter::AcceptanceFilter, extfilter::AcceptanceFilter)

Setup Kvaser interface
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.

kwargs:
* silent(optional): listen only flag in bool.
* sample_point(optional): sample point in percent. Default is 70 (%).
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct KvaserInterface <: Interfaces.AbstractCANInterface
    handle::Cint
    time_offset::Float64
end


function KvaserInterface(channel::Int, bitrate::Int;
    silent::Bool=false, sample_point::Real=70,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize Kvaser CAN
    hnd, time_offset = _init_kvaser(channel, bitrate, silent, stdfilter, extfilter,
        false, false, 1, sample_point)

    KvaserInterface(hnd, time_offset)
end


"""
    KvaserFDInterface(channel::Int, bitrate::Int, datarate::Int;
        non_iso::Bool, silent::Bool, stdfilter::AcceptanceFilter, extfilter::AcceptanceFilter)

Setup Kvaser interface for CAN FD.
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.
* datarate: datarate as bit/s in integer.

kwargs:
* non_iso(optional): use non-iso version of CAN FD
* silent(optional): listen only flag in bool.
* sample_point(optional): sample point in percent. Default is 70 (%).
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct KvaserFDInterface <: Interfaces.AbstractCANInterface
    handle::Cint
    time_offset::Float64
end


function KvaserFDInterface(channel::Int, bitrate::Int, datarate::Int;
    non_iso::Bool=false, silent::Bool=false, sample_point::Real=70,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize Kvaser CAN FD
    hnd, time_offset = _init_kvaser(channel, bitrate, silent, stdfilter, extfilter,
        true, non_iso, datarate, sample_point)

    KvaserFDInterface(hnd, time_offset)
end


#= constructor for do statement =#
function KvaserInterface(f::Function, args...; kwargs...)
    bus = KvaserInterface(args...; kwargs...)
    try
        return f(bus)
    finally
        Interfaces.shutdown(bus)
    end
end


#= constructor for do statement =#
function KvaserFDInterface(f::Function, args...; kwargs...)
    bus = KvaserFDInterface(args...; kwargs...)
    try
        return f(bus)
    finally
        Interfaces.shutdown(bus)
    end
end


function _init_kvaser(channel::Int, bitrate::Int, silent::Bool,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    fd::Bool, non_iso::Bool, datarate::Int, sample_point::Real)::Tuple{Cint,Float64}

    # initialize library
    Canlib.canInitializeLibrary()

    # open channel
    flag = !fd ? Cint(0) :
           non_iso ? Canlib.canOPEN_CAN_FD_NONISO : Canlib.canOPEN_CAN_FD
    hnd = Canlib.canOpenChannel(Cint(channel), flag | Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd < 0
        error("Kvaser: channel $channel open failed. $hnd")
    end

    # set bitrate
    _, tseg1_a, tseg2_a, sjw_a = BitTiming.calc_bittiming(80_000_000, bitrate, sample_point, 255, 255)
    _, tseg1_d, tseg2_d, sjw_d = BitTiming.calc_bittiming(80_000_000, datarate, sample_point, 255, 255)
    status1 = Canlib.canSetBusParams(hnd, Clong(bitrate),
        Cuint(tseg1_a), Cuint(tseg2_a), Cuint(sjw_a), Cuint(1), Cuint(0))
    status2 = !fd ? Canlib.canOK : Canlib.canSetBusParamsFd(hnd,
        Clong(datarate), Cuint(tseg1_d), Cuint(tseg2_d), Cuint(sjw_d))
    if status1 < 0 || status2 < 0
        error("Kvaser: bitrate set failed. $status1, $status2")
    end

    # set drivertype
    flag = silent ? Canlib.canDRIVER_SILENT : Canlib.canDRIVER_NORMAL
    Canlib.canSetBusOutputControl(hnd, flag)

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
    if status < 0
        error("Kvaser: Bus on failed. $status")
    end

    # set timer scale at microsec
    status = Canlib.canIoCtl(hnd, Canlib.canIOCTL_SET_TIMER_SCALE,
        Ref(UInt32(1)), UInt32(4))
    if status != Canlib.canOK
        error("Kvaser: failed to set timer scale.")
    end

    # get time offset
    ptime = Ref(Cuint(0))
    Canlib.kvReadTimer(hnd, ptime)
    time_offset = time() - ptime[] * 1.e-6 # arrange in sec

    # flush receive queue
    Canlib.canFlushReceiveQueue(hnd)

    return hnd, time_offset
end


function Interfaces.send(interface::T,
    msg::Frames.Frame)::Nothing where {T<:Union{KvaserInterface,KvaserFDInterface}}

    pmsg_t = Ref(msg.data, 1)
    len = Cuint(length(msg))
    id = Clong(msg.id)
    flag = msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD
    status = Canlib.canWrite(interface.handle, id, pmsg_t, len, flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end


function Interfaces.send(interface::KvaserFDInterface,
    msg::Frames.FDFrame)::Nothing

    pmesg = Ref(msg.data, 1)
    flag = Canlib.canFDMSG_FDF # CAN FD message
    flag |= msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD # STD or EXT id
    flag |= msg.bitrate_switch ? Canlib.canFDMSG_BRS : Cuint(0) # use BRS
    status = Canlib.canWrite(interface.handle,
        Clong(msg.id), pmesg, Cuint(length(msg)), flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end


function Interfaces.recv(interface::KvaserInterface;
    timeout_s::Real=0)::Union{Nothing,Frames.Frame}
    _recv_kvaser_internal(interface, timeout_s)
end


function Interfaces.recv(interface::KvaserFDInterface;
    timeout_s::Real=0)::Union{Nothing,Frames.AnyFrame}
    _recv_kvaser_internal(interface, timeout_s)
end


function _recv_kvaser_internal(interface::T,
    timeout_s::Real)::Union{Nothing,Frames.AnyFrame} where {T<:Union{KvaserInterface,KvaserFDInterface}}

    # poll
    if timeout_s != 0
        timeout_ms = timeout_s < 0 ? Culong(0xFFFFFFFF) : Culong(timeout_s * 1e3)
        Canlib.canReadSync(interface.handle, timeout_ms)
    end

    # receive
    pid = Ref(Clong(0))
    msg = zeros(Cuchar, T == KvaserFDInterface ? 64 : 8)
    pmsg = Ref(msg, 1)
    plen = Ref(Cuint(0))
    pflag = Ref(Cuint(0))
    ptime = Ref(Culong(0))
    status = Canlib.canRead(interface.handle, pid, pmsg, plen, pflag, ptime)

    if status == Canlib.canOK
        is_ext = (pflag[] & Canlib.canMSG_EXT) != 0
        is_err = (pflag[] & Canlib.canMSG_ERROR_FRAME) != 0
        timestamp = interface.time_offset + ptime[] * 1.e-6 # arrange in sec

        if (pflag[] & Canlib.canFDMSG_FDF) != 0 # FD Message
            brs = (pflag[] & Canlib.canFDMSG_BRS) != 0
            esi = (pflag[] & Canlib.canFDMSG_ESI) != 0

            ret = Frames.FDFrame(pid[], msg[1:plen[]];
                is_extended=is_ext, is_error_frame=is_err,
                bitrate_switch=brs, error_state=esi, timestamp=timestamp)
            return ret
        else
            is_rtr = (pflag[] & Canlib.canMSG_RTR) != 0
            ret = Frames.Frame(pid[], msg[1:plen[]]; is_extended=is_ext,
                is_remote_frame=is_rtr, is_error_frame=is_err,
                timestamp=timestamp)
            return ret
        end
    elseif status == Canlib.canERR_NOMSG
        return nothing
    else
        error("Kvaser: receive error. $status")
    end
end


function Interfaces.shutdown(interface::T) where {T<:Union{KvaserInterface,KvaserFDInterface}}
    status = Canlib.canBusOff(interface.handle)
    status = Canlib.canClose(interface.handle)
    return nothing
end

end # KvaserInterfaces
