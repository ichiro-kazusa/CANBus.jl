module SlcanInterfaces

using LibSerialPort
import ...SerialHAL
import ..Interfaces
import ...Frames

include("slcandef.jl")
import .slcandef

const DELIMITER = '\r'


mutable struct SlcanInterface <: Interfaces.AbstractCANInterface
    sp::SerialPort
    # buffer::Vector{UInt8}
    buffer::String

    function SlcanInterface(channel::String, bitrate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, false, 0)

        new(sp, "")
    end
end


mutable struct SlcanFDInterface{T<:Union{SerialPort,Cint}} <: Interfaces.AbstractCANInterface
    sp::T
    # buffer::Vector{UInt8}
    buffer::String

    function SlcanFDInterface(channel::String, bitrate::Int, datarate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, true, datarate)

        new{typeof(sp)}(sp, "")
    end
end


function _init_slcan(channel::String, bitrate::Int,
    serialbaud::Int, silent::Bool,
    fd::Bool, datarate::Int)

    if !(channel in get_port_list())
        error("Slcan: $channel is not found.")
    end

    sp = SerialHAL.open(channel, serialbaud)

    sleep(1)

    SerialHAL.write(sp, "C" * DELIMITER) # temporary close channel
    sleep(0.1)

    # silent mode
    mode = silent ? "M1" : "M0"
    SerialHAL.write(sp, mode * DELIMITER)

    # set bitrate
    if !haskey(slcandef.BITRATE_DICT, bitrate)
        k = sort(collect(keys(slcandef.BITRATE_DICT)))
        error("Slcan: unsupported bitrate. choose from $k")
    end
    SerialHAL.write(sp, slcandef.BITRATE_DICT[bitrate] * DELIMITER)
    sleep(0.1)

    # set bitrate fd
    if fd
        if !haskey(slcandef.BITRATE_DICT_FD, datarate)
            k = sort(collect(keys(slcandef.BITRATE_DICT_FD)))
            error("Slcan: unsupported datarate. choose from $k")
        end
        SerialHAL.write(sp, slcandef.BITRATE_DICT_FD[datarate] * DELIMITER)
        sleep(0.1)
    end

    # open channel
    SerialHAL.write(sp, "O" * DELIMITER)

    # clear receive buffer
    sleep(0.2) # wait open
    SerialHAL.clear_buffer(sp)

    return sp
end


function Interfaces.send(interface::SlcanInterface, msg::Frames.Frame)

    sendstr::String = ""
    if msg.is_extended
        id = lpad(string(msg.id, base=16), 8, "0")
        sendstr *= ("T" * id)
    else
        id = lpad(string(msg.id, base=16), 3, "0")
        sendstr *= ("t" * id)
    end

    len = string(length(msg))
    data = join(map(x -> lpad(string(x, base=16), 2, "0"), msg.data))
    sendstr *= (len * data * DELIMITER)

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


function Interfaces.recv(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    # read rx buffer & push it to program buffer
    res = SerialHAL.nonblocking_read(interface.sp)
    interface.buffer *= String(res)

    idx = findfirst(c -> c == '\n' || c == '\r', interface.buffer) # delimiter index

    if idx === nothing
        return nothing # queue is empty
    else
        # split token
        token = interface.buffer[1:idx-1] # split before delimiter
        interface.buffer = lstrip(interface.buffer[idx:end],
            ['\n', '\r']) # strip leading delimiter

        if isuppercase(token[1]) # extended
            id = parse(UInt32, token[2:9], base=16)
            len = slcandef.DLC2LEN[UInt8(token[10])]
            data = hex2bytes(token[11:end])

            if token[1] == 'T'
                return Frames.Frame(id, data[1:len], true)
            elseif token[1] == 'D'
                return Frames.FDFrame(id, data[1:len], true, false, false)
            elseif token[1] == 'B'
                return Frames.FDFrame(id, data[1:len], true, true, false)
            else
                return nothing
            end

        elseif islowercase(token[1]) # standard
            id = parse(UInt32, token[2:4], base=16)
            len = slcandef.DLC2LEN[UInt8(token[5])]
            data = hex2bytes(token[6:end])

            if token[1] == 't'
                return Frames.Frame(id, data[1:len], false)
            elseif token[1] == 'd'
                return Frames.FDFrame(id, data[1:len], false, false, false)
            elseif token[1] == 'b'
                return Frames.FDFrame(id, data[1:len], false, true, false)
            else
                return nothing
            end
        end
    end
end


function Interfaces.shutdown(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    SerialHAL.write(interface.sp, "C" * DELIMITER) # close channel
    SerialHAL.close(interface.sp)
    return nothing
end


end # Slcan