""" Internal Device handler for Kvaser """
module KvaserDevices

import ..Devices
import ....InterfaceCfgs
import ....Frames
import ....misc: BitTiming

include("canlib.jl")
import .Canlib


#= mutable struct for handle finalizer =#
mutable struct HandleHolder
    handle::Cint
end


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
struct KvaserDevice{T<:Devices.AbstractBusType} <: Devices.AbstractDevice{T}
    handleholder::HandleHolder
    time_offset::Float64
end


function Devices.dev_open(::Val{InterfaceCfgs.KVASER}, cfg::InterfaceCfgs.InterfaceConfig)

    is_fd = InterfaceCfgs.helper_isfd(cfg)
    is_noniso = cfg.bustype == InterfaceCfgs.CAN_FD_NONISO

    hnd, time_offset = _init_kvaser(cfg.channel, cfg.bitrate,
        cfg.silent, cfg.stdfilter, cfg.extfilter,
        is_fd, is_noniso, cfg.datarate, cfg.sample_point, cfg.sample_point_fd)

    bustype = Devices.bustype_helper(cfg)

    kd = KvaserDevice{bustype}(HandleHolder(hnd), time_offset)
    finalizer(_cleanup, kd.handleholder)

    return kd
end


#= cleanup function for handle finalizer =#
function _cleanup(holder::HandleHolder)
    status = Canlib.canBusOff(holder.handle)
    status = Canlib.canClose(holder.handle)
end


function _init_kvaser(channel::Int, bitrate::Int, silent::Bool,
    stdfilter::Union{Nothing,InterfaceCfgs.AcceptanceFilter},
    extfilter::Union{Nothing,InterfaceCfgs.AcceptanceFilter},
    fd::Bool, non_iso::Bool, datarate::Int,
    sample_point::Real, sample_point_fd::Real)::Tuple{Cint,Float64}

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
    local status2 = Canlib.canOK
    _, tseg1_a, tseg2_a, sjw_a = BitTiming.calc_bittiming(80_000_000, bitrate, sample_point, 255, 255)
    status1 = Canlib.canSetBusParams(hnd, Clong(bitrate),
        Cuint(tseg1_a), Cuint(tseg2_a), Cuint(sjw_a), Cuint(1), Cuint(0))
    if fd
        _, tseg1_d, tseg2_d, sjw_d = BitTiming.calc_bittiming(80_000_000, datarate, sample_point_fd, 255, 255)
        status2 = Canlib.canSetBusParamsFd(hnd,
            Clong(datarate), Cuint(tseg1_d), Cuint(tseg2_d), Cuint(sjw_d))
    end
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


function Devices.dev_send(device::KvaserDevice{T},
    msg::Frames.Frame)::Nothing where {T<:Devices.AbstractBusType}

    pmsg_t = Ref(msg.data, 1)
    len = Cuint(length(msg))
    id = Clong(msg.id)
    flag = msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD
    status = Canlib.canWrite(device.handleholder.handle, id, pmsg_t, len, flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end


function Devices.dev_send(device::KvaserDevice{T},
    msg::Frames.FDFrame)::Nothing where {T<:Devices.BUS_FD}

    pmesg = Ref(msg.data, 1)
    flag = Canlib.canFDMSG_FDF # CAN FD message
    flag |= msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD # STD or EXT id
    flag |= msg.bitrate_switch ? Canlib.canFDMSG_BRS : Cuint(0) # use BRS
    status = Canlib.canWrite(device.handleholder.handle,
        Clong(msg.id), pmesg, Cuint(length(msg)), flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end


function Devices.dev_recv(device::KvaserDevice{T};
    timeout_s::Real=0)::Union{Nothing,Frames.Frame} where {T<:Devices.BUS_20}
    _recv_kvaser_internal(device, timeout_s)
end


function Devices.dev_recv(device::KvaserDevice{T};
    timeout_s::Real=0)::Union{Nothing,Frames.AnyFrame} where {T<:Devices.BUS_FD}
    _recv_kvaser_internal(device, timeout_s)
end


function _recv_kvaser_internal(device::KvaserDevice{T},
    timeout_s::Real)::Union{Nothing,Frames.AnyFrame} where {T<:Devices.AbstractBusType}

    # poll
    if timeout_s != 0
        timeout_ms = timeout_s < 0 ? Culong(0xFFFFFFFF) : Culong(timeout_s * 1e3)
        Canlib.canReadSync(device.handleholder.handle, timeout_ms)
    end

    # receive
    pid = Ref(Clong(0))
    msg = zeros(Cuchar, T <: Devices.BUS_FD ? 64 : 8)
    pmsg = Ref(msg, 1)
    plen = Ref(Cuint(0))
    pflag = Ref(Cuint(0))
    ptime = Ref(Culong(0))
    status = Canlib.canRead(device.handleholder.handle, pid, pmsg, plen, pflag, ptime)

    if status == Canlib.canOK
        is_ext = (pflag[] & Canlib.canMSG_EXT) != 0
        is_err = (pflag[] & Canlib.canMSG_ERROR_FRAME) != 0
        timestamp = device.time_offset + ptime[] * 1.e-6 # arrange in sec

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


function Devices.dev_close(device::KvaserDevice{T}) where {T<:Devices.AbstractBusType}
    status = Canlib.canBusOff(device.handleholder.handle)
    status = Canlib.canClose(device.handleholder.handle)
    return nothing
end

end # KvaserDevices
