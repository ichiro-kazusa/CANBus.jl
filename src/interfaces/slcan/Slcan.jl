module SlcanInterfaces

using LibSerialPort
import ...SerialHAL
import ..Interfaces
import ...Frames

include("slcandef.jl")
import .slcandef

const DELIMITER = '\r'

"""
    slcan0 = SlcanInterface(port::String, bitrate::Integer)

slcan is a CAN over serial protocol by CANable.
This version is tested on CANable 2.0.

!!! note

    `slcan` with FD firmware (b158aa7) is seemd to be always on FD mode,
    thus there is no **pure CAN** mode. Therefore, this interface exceptionally receives
    `FDFrame` when someone sends that.

* port: port name string e.g. `COM3` on Windows,  `/dev/ttyACM0` on Linux.
* bitrate: bit rate in bit/s
* silent(optional): listen only flag in bool.
"""
mutable struct SlcanInterface <: Interfaces.AbstractCANInterface
    sp::SerialHAL.HandleType
    buffer::String

    function SlcanInterface(channel::String, bitrate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, false, 0)

        new(sp, "")
    end
end


"""
    slcan0 = SlcanFDInterface(port::String, bitrate::Integer, datarate::Integer)

slcan is a CAN over serial protocol by CANable.
This version is tested on CANable 2.0.
This interface supports send CAN FD frame.

* port: port name string.
* bitrate: bit rate in bit/s
* datarate: data rate in bit/s
* silent(optional): listen only flag in bool.
"""
mutable struct SlcanFDInterface <: Interfaces.AbstractCANInterface
    sp::SerialHAL.HandleType
    buffer::String

    function SlcanFDInterface(channel::String, bitrate::Int, datarate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, true, datarate)

        new(sp, "")
    end
end


function _init_slcan(channel::String, bitrate::Int,
    serialbaud::Int, silent::Bool,
    fd::Bool, datarate::Int)::SerialHAL.HandleType


    # check arguments
    # bitrate
    if !haskey(slcandef.BITRATE_DICT, bitrate)
        k = sort(collect(keys(slcandef.BITRATE_DICT)))
        error("Slcan: unsupported bitrate. choose from $k")
    end
    # datarate
    if fd
        if !haskey(slcandef.BITRATE_DICT_FD, datarate)
            k = sort(collect(keys(slcandef.BITRATE_DICT_FD)))
            error("Slcan: unsupported datarate. choose from $k")
        end
    end

    if !(channel in get_port_list())
        error("Slcan: $channel is not found.")
    end

    # open port
    sp = SerialHAL.open(channel, serialbaud)

    SerialHAL.write(sp, "C" * DELIMITER) # temporary close channel

    # silent mode
    mode = silent ? "M1" : "M0"
    SerialHAL.write(sp, mode * DELIMITER)

    # set bitrate
    SerialHAL.write(sp, slcandef.BITRATE_DICT[bitrate] * DELIMITER)

    # set datarate fd
    if fd
        SerialHAL.write(sp, slcandef.BITRATE_DICT_FD[datarate] * DELIMITER)
    end

    # open channel
    SerialHAL.write(sp, "O" * DELIMITER)

    # clear receive buffer
    SerialHAL.clear_buffer(sp)

    return sp
end


function Interfaces.send(interface::T, msg::Frames.Frame) where {T<:Union{SlcanInterface,SlcanFDInterface}}

    sendstr::String = ""
    len = string(length(msg))
    data = join(map(x -> lpad(string(x, base=16), 2, "0"), msg.data))

    if msg.is_extended
        id = lpad(string(msg.id, base=16), 8, "0")
        if msg.is_remote_frame
            sendstr *= ("R" * id * len)
        else
            sendstr *= ("T" * id * len * data)
        end
    else
        id = lpad(string(msg.id, base=16), 3, "0")
        if msg.is_remote_frame
            sendstr *= ("r" * id * len)
        else
            sendstr *= ("t" * id * len * data)
        end
    end

    sendstr *= DELIMITER
    SerialHAL.write(interface.sp, sendstr)

end


function Interfaces.send(interface::SlcanFDInterface, msg::Frames.FDFrame)

    sendstr::String = ""
    if msg.is_extended
        header = msg.bitrate_switch ? "B" : "D"
        id = lpad(string(msg.id, base=16), 8, "0")
        sendstr *= (header * id)
    else
        header = msg.bitrate_switch ? "b" : "d"
        id = lpad(string(msg.id, base=16), 3, "0")
        sendstr *= (header * id)
    end

    dlc = slcandef.LEN2DLC[length(msg)]
    data = join(map(x -> lpad(string(x, base=16), 2, "0"), msg.data))
    sendstr *= (dlc * data * DELIMITER)

    SerialHAL.write(interface.sp, sendstr)

end


function Interfaces.recv(interface::T)::Union{Nothing,Frames.Frame,Frames.FDFrame} where {T<:Union{SlcanInterface,SlcanFDInterface}}
    # read rx buffer & push it to program buffer
    res = SerialHAL.nonblocking_read(interface.sp)
    interface.buffer *= String(res)

    idx = findfirst(c -> c == '\n' || c == '\r', interface.buffer) # delimiter index

    if idx === nothing
        return nothing # queue is empty or incomplete
    else
        # split token
        timestamp = time() # slcan has no device timestamp, therefore system time is used.
        token = interface.buffer[1:idx-1] # split before delimiter
        interface.buffer = lstrip(interface.buffer[idx:end],
            ['\n', '\r']) # strip leading delimiter

        if isuppercase(token[1]) # extended
            id = parse(UInt32, token[2:9], base=16)
            len = slcandef.DLC2LEN[UInt8(token[10])]
            data = hex2bytes(token[11:end])

            if token[1] == 'T'
                return Frames.Frame(id, data[1:len]; is_extended=true, timestamp=timestamp)
            elseif token[1] == 'R'
                return Frames.Frame(id, data[1:len]; is_extended=true, is_remote_frame=true, timestamp=timestamp)
            elseif token[1] == 'D'
                return Frames.FDFrame(id, data[1:len]; is_extended=true, bitrate_switch=false, timestamp=timestamp)
            elseif token[1] == 'B'
                return Frames.FDFrame(id, data[1:len]; is_extended=true, timestamp=timestamp)
            else
                return nothing
            end

        elseif islowercase(token[1]) # standard
            id = parse(UInt32, token[2:4], base=16)
            len = slcandef.DLC2LEN[UInt8(token[5])]
            data = hex2bytes(token[6:end])

            if token[1] == 't'
                return Frames.Frame(id, data[1:len], timestamp=timestamp)
            elseif token[1] == 'r'
                return Frames.Frame(id, data[1:len]; is_remote_frame=true, timestamp=timestamp)
            elseif token[1] == 'd'
                return Frames.FDFrame(id, data[1:len]; bitrate_switch=false, timestamp=timestamp)
            elseif token[1] == 'b'
                return Frames.FDFrame(id, data[1:len], timestamp=timestamp)
            else
                return nothing
            end
        else
            return nothing
        end
    end
end


function Interfaces.shutdown(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    SerialHAL.write(interface.sp, "C" * DELIMITER) # close channel
    SerialHAL.close(interface.sp)
    return nothing
end


end # Slcan