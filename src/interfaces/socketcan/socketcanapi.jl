"Low level API for SocketCAN"
module SocketCAN

using StaticArrays

########################################
# definitions
########################################
const PF_CAN = Cint(29)
const AF_CAN = Cint(29)
const SOCK_RAW = Cint(3)
const SOCK_NONBLOCK = Cint(0o4000)
const CAN_RAW = Cint(1)
const SIOCGIFINDEX = Cint(0x8933)
const CAN_EFF_FLAG = UInt32(0x80000000)

########################################
# structs
########################################
struct ifreq
    ifr_ifrn::SVector{16,Cchar}
    ifr_ifru::SVector{16,Cchar}
end

struct sockaddr_can # 19 bytes
    can_family::Cushort
    can_ifindex::Cint
    can_addr::SVector{13,Cchar}
end

struct can_frame # 16 bytes
    can_id::UInt32
    len::UInt8
    __pad::UInt8
    __res0::UInt8
    len8_dlc::UInt8
    data::SVector{8,UInt8}
end


########################################
# function wrappers
########################################
function socket(domain::Cint, type::Cint, protocol::Cint)::Cint
    ccall(:socket, Cint, (Cint, Cint, Cint), domain, type, protocol)
end

function ioctl(fd::Cint, cmd::Cint, arg::Base.RefValue{ifreq})::Cint
    ccall(:ioctl, Cint, (Cint, Cint, Ptr{ifreq}), fd, cmd, arg)
end

function bind(socket::Cint, address::Ref{sockaddr_can}, address_len::Cuint)::Cint
    ccall(:bind, Cint, (Cint, Ptr{sockaddr_can}, Cuint), socket, address, address_len)
end

function write(socket::Cint, pframe::Ref{can_frame}, len::Cuint)::Clong
    ccall(:write, Clong, (Cint, Ptr{can_frame}, Cuint),
        socket, pframe, len)
end

function read(socket::Cint, pframe::Ref{can_frame}, len::Cuint)::Clong
    ccall(:read, Clong, (Cint, Ptr{can_frame}, Cuint),
        socket, pframe, len)
end

function close(socket::Cint)::Cint
    ccall(:close, Cint, (Cint,), socket)
end


end # Socketcanapi