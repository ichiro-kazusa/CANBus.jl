"""
Abstraction layer for serial port communication.
This uses `LinuxSerial` module on Linux, `LibSerialPort` on others.
"""
module SerialHAL

using LibSerialPort
import ..LinuxSerial


function open(port::String, baudrate::Integer)::Union{SerialPort,Cint}
    @static if Sys.islinux()
        fd = LinuxSerial.open(port, baudrate)
        return fd
    else
        sp = LibSerialPort.open(port, baudrate)
        return sp
    end
end


function close(fd::T) where {T<:Union{Union{SerialPort,Cint}}}
    @static if Sys.islinux()
        return LinuxSerial.close(fd)
    else
        return LibSerialPort.close(fd)
    end
end


function write(fd::T, msg::String) where {T<:Union{Union{SerialPort,Cint}}}
    @static if Sys.islinux()
        r = LinuxSerial.write(fd, msg)
        LinuxSerial.drain(fd)
        return r
    else
        r = LibSerialPort.write(fd, msg)
        Base.flush(fd)
        return r
    end
end


function nonblocking_read(fd::T) where {T<:Union{Union{SerialPort,Cint}}}
    @static if Sys.islinux()
        return LinuxSerial.nonblocking_read(fd)
    else
        return LibSerialPort.nonblocking_read(fd)
    end
end


function clear_buffer(fd::T) where {T<:Union{Union{SerialPort,Cint}}}
    @static if Sys.islinux()
        LinuxSerial.flushio(fd)
    else
        LibSerialPort.sp_flush(fd, LibSerialPort.SP_BUF_BOTH)
    end
end

end # SerialHAL