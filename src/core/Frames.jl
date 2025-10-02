module Frames

using CANalyze


"""Abstract type for Frames."""
abstract type AbstractFrame end


# validation functions

#= check id range =#
function _check_id(id::Integer, is_extended::Bool)
    if is_extended
        return 0x0 <= id <= 0x1FFFFFFF
    else
        return 0x0 <= id <= 0x7FF
    end
end

#= check dlc =#
const capable_dlc_over8 = [12, 16, 20, 24, 32, 48, 64]
function _check_len(len::Integer, is_fd::Bool)
    if is_fd
        return 0 <= len <= 8 || len in capable_dlc_over8
    else
        return 0 <= len <= 8
    end
end


"""
    Frame(id::Integer, data::AbstractVector;
        timestamp::Float64=0, is_extended::Bool=false, 
        is_remote_frame::Bool=false, is_error_frame::Bool=false)

Frame struct represents classic (MAX 8bytes) CAN frame.

* `id`: arbitration id
* `data`: Vector of Integer with length <= 8. If input has element > 255, throws error.

kwargs:
* `timestamp`: When receive, arrive time stamp is set in this field. When transmission, this field is not cared.
* `is_extended`: Flag which arbitration id is extended. default=`false`
* `is_remote_frame`: Flag which indicates remote frame. default=`false`
* `is_error_frame` : Flag which indicates error frame. Cared in RX only. default=`false`

```jl
frame = CANBus.Frame(0x5, [1, 2, 3, 4, 5, 6, 7, 8]; is_extended=true)
```
"""
struct Frame <: AbstractFrame
    timestamp::Float64
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool
    is_remote_frame::Bool
    is_error_frame::Bool

    function Frame(id::IT, data::V; timestamp::Float64=0.0, is_extended::Bool=false,
        is_remote_frame::Bool=false, is_error_frame::Bool=false) where {IT<:Integer,V<:AbstractVector}

        if !_check_id(id, is_extended)
            error("Frame: invalid id range.")
        end
        if !_check_len(length(data), false)
            error("Frame: invalid data length.")
        end

        new(timestamp, id, data, is_extended, is_remote_frame, is_error_frame)
    end
end


"""
    Frame(frm::CANalyze.CANFrame)

This constructor converts `CANalyze.CANFrame` to `CANBus.Frame`.
"""
function Frame(frm::CANalyze.CANFrame)
    Frame(frm.frame_id, frm.data; is_extended=frm.is_extended)
end

"""
    CANalyze.Frames.CANFrame(frame::Frame)

This constructor converts `CANBus.Frame` to `CANalyze.CANFrame`.
"""
function CANalyze.Frames.CANFrame(frame::Frame)
    CANalyze.CANFrame(frame.id, frame.data; is_extended=frame.is_extended)
end



"""
    FDFrame(id::Integer, data::AbstractVector;
        timestamp::Float64=0, is_extended::Bool=false,
        bitrate_switch::Bool=true, error_state::Bool=false, is_error_frame::Bool=false)

FDFrame struct represents CAN FD (MAX 64bytes) frame.

* `id`: arbitration id
* `data`: Vector of Integer. Length must be in CAN FD DLC standard. Elements must not be > 255.

kwargs:
* `timestamp`: When receive, arrive time stamp is set in this field. When transmission, this field is not cared.
* `is_extended`: Flag which arbitration id is extended. default=`false`
* `bitrate_switch`: Flag to use `bitrate_switch`. **default=`true`**
* `error_state`: Flag corresponds to `error_state_indicator`. Cared in RX only. default=`false`
* `is_error_frame` : Flag which indicates error frame. Cared in RX only. default=`false`
"""
struct FDFrame <: AbstractFrame
    timestamp::Float64
    id::UInt32
    data::Vector{UInt8}
    is_extended::Bool
    bitrate_switch::Bool
    error_state::Bool
    is_error_frame::Bool

    function FDFrame(id::IT, data::V; timestamp::Float64=0.0,
        is_extended::Bool=false, bitrate_switch::Bool=true, error_state::Bool=false,
        is_error_frame::Bool=false) where {IT<:Integer,V<:AbstractVector}

        if !_check_id(id, is_extended)
            error("Frame: invalid id range.")
        end
        if !_check_len(length(data), true)
            error("Frame: invalid data length.")
        end

        new(timestamp, id, data, is_extended, bitrate_switch, error_state, is_error_frame)
    end
end


"""
    FDFrame(frm::CANalyze.CANFdFrame; bitrate_switch::Bool=true)

This constructor converts `CANalyze.CANFdFrame` to `CANBus.FDFrame`.
"""
function FDFrame(frm::CANalyze.CANFdFrame; bitrate_switch::Bool=true)
    FDFrame(frm.frame_id, frm.data; is_extended=frm.is_extended, bitrate_switch=bitrate_switch)
end


"""
    CANalyze.Frames.CANFdFrame(frame::FDFrame)

This constructor converts `CANBus.FDFrame` to `CANalyze.CANFdFrame`.
"""
function CANalyze.Frames.CANFdFrame(frame::FDFrame)
    CANalyze.CANFdFrame(frame.id, frame.data; is_extended=frame.is_extended)
end



"""
    Base.:(==)(msg1::T, msg2::T) where {T<:CANBus.Frames.AbstractFrame}

Compare two `Frame`s or `FDFrame`s except timestamp field.
"""
function Base.:(==)(msg1::T, msg2::T) where {T<:AbstractFrame}
    res::Bool = true
    for n in fieldnames(T)
        if n == :timestamp # skip to compare timestamp
            continue
        end
        res &= getproperty(msg1, n) == getproperty(msg2, n)
    end
    res
end


"""
    Base.length(msg::T) where {T<:CANBus.Frames.AbstractFrame}

Return length of data field.
"""
function Base.length(msg::T) where {T<:AbstractFrame}
    length(msg.data)
end


const AnyFrame = Union{Frame,FDFrame} # union type

end # Frames