"""
Abstraction layer for serial port communication.
"""
module SerialHAL

using LibSerialPort


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


end # SerialHAL