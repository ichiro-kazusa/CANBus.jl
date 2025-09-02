module Messages

using CANalyze
using StaticArrays


abstract type AbstractCANMessage end


struct CANMessage
    id::UInt32
    dlc::UInt32
    data::Vector{UInt8}
    is_extended::Bool
end

function CANMessage(frm::CANalyze.CANFrame)
    id = frm.frame_id
    dlc = length(frm.data)
    data = zeros(UInt8, 8)
    data[1:dlc] .= frm.data
    CANMessage(id, dlc, data, frm.is_extended)
end

function Base.convert(::Type{CANalyze.CANFrame}, msg::CANMessage)
    data = msg.data[1:msg.dlc]
    CANalyze.CANFrame(msg.id, data; is_extended=msg.is_extended)
end



struct CANFDMessage
    id::UInt32
    bytes::UInt32
    data::Vector{UInt8}
    is_extended::Bool
    bitrate_switch::Bool
    error_state::Bool
end

function CANFDMessage(frm::CANalyze.CANFdFrame, bitrate_switch::Bool)
    id = frm.frame_id
    bytes = length(frm.data)
    data = zeros(UInt8, 64)
    data[1:bytes] .= frm.data
    CANFDMessage(id, bytes, data, frm.is_extended, bitrate_switch, false)
end

function Base.convert(::Type{CANalyze.CANFdFrame}, msg::CANFDMessage)
    data = msg.data[1:msg.bytes]
    CANalyze.CANFdFrame(msg.id, data; is_extended=msg.is_extended)
end


end # Messagesa