module SocketcanInterfaces

using CANalyze
import ..Interfaces

include("socketcanapi.jl")
import .SocketCAN



"""
    SocketcanInterface(channel::String)

Setup SocketCAN interface with channel name.
"""
struct SocketcanInterface <: Interfaces.AbstractCANInterface
    socket::Cint

    function SocketcanInterface(channel::String)
        # open socket
        s = SocketCAN.socket(SocketCAN.PF_CAN,
            SocketCAN.SOCK_RAW | SocketCAN.SOCK_NONBLOCK, SocketCAN.CAN_RAW)
        if s < 0
            error("SocketCAN: socket could not open.")
        end

        # ioctl
        ifname = Vector{Cchar}(codeunits(channel))
        ifname_pad = vcat(ifname, zeros(Cchar, 16 - length(ifname)))
        ifr = SocketCAN.ifreq(ifname_pad, zeros(Cchar, 16))
        pifr = Ref(ifr)
        io = SocketCAN.ioctl(s, SocketCAN.SIOCGIFINDEX, pifr)
        if io <0
            error("SocketCAN: $channel is not found.")
        end

        # bind
        ptr = Base.unsafe_convert(Ptr{Cint}, pointer(pifr[].ifr_ifru))
        ifr_ifindex = unsafe_load(ptr)
        addr = SocketCAN.sockaddr_can(SocketCAN.AF_CAN, ifr_ifindex,
            zeros(Cchar, 13))
        paddr = Ref(addr)
        b = SocketCAN.bind(s, paddr, Cuint(19))
        if b < 0
            error("SocketCAN: bind error.")
        end

        new(s)
    end
end


function Interfaces.send(interface::SocketcanInterface,
    frame::CANalyze.CANFrame)::Nothing

    id = frame.is_extended ? frame.frame_id | SocketCAN.CAN_EFF_FLAG : frame.frame_id
    dlc = size(frame.data, 1)
    data = zeros(UInt8, 8)
    data[1:dlc] .= frame.data
    frame = SocketCAN.can_frame(id, dlc, 0, 0, 0, data)
    pframe = Ref(frame)
    written = SocketCAN.write(interface.socket, pframe, Cuint(16))

    if written != Cuint(16)
        error("SocketCAN: Failed to transmit.")
    end
    return nothing
end


function Interfaces.recv(interface::SocketcanInterface)::Union{Nothing,CANalyze.CANFrame}
    frame_r = SocketCAN.can_frame(0, 0, 0, 0, 0, zeros(Cchar, 8)) # empty frame
    pframe_r = Ref(frame_r)
    nbytes = SocketCAN.read(interface.socket, pframe_r, Cuint(16))
    if nbytes >= 0
        rawid = pframe_r[].can_id
        isext = (rawid & SocketCAN.CAN_EFF_FLAG) != 0
        id = isext ? rawid - SocketCAN.CAN_EFF_FLAG : rawid
        dlc = pframe_r[].len
        frame = CANalyze.CANFrame(
            id,
            pframe_r[].data[1:dlc],
            is_extended=isext
        )
        return frame
    end
    return nothing
end


function Interfaces.shutdown(interface::SocketcanInterface)
    SocketCAN.close(interface.socket)
end


end # SocketcanInterfaces