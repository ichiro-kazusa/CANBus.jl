module LinuxSerial

using TERMIOS

const T = TERMIOS
const O_RDWR = Cint(2)
const O_NOCTTY = 0x0800
const O_NONBLOCK = 0x0080
const B115200 = 0x00001002
const PARENB = 0x00000100
const CSTOPB = 0x00000040
const CSIZE = 0x00000030
const CS8 = 0x00000030
const CRTSCTS = 0x80000000
const CLOCAL = 0x00000800
const CREAD = 0x00000080
const ICANON = 0x00002
const ECHO = 0x00008
const ECHOE = 0x00010
const ISIG = 0x00001
const IXON = 0x0400
const IXOFF = 0x1000
const IXANY = 0x800
const OPOST = 0x01
const TCSANOW = 0
const TCIFLUSH = 0 #/* Discard data received but not yet read */
const TCOFLUSH = 1 #/* Discard data written but not yet sent */
const TCIOFLUSH = 2 #/* Discard all pending data */


const BAUDRATE = Dict([
    115200 => B115200
])

##########################################
# functions 
##########################################


function open(portname::String, baudrate::Integer)::Cint

    tio = T.termios()

    fd = ccall(:open, Cint, (Ptr{Cchar}, Cint),
        portname, O_RDWR | O_NOCTTY | O_NONBLOCK)

    T.tcgetattr(Libc.RawFD(fd), tio)

    brate = BAUDRATE[baudrate]

    T.cfsetospeed(tio, brate)
    T.cfsetispeed(tio, brate)

    tio.c_cflag &= ~PARENB # no parity
    tio.c_cflag &= ~CSTOPB # stopbit=1
    tio.c_cflag &= ~CSIZE
    tio.c_cflag |= CS8 # databit=8
    tio.c_cflag &= ~CRTSCTS # no hardware flows
    tio.c_cflag |= (CLOCAL | CREAD)

    tio.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG) # low level input
    tio.c_iflag &= ~(IXON | IXOFF | IXANY)         # no software flow control
    tio.c_oflag &= ~OPOST                          # raw output

    T.tcsetattr(Libc.RawFD(fd), TCSANOW, tio)

    flushio(fd) # clear i/o buffer

    return fd
end


function close(fd::Cint)
    ccall(:close, Cint, (Cint,), fd)
end


function flushio(fd::Cint)
    ccall(:tcflush, Cint, (Cint, Cint), fd, TCIOFLUSH)
end


function drain(fd::Cint)
    ccall(:tcdrain, Cint, (Cint,), fd)
end


function write(fd::Cint, msg::String)
    ccall(:write, Cint, (Cint, Ptr{Cuchar}, Cuint), fd, msg, length(msg))
end


function nonblocking_read(fd::Cint)::Vector{UInt8}
    totbuf = UInt8[]
    buf = zeros(Cuchar, 1)
    pbuf = Ref(buf, 1)
    while true
        r = ccall(:read, Cint, (Cint, Ptr{Cuchar}, Cuint), fd, pbuf, 1)
        r > 0 ? append!(totbuf, buf[1:r]) : break
    end

    return totbuf
end


end # LinuxSerial