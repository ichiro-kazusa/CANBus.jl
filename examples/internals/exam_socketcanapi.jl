using StaticArrays
import CAN.Interfaces.SocketcanInterfaces: SocketCAN as SocketCAN


"""
example program to check internal low-level api "CAN.Interfaces.SocketcanInterfaces.Socketcanapi"
"""
function main()
    s = SocketCAN.socket(SocketCAN.PF_CAN, SocketCAN.SOCK_RAW | SocketCAN.SOCK_NONBLOCK, SocketCAN.CAN_RAW)
    if s < 0
        error("SocketCAN: socket could not open.")
    end

    ifname = Vector{Cchar}(codeunits("vcan0"))
    ifname_pad = vcat(ifname, zeros(Cchar, 16 - length(ifname)))
    ifr = SocketCAN.ifreq(ifname_pad, zeros(Cchar, 16))
    pifr = Ref(ifr)
    SocketCAN.ioctl(s, SocketCAN.SIOCGIFINDEX, pifr)
    ptr = Base.unsafe_convert(Ptr{Cint}, pointer(pifr[].ifr_ifru))
    ifr_ifindex = unsafe_load(ptr)

    addr = SocketCAN.sockaddr_can(SocketCAN.AF_CAN, ifr_ifindex, zeros(Cchar, 13))
    paddr = Ref(addr)
    b = SocketCAN.bind(s, paddr, Cuint(19))
    println(b)

    frame = SocketCAN.can_frame(0x555, 5, 0, 0, 0, [1, 2, 3, 4, 5, 0, 0, 0])
    pframe = Ref(frame)
    written = SocketCAN.write(s, pframe, Cuint(16))

    sleep(3)

    frame_r = SocketCAN.can_frame(0, 0, 0, 0, 0, zeros(Cchar, 8))
    pframe_r = Ref(frame_r)
    nbytes = SocketCAN.read(s, pframe_r, Cuint(16))
    if nbytes >= 0
        println(pframe_r[])
    end

    SocketCAN.close(s)

end

main()