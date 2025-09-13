module KvaserInterfaces

import ..Interfaces
import ...Frames

include("canlib.jl")
import .Canlib


"""
    KvaserInterface(channel::Int, bitrate::Int;
        silent::Bool, stdfilter::AcceptanceFilter, extfilter::AcceptanceFilter)

Setup Kvaser interface
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.
* silent(optional): listen only flag in bool.
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct KvaserInterface <: Interfaces.AbstractCANInterface
    handle::Cint
end


function KvaserInterface(channel::Int, bitrate::Int;
    silent::Bool=false,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize Kvaser CAN
    hnd = _init_kvaser(channel, bitrate, silent, stdfilter, extfilter,
        false, false, 0)

    KvaserInterface(hnd)
end


"""
    KvaserFDInterface(channel::Int, bitrate::Int, datarate::Int;
        non_iso::Bool, silent::Bool, stdfilter::AcceptanceFilter, extfilter::AcceptanceFilter)

Setup Kvaser interface for CAN FD.
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.
* datarate: datarate as bit/s in integer.
* non_iso(optional): use non-iso version of CAN FD
* silent(optional): listen only flag in bool.
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct KvaserFDInterface <: Interfaces.AbstractCANInterface
    handle::Cint
end


function KvaserFDInterface(channel::Int, bitrate::Int, datarate::Int;
    non_iso::Bool=false, silent::Bool=false,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize Kvaser CAN FD
    hnd = _init_kvaser(channel, bitrate, silent, stdfilter, extfilter,
        true, non_iso, datarate)

    KvaserFDInterface(hnd)
end


function _init_kvaser(channel::Int, bitrate::Int, silent::Bool,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    fd::Bool, non_iso::Bool, datarate::Int)::Cint

    # initialize library
    Canlib.canInitializeLibrary()

    # open channel
    flag = !fd ? Cint(0) :
           non_iso ? Canlib.canOPEN_CAN_FD_NONISO : Canlib.canOPEN_CAN_FD
    hnd = Canlib.canOpenChannel(Cint(channel), flag | Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd < 0
        error("Kvaser: channel $channel open failed. $hnd")
    end

    # set bitrate / tseg1, tseg2, sjw is used the same numbers as Vector.
    status1 = Canlib.canSetBusParams(hnd, Clong(bitrate),
        Cuint(6), Cuint(3), Cuint(2), Cuint(1), Cuint(0))
    status2 = !fd ? Canlib.canOK : Canlib.canSetBusParamsFd(hnd,
        Clong(datarate), Cuint(6), Cuint(3), Cuint(2))
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

    return hnd
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


function Interfaces.recv(interface::KvaserInterface)::Union{Nothing,Frames.Frame}
    _recv_kvaser_internal(interface)
end


function Interfaces.recv(interface::KvaserFDInterface)::Union{Nothing,Frames.AnyFrame}
    _recv_kvaser_internal(interface)
end


function _recv_kvaser_internal(interface::T)::Union{Nothing,Frames.AnyFrame} where {T<:Union{KvaserInterface,KvaserFDInterface}}
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

        if (pflag[] & Canlib.canFDMSG_FDF) != 0 # FD Message
            brs = (pflag[] & Canlib.canFDMSG_BRS) != 0
            esi = (pflag[] & Canlib.canFDMSG_ESI) != 0

            ret = Frames.FDFrame(pid[], msg[1:plen[]];
                is_extended=is_ext, is_error_frame=is_err,
                bitrate_switch=brs, error_state=esi)
            return ret
        else
            is_rtr = (pflag[] & Canlib.canMSG_RTR) != 0
            ret = Frames.Frame(pid[], msg[1:plen[]]; is_extended=is_ext,
                is_remote_frame=is_rtr, is_error_frame=is_err)
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
