module KvaserInterfaces

using CANalyze
import ..Interfaces
import ...Messages

include("canlib.jl")
import .Canlib



"""
    KvaserInterface(channel::Int, bitrate::Int)

Setup Kvaser interface with channel number and bitrate(bps).
"""
struct KvaserInterface <: Interfaces.AbstractCANInterface
    handle::Cint
end

function KvaserInterface(channel::Int, bitrate::Int;
    silent::Bool=false,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize library
    Canlib.canInitializeLibrary()

    # open channel
    hnd = Canlib.canOpenChannel(Cint(channel), Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd < 0
        error("Kvaser: channel $channel open failed.")
    end

    # set bitrate
    status = Canlib.canSetBusParams(hnd, Clong(bitrate),
        Cuint(0), Cuint(0), Cuint(0), Cuint(0), Cuint(0))
    if status < 0
        error("Kvaser: bitrate set failed.")
    end

    # set drivertype
    flag = silent ? Canlib.canDRIVER_SILENT : Canlib.canDRIVER_NORMAL
    status = Canlib.canSetBusOutputControl(hnd, flag)

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
        error("Kvaser: Bus on failed")
    end

    KvaserInterface(hnd)
end


struct KvaserFDInterface <: Interfaces.AbstractCANInterface
    handle::Cint
end

function KvaserFDInterface(channel::Int, bitrate::Int, datarate::Int;
    non_iso::Bool=false, silent::Bool=false,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

    # initialize library
    Canlib.canInitializeLibrary()

    # open channel
    flag = non_iso ? Canlib.canOPEN_CAN_FD_NONISO : Canlib.canOPEN_CAN_FD
    hnd = Canlib.canOpenChannel(Cint(channel), flag | Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd < 0
        error("Kvaser: channel $channel open failed.")
    end

    # set bitrate
    status1 = Canlib.canSetBusParams(hnd, Clong(bitrate),
        Cuint(0), Cuint(0), Cuint(0), Cuint(0), Cuint(0))
    status2 = Canlib.canSetBusParamsFd(hnd, Clong(datarate),
        Cuint(0), Cuint(0), Cuint(0))
    if status1 < 0 || status2 < 0
        error("Kvaser: bitrate set failed.")
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
        error("Kvaser: Bus on failed")
    end

    KvaserFDInterface(hnd)
end

function Interfaces.send(interface::KvaserInterface,
    msg::Messages.CANMessage)::Nothing

    pmsg_t = Ref(msg.data, 1)
    dlc = Cuint(msg.dlc)
    id = Clong(msg.id)
    flag = msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD
    status = Canlib.canWrite(interface.handle, id, pmsg_t, dlc, flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end

function Interfaces.send(interface::KvaserFDInterface,
    msg::Messages.CANFDMessage)::Nothing

    pmesg = Ref(msg.data, 1)
    flag = Canlib.canFDMSG_FDF # CAN FD message
    flag |= msg.is_extended ? Canlib.canMSG_EXT : Canlib.canMSG_STD # STD or EXT id
    flag |= msg.bitrate_switch ? Canlib.canFDMSG_BRS : Cuint(0) # use BRS
    status = Canlib.canWrite(interface.handle,
        Clong(msg.id), pmesg, msg.bytes, flag)

    if status != Canlib.canOK
        error("Kvaser: Failed to transmit. $status")
    end
    return nothing
end


function Interfaces.recv(interface::KvaserInterface)::Union{Nothing,Messages.CANMessage}
    msg_r = zeros(Cuchar,8)
    pid = Ref(Clong(0))
    pmsg_r = Ref(msg_r, 1)
    pdlc = Ref(Cuint(0))
    pflag = Ref(Cuint(0))
    ptime = Ref(Culong(0))
    status = Canlib.canRead(interface.handle, pid, pmsg_r, pdlc, pflag, ptime)
    if status == Canlib.canOK
        isext = (pflag[] & Canlib.canMSG_EXT) != 0

        frame = Messages.CANMessage(pid[], pdlc[], msg_r, isext)
        return frame
    end
    return nothing
end


function Interfaces.recv(interface::KvaserFDInterface)::Union{Nothing,Messages.CANFDMessage}
    pid = Ref(Clong(0))
    msg = zeros(Cuchar, 64)
    pmsg = Ref(msg, 1)
    pbytes = Ref(Cuint(0))
    pflag = Ref(Cuint(0))
    ptime = Ref(Culong(0))
    status = Canlib.canRead(interface.handle, pid, pmsg, pbytes, pflag, ptime)

    if status == Canlib.canOK
        ret = Messages.CANFDMessage(pid[], pbytes[], msg, (pflag[] & Canlib.canMSG_EXT) != 0,
            (pflag[] & Canlib.canFDMSG_BRS) != 0, (pflag[] & Canlib.canFDMSG_ESI) != 0)
        return ret
    elseif status != Canlib.canERR_NOMSG
        error("Kvaser: CANFD receive error. $status")
    end
    return nothing
end


function Interfaces.shutdown(interface::T) where {T<:Union{KvaserInterface,KvaserFDInterface}}
    status = Canlib.canBusOff(interface.handle)
    status = Canlib.canClose(interface.handle)
    return nothing
end

end # KvaserInterfaces
