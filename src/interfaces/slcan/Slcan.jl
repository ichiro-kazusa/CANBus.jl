module SlcanInterfaces

using LibSerialPort
import ..Interfaces
import ...Frames

include("slcandef.jl")
import .slcandef

const DELIMITER = "\r"


struct SlcanInterface <: Interfaces.AbstractCANInterface
    sp::SerialPort

    function SlcanInterface(channel::String, bitrate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, false, 0)

        new(sp)
    end
end


struct SlcanFDInterface <: Interfaces.AbstractCANInterface
    sp::SerialPort

    function SlcanFDInterface(channel::String, bitrate::Int, datarate::Int;
        serialbaud::Int=115200, silent::Bool=false)

        sp = _init_slcan(channel, bitrate, serialbaud, silent, true, datarate)

        new(sp)
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

    # silent mode
    mode = silent ? "M1" : "M0"
    write(sp, mode * DELIMITER)

    # open channel
    write(sp, "O" * DELIMITER)
    flush(sp)

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


function Interfaces.shutdown(interface::T) where {T<:Union{SlcanInterface,SlcanFDInterface}}
    write(interface.sp, "C" * DELIMITER) # close channel
    LibSerialPort.close(interface.sp)
    return nothing
end


end # Slcan