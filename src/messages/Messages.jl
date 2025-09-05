module Messages

using CANalyze
using StaticArrays


abstract type AbstractCANMessage end


struct CANMessage <: AbstractCANMessage
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool

    function CANMessage(id::IT, data::V, is_extended::Bool) where {IT<:Integer,V<:AbstractVector}
        @assert length(data) <= 8 "Length of CAN Message must be <= 8."
        new(id, data, is_extended)
    end
end

function CANMessage(frm::CANalyze.CANFrame)
    CANMessage(frm.frame_id, frm.data, frm.is_extended)
end

function Base.convert(::Type{CANalyze.CANFrame}, msg::CANMessage)
    CANalyze.CANFrame(msg.id, msg.data; is_extended=msg.is_extended)
end


const capable_dlc_over8 = [12, 16, 20, 24, 32, 48, 64]

struct CANFDMessage <: AbstractCANMessage
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool
    bitrate_switch::Bool
    error_state::Bool

    function CANFDMessage(id::IT, data::V, is_extended::Bool,
        bitrate_switch::Bool, error_state::Bool) where {IT<:Integer,V<:AbstractVector}

        @assert length(data) <= 64 "Length of CAN FD Message must be <= 64."
        @assert length(data) <= 8 || in(length(data), capable_dlc_over8) "Invalid data length."
        new(id, data, is_extended, bitrate_switch, error_state)
    end
end

function CANFDMessage(frm::CANalyze.CANFdFrame, bitrate_switch::Bool)
    CANFDMessage(frm.frame_id, frm.data, frm.is_extended, bitrate_switch, false)
end


function Base.convert(::Type{CANalyze.CANFdFrame}, msg::CANFDMessage)
    CANalyze.CANFdFrame(msg.id, msg.data; is_extended=msg.is_extended)
end


function Base.:(==)(msg1::T, msg2::T) where {T<:AbstractCANMessage}
    res::Bool = true
    for n in fieldnames(T)
        res &= getproperty(msg1, n) == getproperty(msg2, n)
    end
    res
end


function Base.length(msg::T) where {T<:AbstractCANMessage}
    length(msg.data)
end


end # Messagesa