module SlcanDevices

import ..Devices
import ....InterfaceCfgs
import ....Frames
import ....misc: SerialHAL


include("slcandef.jl")
import .slcandef

const DELIMITER = '\r'

"""
    SlcanDevice(port::String, bitrate::Integer)

Struct to store SLCAN device handle and buffer.
"""
mutable struct SlcanDevice{T<:Devices.AbstractBusType} <: Devices.AbstractDevice{T}
    sp::SerialHAL.HandleType
    stdfilter::Vector{NTuple{2, UInt32}}
    extfilter::Vector{NTuple{2, UInt32}}
    buffer::String
end


function Devices.dev_open(::Val{InterfaceCfgs.SLCAN}, cfg::InterfaceCfgs.InterfaceConfig)
    sp = _init_slcan(cfg.channel, cfg.bitrate, cfg.slcan_serialbaud, cfg.silent,
        InterfaceCfgs.helper_isfd(cfg), cfg.datarate)

    bustype = Devices.helper_bustype(cfg)

    stdfilter = _init_filter(cfg.stdfilter)
    extfilter = _init_filter(cfg.extfilter)

    SlcanDevice{bustype}(sp, stdfilter, extfilter, "")

end


#= convert AcceptanceFilter to (mask, rhs) =#
function _init_filter(filter::Union{Nothing,InterfaceCfgs.AcceptanceFilter,Vector{InterfaceCfgs.AcceptanceFilter}})::Vector{NTuple{2, UInt32}}
    if filter === nothing
        return []
    elseif isa(filter, InterfaceCfgs.AcceptanceFilter)
        filter = [filter]
    end

    return [(f.mask, f.code_id & f.mask) for f in filter]
end


function _init_slcan(channel::String, bitrate::Int,
    serialbaud::Int, silent::Bool,
    fd::Bool, datarate::Union{Nothing,Int})::SerialHAL.HandleType

    # cleanup unreferenced handle
    GC.gc()

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

    if !(channel in SerialHAL.LibSerialPort.get_port_list())
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


function Devices.dev_send(driver::SlcanDevice{T}, msg::Frames.Frame) where {T<:Devices.AbstractBusType}

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
    SerialHAL.write(driver.sp, sendstr)

end


function Devices.dev_send(driver::SlcanDevice{Devices.BUS_FD}, msg::Frames.FDFrame)

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

    SerialHAL.write(driver.sp, sendstr)

end


#= apply filter and retruns accept flag =#
function _apply_filter(id::UInt32, filter::Vector{NTuple{2, UInt32}})
    if length(filter) == 0
        return true
    else
        return any([id & mask == rhs for (mask, rhs) in filter])
    end
end


function Devices.dev_recv(device::SlcanDevice; timeout_s::Real=0)::Union{Nothing,Frames.AnyFrame}

    # non-blocking read before poll
    res = SerialHAL.nonblocking_read(device.sp)
    device.buffer *= String(res)

    # poll
    if timeout_s != 0 && length(device.buffer) == 0
        # timeout_s < 0(inf) -> pass 0ms(inf)
        timeout_ms = timeout_s < 0 ? 0 : Cint(timeout_s * 1e3)
        buf = SerialHAL.blocking_read(device.sp.ref, 1, timeout_ms)
        device.buffer *= String(buf)
    end

    # start buffer parsing
    idx = findfirst(c -> c == '\n' || c == '\r', device.buffer) # delimiter index

    if idx === nothing
        return nothing # queue is empty or incomplete
    else
        # split token
        timestamp = time() # slcan has no device timestamp, therefore system time is used.
        token = device.buffer[1:idx-1] # split before delimiter
        device.buffer = lstrip(device.buffer[idx:end],
            ['\n', '\r']) # strip leading delimiter

        if isuppercase(token[1]) # extended
            id = parse(UInt32, token[2:9], base=16)
            if !_apply_filter(id, device.extfilter)
                return nothing # filter rejects id
            end
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
            if !_apply_filter(id, device.stdfilter)
                return nothing # filter rejects id
            end
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


function Devices.dev_close(driver::SlcanDevice)
    SerialHAL.write(driver.sp, "C" * DELIMITER) # close channel
    SerialHAL.close(driver.sp)
    return nothing
end


end # Slcan