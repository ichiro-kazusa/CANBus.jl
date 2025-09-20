"""
Abstraction layer for serial port communication.
"""
module SerialHAL

using LibSerialPort
import LibSerialPort.Lib: libserialport, Port, SPPort, SPReturn, check

const HandleType = LibSerialPort.SerialPort


function open(port::String, baudrate::Integer)::HandleType
    sp = LibSerialPort.open(port, baudrate)
    LibSerialPort.set_flow_control(sp)
    return sp
end


function close(fd::HandleType)
    return LibSerialPort.close(fd)
end


function write(fd::HandleType, msg::String)::Cuint
    r = LibSerialPort.write(fd, msg)
    LibSerialPort.sp_drain(fd)
    return r
end


function nonblocking_read(fd::HandleType)::Vector{UInt8}
    return LibSerialPort.nonblocking_read(fd)
end


function clear_buffer(fd::HandleType)
    LibSerialPort.sp_flush(fd, LibSerialPort.SP_BUF_BOTH)
end


function blocking_read(port::Port, nbytes::Integer, timeout_ms::Integer)
    buffer = zeros(UInt8, nbytes)

    # @threadcall version of sp_blocking_read_next
    # If the read succeeds, the return value is the number of bytes read.
    ret = Threads.@threadcall(
        (:sp_blocking_read_next, libserialport),
        SPReturn,
        (Ptr{SPPort}, Ptr{UInt8}, Csize_t, Cuint),
        port,
        buffer,
        nbytes,
        timeout_ms,
    )
    check(ret)

    if Int64(ret) <= 0
        return UInt8[]
    else
        return buffer
    end
end

end # SerialHAL