#########################################################
# in module Interfaces
#########################################################


@enum DeviceType::UInt8 begin
    VECTOR
    KVASER
    SOCKETCAN
    SLCAN
end


@enum BusType::UInt8 begin
    CAN_20
    CAN_FD
    CAN_FD_NONISO
end



"""
    AcceptanceFilter(code_id, mask)

Struct for accept filter. 
    
If this struct is set to Interface,
the id is accepted when 
`<received_id> & mask == code_id & mask`
or
`(<received_id> xor code_id) & mask == 0 `.
Those are equivalent.
"""
struct AcceptanceFilter
    code_id::UInt32
    mask::UInt32
end


struct InterfaceConfig
    device::DeviceType
    channel::Union{String,Int}
    bustype::BusType
    bitrate::Int
    datarate::Union{Nothing,Int}
    silent::Bool
    sample_point::Real
    sample_point_fd::Real
    stdfilter::Union{Nothing,AcceptanceFilter,Vector{AcceptanceFilter}}
    extfilter::Union{Nothing,AcceptanceFilter,Vector{AcceptanceFilter}}
    vector_appname::String
    slcan_serialbaud::Integer
end


"""
Always required:
* device: Device name. e.g. VECTOR, SOCKETCAN...
* channel: Device specific channel name.
* bustype: (CAN_20, CAN_FD, CAN_FD_NONISO)

Required when bustype is CAN_FD or CAN_FD_NONISO:
* datarate

Other options:

| Device     | silent | sample_point/_fd | std/extfilter   | vector_appname |
| ---------- | ------ | ---------------- | --------------- | -------------- |
| KVASER     |   ✓   |   ✓             |   ✓            |   ign           |
| SLCAN      |   ✓   |   ign            |   ign           |   ign          |
| SOCKETCAN  |   ign  |   ign            |   ✓            |   ign          |
| VECTOR     |   ✓   |   ✓             |   ✓            |   ◯           |

◯:required,
✓:supported,
ign:ignored.

See Hardwares section to see vendor specific notations.
"""
function InterfaceConfig(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int;
    datarate=nothing, silent=false,
    sample_point=70, sample_point_fd=70,
    stdfilter=nothing, extfilter=nothing,
    vector_appname="CANalyzer", slcan_serialbaud=2_000_000)

    # check validity
    if !(0 < bitrate <= 1_000_000)
        error("invalid bitrate")
    end
    if !(50 < sample_point < 100)
        error("invalid samplepoint")
    end
    if bustype in (CAN_FD, CAN_FD_NONISO)
        if datarate === nothing || datarate <= 0
            error("invalid datarate")
        end
        if !(50 < sample_point_fd < 100)
            error("invalid fd samplepoint")
        end
    end

    # construct
    InterfaceConfig(device, channel, bustype, bitrate, datarate,
        silent, sample_point, sample_point_fd,
        stdfilter, extfilter,
        vector_appname, slcan_serialbaud)
end


"""
    InterfaceConfigCAN(device::DeviceType, channel::Union{String,Int},
        bustype::BusType, bitrate::Int; kwargs...)

Helper function to construct InterfaceConfig object for CAN2.0 setup.
kwargs is same as `InterfaceConfig` constructor.
"""
function InterfaceConfigCAN(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int; kwargs...)::InterfaceConfig

    InterfaceConfig(device, channel, CAN_20, bitrate; kwargs...)
end


"""
    InterfaceConfigFD(device::DeviceType, channel::Union{String,Int},
        bustype::BusType, bitrate::Int, datarate::Int; kwargs...)

Helper function to construct InterfaceConfig object for CAN-FD (ISO type) setup.
kwargs is same as `InterfaceConfig` constructor.
"""
function InterfaceConfigFD(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int, datarate::Int; kwargs...)::InterfaceConfig

    InterfaceConfig(device, channel, CAN_FD, bitrate;
        datarate=datarate, kwargs...)
end


#= internal helper function that cfg for FD? =#
helper_isfd(cfg::InterfaceConfig) = cfg.bustype in (CAN_FD, CAN_FD_NONISO)

