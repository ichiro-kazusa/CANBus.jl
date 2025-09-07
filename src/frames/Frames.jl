module Frames

using CANalyze
using StaticArrays


"""Abstract type for Frames."""
abstract type AbstractFrame end


"""
    CANBus.Frame(id::Integer, data::AbstractVector, is_extended:Bool)

Frame struct represents classic (8bytes) CAN frame.

* `id`: arbitration id
* `data`: Vector of Integer with length <= 8. If input has element > 255, throws error.
* `is_extended`: Flag which arbitration id is extended.

```jl
frame = CANBus.Frame(0x5, [1, 2, 3, 4, 5, 6, 7, 8], true)
```
"""
struct Frame <: AbstractFrame
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool

    function Frame(id::IT, data::V, is_extended::Bool) where {IT<:Integer,V<:AbstractVector}
        _check_id(id, is_extended) # id must be in specific range.
        @assert length(data) <= 8 "Length of CAN Message must be <= 8."
        new(id, data, is_extended)
    end
end


function Frame(frm::CANalyze.CANFrame)
    Frame(frm.frame_id, frm.data, frm.is_extended)
end


function CANalyze.Frames.CANFrame(frame::Frame)
    CANalyze.CANFrame(frame.id, frame.data; is_extended=frame.is_extended)
end


function _check_id(id::Integer, is_extended::Bool)
    if is_extended
        @assert 0x0 <= id <= 0x1FFFFFFF
    else
        @assert 0x0 <= id <= 0x7FF
    end
end

const capable_dlc_over8 = [12, 16, 20, 24, 32, 48, 64]

"""
    CANBus.FDFrame(id::Integer, data::AbstractVector, is_extended::Bool,
        bitrate_switch::Bool, error_state::Bool)

FDFrame struct represents CAN FD (64bytes) frame.

* `id`: arbitration id
* `data`: Vector of Integer. Length must be in CAN FD DLC standard. Elements must not be > 255.
* `is_extended`: Flag which arbitration id is extended.
* `bitrate_switch`: Flag to use `bitrate_switch`.
* `error_state`: Flag corresponds to `error_state_indicator`.
    This is used in receiving, so that it is ignore in transmitting (always treat as =false).
"""
struct FDFrame <: AbstractFrame
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool
    bitrate_switch::Bool
    error_state::Bool

    function FDFrame(id::IT, data::V, is_extended::Bool,
        bitrate_switch::Bool, error_state::Bool) where {IT<:Integer,V<:AbstractVector}

        _check_id(id, is_extended) # id must be in specific range.
        @assert length(data) <= 64 "Length of CAN FD Message must be <= 64."
        @assert length(data) <= 8 || in(length(data), capable_dlc_over8) "Invalid data length."
        new(id, data, is_extended, bitrate_switch, error_state)
    end
end

function FDFrame(frm::CANalyze.CANFdFrame, bitrate_switch::Bool)
    FDFrame(frm.frame_id, frm.data, frm.is_extended, bitrate_switch, false)
end


function CANalyze.Frames.CANFdFrame(frame::FDFrame)
    CANalyze.CANFdFrame(frame.id, frame.data; is_extended=frame.is_extended)
end


function Base.:(==)(msg1::T, msg2::T) where {T<:AbstractFrame}
    res::Bool = true
    for n in fieldnames(T)
        res &= getproperty(msg1, n) == getproperty(msg2, n)
    end
    res
end


function Base.length(msg::T) where {T<:AbstractFrame}
    length(msg.data)
end


end # Framesa