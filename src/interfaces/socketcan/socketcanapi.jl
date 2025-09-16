"Low level API for SocketCAN"
module SocketCAN


########################################
# typdefs
########################################
const socklen_t = Cuint

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
const CAN_RTR_FLAG = UInt32(0x40000000)
const CAN_ERR_FLAG = UInt32(0x20000000)
const SOL_CAN_BASE = Cint(100)
const SOL_CAN_RAW = SOL_CAN_BASE + CAN_RAW
const SOL_SOCKET = Cint(1)
const SO_TIMESTAMPNS_NEW = Cint(64)
const CAN_RAW_FILTER = Cint(1)
const CAN_RAW_FD_FRAMES = Cint(5)
#/*
# * defined bits for canfd_frame.flags
# */
const CANFD_BRS::UInt8 = 0x01 #/* bit rate switch (second bitrate for payload data) */
const CANFD_ESI::UInt8 = 0x02 #/* error state indicator of the transmitting node */
const CANFD_FDF::UInt8 = 0x04 #/* mark CAN FD for dual use of struct canfd_frame */

const EAGAIN = 11

########################################
# structs
########################################
struct ifreq
    ifr_ifrn::NTuple{16,Cchar}
    ifr_ifru::NTuple{16,Cchar}
end

struct sockaddr_can # 19 bytes
    can_family::Cushort
    can_ifindex::Cint
    can_addr::NTuple{13,Cchar}
end

struct can_frame # 16 bytes
    can_id::UInt32
    len::UInt8
    __pad::UInt8
    __res0::UInt8
    len8_dlc::UInt8
    data::NTuple{8,UInt8}
end

struct canfd_frame # 72 bytes
    can_id::UInt32
    len::UInt8
    flags::UInt8
    __res0::UInt8
    __res1::UInt8
    data::NTuple{64,UInt8}
end

struct can_filter # 8 bytes
    can_id::UInt32
    can_mask::UInt32
end

struct timespec
    tv_sec::Clong
    tv_nsec::Clong
end

struct iovec
    iov_base::Ptr{Cvoid}
    iov_len::Csize_t
end

struct msghdr
    msg_name::Ptr{Cvoid}
    msg_namelen::socklen_t
    msg_iov::Ptr{iovec}
    msg_iovlen::Csize_t
    msg_control::Ptr{Cvoid}
    msg_controllen::Csize_t
    msg_flags::Cint
end

struct cmsghdr
    cmsg_len::Csize_t
    cmsg_level::Cint
    cmsg_type::Cint
end

########################################
# function wrappers
########################################
function socket(domain::Cint, type::Cint, protocol::Cint)::Cint
    ccall(:socket, Cint, (Cint, Cint, Cint), domain, type, protocol)
end

function ioctl(fd::Cint, cmd::Cint, arg::Base.RefValue{ifreq})::Cint
    # ioctl to set ifreq
    ccall(:ioctl, Cint, (Cint, Cint, Ptr{ifreq}), fd, cmd, arg)
end

function bind(socket::Cint, address::Ref{sockaddr_can}, address_len::Cuint)::Cint
    ccall(:bind, Cint, (Cint, Ptr{sockaddr_can}, Cuint), socket, address, address_len)
end

function write(socket::Cint, pframe::Ref{T},
    len::Cuint)::Clong where T<:Union{can_frame,canfd_frame}
    ccall(:write, Clong, (Cint, Ptr{T}, Cuint),
        socket, pframe, len)
end

function read(socket::Cint, pframe::Ref{T},
    len::Cuint)::Clong where T<:Union{can_frame,canfd_frame}

    ccall(:read, Clong, (Cint, Ptr{T}, Cuint),
        socket, pframe, len)
end

function close(socket::Cint)::Cint
    ccall(:close, Cint, (Cint,), socket)
end

function setsockopt(socket::Cint, level::Cint, optionname::Cint,
    optionvalue::Base.RefArray{can_filter,Vector{can_filter},Nothing},
    optionlength::Cuint)::Cint

    # setsockopt for add filters
    ccall(:setsockopt, Cint,
        (Cint, Cint, Cint, Ptr{Cvoid}, Cuint),
        socket, level, optionname, optionvalue, optionlength)
end

function setsockopt(socket::Cint, level::Cint, optionname::Cint,
    optionvalue::Base.RefValue{Cint}, optionlength::Cuint)::Cint

    ccall(:setsockopt, Cint,
        (Cint, Cint, Cint, Ptr{Cvoid}, Cuint),
        socket, level, optionname, optionvalue, optionlength)
end

function recvmsg(socket::Cint, pmsg::Ref{msghdr},
    flag::Cint)::Cssize_t

    ccall(:recvmsg, Cssize_t,
        (Cint, Ptr{msghdr}, Cint),
        socket, pmsg, flag)
end

end # Socketcanapi