module SocketCANDevices

import ..Devices
import ....InterfaceCfgs
import ....Frames
import ....Errors
include("socketcanapi.jl")
import .SocketCAN
using FileWatching


#= mutable struct for handle finalizer =#
mutable struct SocketHolder
    socket::Cint
end


"""
    SocketCANDevice(socketholder::SocketHolder)

Struct for store SocketCAN device handle.
"""
struct SocketCANDevice{T<:Devices.AbstractBusType} <: Devices.AbstractDevice{T}
    socketholder::SocketHolder
    r_status::Ref{Devices.BusStatus} # to treat as mutable
end


function Devices.dev_open(::Val{InterfaceCfgs.SOCKETCAN}, cfg::InterfaceCfgs.InterfaceConfig)
    is_fd = InterfaceCfgs.helper_isfd(cfg)

    # preprocess filter
    filters = InterfaceCfgs.AcceptanceFilter[]
    append!(filters, _preprocess_filter(cfg.stdfilter, false))
    append!(filters, _preprocess_filter(cfg.extfilter, true))
    filters = length(filters) == 0 ? nothing : filters

    s = _init_can(cfg.channel, filters, is_fd)

    bustype = Devices.helper_bustype(cfg)

    sd = SocketCANDevice{bustype}(SocketHolder(s), Ref(Devices.NO_STATUS))
    finalizer(_cleanup, sd.socketholder)

    return sd
end


#= filter preprocessor =#
function _preprocess_filter(filter::T, isext::Bool)::Vector{InterfaceCfgs.AcceptanceFilter} where T
    flag = isext ? SocketCAN.CAN_EFF_FLAG : UInt32(0)
    mask = SocketCAN.CAN_EFF_FLAG | SocketCAN.CAN_RTR_FLAG

    if filter === nothing
        return InterfaceCfgs.AcceptanceFilter[]
    elseif T == InterfaceCfgs.AcceptanceFilter
        return [InterfaceCfgs.AcceptanceFilter(
            filter.code_id | flag, filter.mask | mask)]
    elseif length(filter) == 0
        return InterfaceCfgs.AcceptanceFilter[]
    else
        return [InterfaceCfgs.AcceptanceFilter(
            f.code_id | flag, f.mask | mask) for f in filter]
    end
end


#= cleanup function for socket finalizer =#
function _cleanup(holder::SocketHolder)
    SocketCAN.close(holder.socket)
end


function _init_can(channel::String,
    filters::Union{Nothing,Vector{InterfaceCfgs.AcceptanceFilter}},
    fd::Bool)::Cint

    # cleanup unreferenced socket
    GC.gc()

    # open socket
    s = SocketCAN.socket(SocketCAN.PF_CAN,
        SocketCAN.SOCK_RAW | SocketCAN.SOCK_NONBLOCK, SocketCAN.CAN_RAW)
    if s < 0
        throw(Errors.CANBusOpenError("socket could not open.",
            "SocketCAN", "$s"))
    end

    # ioctl to set ch name
    ifname = Vector{Cchar}(codeunits(channel))
    ifname_pad = vcat(ifname, zeros(Cchar, 16 - length(ifname)))
    ifr = SocketCAN.ifreq((ifname_pad...,), (zeros(Cchar, 16)...,))
    pifr = Ref(ifr)
    io = SocketCAN.ioctl(s, SocketCAN.SIOCGIFINDEX, pifr)
    if io < 0
        throw(Errors.CANBusOpenError("$channel is not found.",
            "SocketCAN", "$io"))
    end

    # enable FD frames
    if fd
        enable_canfd::Cint = 1
        penable_canfd = Ref(enable_canfd)
        so = SocketCAN.setsockopt(s, SocketCAN.SOL_CAN_RAW,
            SocketCAN.CAN_RAW_FD_FRAMES, penable_canfd, Cuint(sizeof(Cint)))
        if so < 0
            throw(Errors.CANBusOpenError("setting CAN FD failed.",
                "SocketCAN", "$so"))
        end
    end

    # use timestamp (software)
    p_on = Ref(Cint(1))
    so = SocketCAN.setsockopt(s, SocketCAN.SOL_SOCKET,
        SocketCAN.SO_TIMESTAMPNS_NEW, p_on, Cuint(sizeof(Cint)))
    if so < 0
        throw(Errors.CANBusOpenError("setting up for capture timestamp is failed.",
            "SocketCAN", "$so"))
    end

    # set filters
    if filters !== nothing
        rfilter = [SocketCAN.can_filter(f.code_id, f.mask) for f in filters]
        prfilter = Ref(rfilter, 1)
        so = SocketCAN.setsockopt(s, SocketCAN.SOL_CAN_RAW,
            SocketCAN.CAN_RAW_FILTER, prfilter, Cuint(8 * size(rfilter, 1)))
        if so < 0
            err = Libc.strerror(Libc.errno())
            throw(Errors.CANBusOpenError("filter setting error.",
                "SocketCAN", "$err"))
        end
    end

    # enable receive error-frame
    enable_err = Cint(SocketCAN.CAN_ERR_BUSOFF | SocketCAN.CAN_ERR_CRTL)
    so = SocketCAN.setsockopt(s, SocketCAN.SOL_CAN_RAW,
        SocketCAN.CAN_RAW_ERR_FILTER, Ref(enable_err), Cuint(sizeof(enable_err)))
    if so < 0
        throw(Errors.CANBusOpenError("Failed to set receiving error-frame.",
            "SocketCAN", "$so"))
    end

    # bind
    ptr = ccall(:jl_value_ptr, Ptr{Cint}, (Any,), pifr[].ifr_ifru) # convert to Cint pointer
    ifr_ifindex = unsafe_load(ptr)
    addr = SocketCAN.sockaddr_can(SocketCAN.AF_CAN, ifr_ifindex,
        (zeros(Cchar, 13)...,))
    paddr = Ref(addr)
    b = SocketCAN.bind(s, paddr, Cuint(19))
    if b < 0
        throw(Errors.CANBusOpenError("bind error.",
            "SocketCAN", "$b"))
    end

    return s
end


function Devices.dev_send(device::SocketCANDevice,
    msg::Frames.Frame)::Nothing

    id = msg.is_extended ? msg.id | SocketCAN.CAN_EFF_FLAG : msg.id
    id |= msg.is_error_frame ? SocketCAN.CAN_RTR_FLAG : UInt32(0)
    dlc = size(msg.data, 1)
    data = zeros(UInt8, 8)
    data[1:dlc] .= msg.data
    msg = SocketCAN.can_frame(id, dlc, 0, 0, 0, (data...,))
    pmsg = Ref(msg)
    written = SocketCAN.write(device.socketholder.socket,
        pmsg, Cuint(sizeof(SocketCAN.can_frame)))

    if written != Cuint(sizeof(SocketCAN.can_frame))
        throw(Errors.CANBusIOError("Failed to transmit.",
            "send_Frame", "SocketCAN", "$written"))
    end
    return nothing
end


function Devices.dev_send(device::SocketCANDevice{T},
    msg::Frames.FDFrame)::Nothing where {T<:Devices.BUS_FD}

    id = msg.is_extended ? msg.id | SocketCAN.CAN_EFF_FLAG : msg.id
    len = size(msg.data, 1)
    data = zeros(UInt8, 64)
    data[1:len] .= msg.data
    flags = msg.bitrate_switch ? SocketCAN.CANFD_BRS | SocketCAN.CANFD_FDF :
            SocketCAN.CANFD_FDF
    msg = SocketCAN.canfd_frame(id, len, flags, 0, 0, (data...,))
    pmsg = Ref(msg)
    written = SocketCAN.write(device.socketholder.socket,
        pmsg, Cuint(sizeof(SocketCAN.canfd_frame)))

    if written != Cuint(sizeof(SocketCAN.canfd_frame))
        throw(Errors.CANBusIOError("Failed to transmit.",
            "send_FDFrame", "SocketCAN", "$written"))
    end
    return nothing
end


function Devices.dev_recv(device::SocketCANDevice; timeout_s::Real=0)::Union{Nothing,Frames.AnyFrame}

    # polling (Do not use ccall(:poll). It may blocks julia's process.)
    if timeout_s != 0
        poll_fd(Libc.RawFD(device.socketholder.socket), timeout_s; readable=true)
    end

    # prepare to receive
    r_frame = Ref{SocketCAN.canfd_frame}()
    r_iov = Ref{SocketCAN.iovec}()
    r_addr = Ref{SocketCAN.sockaddr_can}()

    ctrl_len = 100
    ctrlbuf = Vector{UInt8}(undef, ctrl_len)

    # receive
    GC.@preserve r_frame r_iov r_addr ctrlbuf begin
        p_frame = Base.unsafe_convert(Ptr{SocketCAN.canfd_frame}, r_frame)
        iov = SocketCAN.iovec(Ptr{Cvoid}(p_frame), Csize_t(sizeof(SocketCAN.canfd_frame)))
        r_iov[] = iov

        msg = SocketCAN.msghdr(
            Ptr{Cvoid}(Base.unsafe_convert(Ptr{SocketCAN.sockaddr_can}, r_addr)), # msg_name
            SocketCAN.socklen_t(sizeof(SocketCAN.sockaddr_can)),
            Base.unsafe_convert(Ptr{SocketCAN.iovec}, r_iov),
            Csize_t(1),
            Ptr{Cvoid}(pointer(ctrlbuf)),
            Csize_t(ctrl_len),
            Cint(0)
        )
        r_msg = Ref(msg)

        nbytes = SocketCAN.recvmsg(device.socketholder.socket, r_msg, Cint(0))

        if nbytes < 0
            ern = Libc.errno()
            if ern == SocketCAN.EAGAIN
                return nothing # rx queue is empty
            else
                throw(Errors.CANBusIOError("Receive error",
                    "recv", "SocketCAN", "$ern"))
            end
        else
            if nbytes != sizeof(SocketCAN.canfd_frame) && nbytes != sizeof(SocketCAN.can_frame)
                throw(Errors.CANBusIOError("Received unexpected length",
                    "recv", "SocketCAN", "$nbytes"))
            end
        end

        # parse timestamp
        p_ctrlhdr = Ptr{SocketCAN.cmsghdr}(r_msg[].msg_control)
        p_ctrldata = Ptr{SocketCAN.timespec}(p_ctrlhdr + sizeof(SocketCAN.cmsghdr))
        ts = unsafe_load(p_ctrldata)
        timestamp = ts.tv_sec + ts.tv_nsec * 1.e-9

        # parse frame
        rawid = r_frame[].can_id
        isext = (rawid & SocketCAN.CAN_EFF_FLAG) != 0
        isrtr = (rawid & SocketCAN.CAN_RTR_FLAG) != 0
        iserr = (rawid & SocketCAN.CAN_ERR_FLAG) != 0
        isfdf = (r_frame[].flags & SocketCAN.CANFD_FDF) != 0
        isbrs = (r_frame[].flags & SocketCAN.CANFD_BRS) != 0
        isesi = (r_frame[].flags & SocketCAN.CANFD_ESI) != 0
        id = isext ? rawid - SocketCAN.CAN_EFF_FLAG : rawid
        id = isrtr ? id - SocketCAN.CAN_RTR_FLAG : id
        id = iserr ? id - SocketCAN.CAN_ERR_FLAG : id
        len = r_frame[].len

        # if BUSOFF/CTRL error frame, store status. then, re-recv
        if iserr
            if (SocketCAN.CAN_ERR_BUSOFF & id) != 0
                device.r_status[] = Devices.BUSOFF
                return Devices.dev_recv(device, timeout_s=timeout_s)
            elseif (SocketCAN.CAN_ERR_CRTL & id) != 0
                if (r_frame[].data[2] & 0x04) != 0 || (r_frame[].data[2] & 0x08) != 0
                    device.r_status[] = Devices.ERROR_WARNING
                    return Devices.dev_recv(device, timeout_s=timeout_s)
                elseif (r_frame[].data[2] & 0x10) != 0 || (r_frame[].data[2] & 0x20) != 0
                    device.r_status[] = Devices.ERROR_PASSIVE
                    return Devices.dev_recv(device, timeout_s=timeout_s)
                elseif (r_frame[].data[2] & 0x40) != 0
                    device.r_status[] = Devices.ERROR_ACTIVE
                    return Devices.dev_recv(device, timeout_s=timeout_s)
                end
                return Devices.dev_recv(device, timeout_s=timeout_s)
            end
        end

        # construct Frame/FDFrame
        if isfdf
            msg = Frames.FDFrame(
                id, collect(r_frame[].data[1:len]);
                is_extended=isext, bitrate_switch=isbrs,
                error_state=isesi, is_error_frame=iserr,
                timestamp=timestamp)
            return msg
        else
            msg = Frames.Frame(id, collect(r_frame[].data[1:len]);
                is_extended=isext, is_remote_frame=isrtr, is_error_frame=iserr,
                timestamp=timestamp)
            return msg
        end

    end
end


function Devices.dev_close(device::T) where {T<:SocketCANDevice}
    SocketCAN.close(device.socketholder.socket)
    return nothing
end


function Devices.dev_status(device::T) where {T<:SocketCANDevice}
    return device.r_status[]
end


end # SocketCANDevices