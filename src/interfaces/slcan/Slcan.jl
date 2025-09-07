module SlcanInterfaces

using LibSerialPort
import ..Interfaces
import ...Frames

include("slcandef.jl")
import .slcandef

const DELIMITER = "\r"


mutable struct SlcanInterface <: Interfaces.AbstractCANInterface
    sp::SerialPort
    buffer::Vector{UInt8}

    function SlcanInterface(channel::String, bitrate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, false, 0)

        new(sp, [])
    end
end


mutable struct SlcanFDInterface <: Interfaces.AbstractCANInterface
    sp::SerialPort
    buffer::Vector{UInt8}

    function SlcanFDInterface(channel::String, bitrate::Int, datarate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, true, datarate)

        new(sp, [])
    end
end


function _init_slcan(channel::String, bitrate::Int,
    serialbaud::Int, silent::Bool,
    fd::Bool, datarate::Int)

    if !(channel in get_port_list())
        error("Slcan: $channel is not found.")
    end

    sp = LibSerialPort.open(channel, serialbaud)

    write(sp, "C" * DELIMITER) # temporary close channel

    # silent mode
    mode = silent ? "M1" : "M0"
    write(sp, mode * DELIMITER)

    # set bitrate
    if !haskey(slcandef.BITRATE_DICT, bitrate)
        k = sort(collect(keys(slcandef.BITRATE_DICT)))
        error("Slcan: unsupported bitrate. choose from $k")
    end
    write(sp, slcandef.BITRATE_DICT[bitrate] * DELIMITER)

    # set bitrate fd
    if fd
        if !haskey(slcandef.BITRATE_DICT_FD, datarate)
            k = sort(collect(keys(slcandef.BITRATE_DICT_FD)))
            error("Slcan: unsupported datarate. choose from $k")
        end
        write(sp, slcandef.BITRATE_DICT_FD[datarate] * DELIMITER)
    end

    # open channel
    write(sp, "O" * DELIMITER)
    flush(sp)

    # clear receive buffer
    sleep(0.1) # wait open
    nonblocking_read(sp)

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

    write(interface.sp, sendstr)
    flush(interface.sp)

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

    write(interface.sp, sendstr)
    flush(interface.sp)

end


function Interfaces.recv(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    # read rx buffer & push it to program buffer
    res = nonblocking_read(interface.sp)
    append!(interface.buffer, res)

    idx = findfirst(x -> x == 0x0d, interface.buffer) # delimiter index

    if idx === nothing
        return nothing # queue is empty
    else
        # split token
        token = interface.buffer[1:idx]
        interface.buffer = interface.buffer[idx+1:end]

        if 0x41 <= token[1] <= 0x5a # extended

            id = parse(UInt32, String(token[2:9]), base=16)
            len = slcandef.DLC2LEN[token[10]]
            data = hex2bytes(String(token[11:end-1]))

            if token[1] == 0x54 # T
                return Frames.Frame(id, data[1:len], true)
            elseif token[1] == 0x44 # D
                return Frames.FDFrame(id, data[1:len], true, false, false)
            elseif token[1] == 0x42 # B
                return Frames.FDFrame(id, data[1:len], true, true, false)
            else
                return nothing
            end

        elseif 0x61 <= token[1] <= 0x7a # standard

            id = parse(UInt32, String(token[2:4]), base=16)
            len = slcandef.DLC2LEN[token[5]]
            data = hex2bytes(String(token[6:end-1]))

            if token[1] == 0x74 # t
                return Frames.Frame(id, data[1:len], false)
            elseif token[1] == 0x64 # d
                return Frames.FDFrame(id, data[1:len], false, false, false)
            elseif token[1] == 0x62 # b
                return Frames.FDFrame(id, data[1:len], false, true, false)
            else
                return nothing
            end
        end
    end
end


function Interfaces.shutdown(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    write(interface.sp, "C" * DELIMITER) # close channel
    LibSerialPort.close(interface.sp)
    return nothing
end


end # Slcan