module SocketCANInterfaces

import ..Interfaces
import ...Frames

include("socketcanapi.jl")
import .SocketCAN



"""
    SocketCANInterface(channel::String; filters::Vector{AcceptanceFilter})

Setup SocketCAN interface.
* channel: channel name string, e.g. "can0"
* filters(optional): list of filters. experimental.
"""
struct SocketCANInterface <: Interfaces.AbstractCANInterface
    socket::Cint

    function SocketCANInterface(channel::String;
        filters::Union{Nothing,Vector{Interfaces.AcceptanceFilter}}=nothing)

        s = _init_can(channel, filters, false)

        new(s)
    end
end


"""
    SocketCANFDInterface(channel::String; filters::Vector{AcceptanceFilter})

Setup SocketCAN for CAN FD.
* channel: channel name string, e.g. "can0"
* filters(optional): list of filters. experimental.
"""
struct SocketCANFDInterface <: Interfaces.AbstractCANInterface
    socket::Cint

    function SocketCANFDInterface(channel::String;
        filters::Union{Nothing,Vector{Interfaces.AcceptanceFilter}}=nothing)

        s = _init_can(channel, filters, true)

        new(s)
    end
end


function _init_can(channel::String,
    filters::Union{Nothing,Vector{Interfaces.AcceptanceFilter}},
    fd::Bool)::Cint

    # open socket
    s = SocketCANBus.socket(SocketCANBus.PF_CAN,
        SocketCANBus.SOCK_RAW | SocketCANBus.SOCK_NONBLOCK, SocketCANBus.CAN_RAW)
    if s < 0
        error("SocketCAN: socket could not open.")
    end

    # ioctl
    ifname = Vector{Cchar}(codeunits(channel))
    ifname_pad = vcat(ifname, zeros(Cchar, 16 - length(ifname)))
    ifr = SocketCANBus.ifreq(ifname_pad, zeros(Cchar, 16))
    pifr = Ref(ifr)
    io = SocketCANBus.ioctl(s, SocketCANBus.SIOCGIFINDEX, pifr)
    if io < 0
        error("SocketCAN: $channel is not found.")
    end

    # enable FD frames
    if fd
        enable_canfd::Cint = 1
        penable_canfd = Ref(enable_canfd)
        so = SocketCANBus.setsockopt(s, SocketCANBus.SOL_CAN_RAW,
            SocketCANBus.CAN_RAW_FD_FRAMES, penable_canfd, Cuint(4))
        if so < 0
            error("SocketCAN: setting CAN FD failed. $so")
        end
    end

    # set filters
    if filters !== nothing
        rfilter = [SocketCANBus.can_filter(f.code_id, f.mask) for f in filters]
        prfilter = Ref(rfilter, 1)
        so = SocketCANBus.setsockopt(s, SocketCANBus.SOL_CAN_RAW,
            SocketCANBus.CAN_RAW_FILTER, prfilter, Cuint(8 * size(rfilter, 1)))
        if so < 0
            s = Libc.strerror(Libc.errno())
            error("SocketCAN: filter setting error: $s")
        end
    end

    # bind
    ptr = Base.unsafe_convert(Ptr{Cint}, pointer(pifr[].ifr_ifru))
    ifr_ifindex = unsafe_load(ptr)
    addr = SocketCANBus.sockaddr_can(SocketCANBus.AF_CAN, ifr_ifindex,
        zeros(Cchar, 13))
    paddr = Ref(addr)
    b = SocketCANBus.bind(s, paddr, Cuint(19))
    if b < 0
        error("SocketCAN: bind error. $b")
    end

    return s
end


function Interfaces.send(interface::SocketCANInterface,
    msg::Frames.Frame)::Nothing

    id = msg.is_extended ? msg.id | SocketCANBus.CAN_EFF_FLAG : msg.id
    dlc = size(msg.data, 1)
    data = zeros(UInt8, 8)
    data[1:dlc] .= msg.data
    msg = SocketCANBus.can_frame(id, dlc, 0, 0, 0, data)
    pmsg = Ref(msg)
    written = SocketCANBus.write(interface.socket, pmsg, Cuint(16))

    if written != Cuint(16)
        error("SocketCAN: Failed to transmit.")
    end
    return nothing
end


function Interfaces.send(interface::SocketCANFDInterface,
    msg::Frames.FDFrame)::Nothing

    id = msg.is_extended ? msg.id | SocketCANBus.CAN_EFF_FLAG : msg.id
    len = size(msg.data, 1)
    data = zeros(UInt8, 64)
    data[1:len] .= msg.data
    flags = msg.bitrate_switch ? SocketCANBus.CANFD_BRS | SocketCANBus.CANFD_FDF :
            SocketCANBus.CANFD_FDF
    msg = SocketCANBus.canfd_frame(id, len, flags, 0, 0, data)
    pmsg = Ref(msg)
    written = SocketCANBus.write(interface.socket, pmsg, Cuint(72))

    if written != Cuint(72)
        error("SocketCAN: Failed to transmit.")
    end
    return nothing
end


function Interfaces.recv(interface::SocketCANInterface)::Union{Nothing,Frames.Frame}
    frame_r = SocketCANBus.can_frame(0, 0, 0, 0, 0, zeros(Cchar, 8)) # empty frame
    pframe_r = Ref(frame_r)
    nbytes = SocketCANBus.read(interface.socket, pframe_r, Cuint(16))
    if nbytes >= 0
        rawid = pframe_r[].can_id
        isext = (rawid & SocketCANBus.CAN_EFF_FLAG) != 0
        id = isext ? rawid - SocketCANBus.CAN_EFF_FLAG : rawid
        dlc = pframe_r[].len
        frame = Frames.Frame(
            id,
            pframe_r[].data[1:dlc],
            isext
        )
        return frame
    end
    return nothing
end


function Interfaces.recv(interface::SocketCANFDInterface)::Union{Nothing,Frames.FDFrame}
    frame_r = SocketCANBus.canfd_frame(0, 0, 0, 0, 0, zeros(Cchar, 64)) # empty frame
    pframe_r = Ref(frame_r)
    nbytes = SocketCANBus.read(interface.socket, pframe_r, Cuint(72))
    if nbytes >= 0
        rawid = pframe_r[].can_id
        isext = (rawid & SocketCANBus.CAN_EFF_FLAG) != 0
        isbrs = (pframe_r[].flags & SocketCANBus.CANFD_BRS) != 0
        isesi = (pframe_r[].flags & SocketCANBus.CANFD_ESI) != 0
        id = isext ? rawid - SocketCANBus.CAN_EFF_FLAG : rawid
        len = pframe_r[].len
        msg = Frames.FDFrame(
            id,
            pframe_r[].data[1:len],
            isext, isbrs, isesi
        )
        return msg
    end
    return nothing
end

function Interfaces.shutdown(interface::T) where {T<:Union{SocketCANInterface,SocketCANFDInterface}}
    SocketCANBus.close(interface.socket)
    return nothing
end


end # SocketCANInterfaces