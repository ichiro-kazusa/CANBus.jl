#########################################################
# in Interfaces module
#########################################################


"""
Abstract type for Interfaces.
"""
abstract type AbstractDriver end


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


#= value reference for dispatching =#
const VAL_ANY_FD = Union{Val{CAN_FD},Val{CAN_FD_NONISO}}


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


mutable struct InterfaceConfig
    device::DeviceType
    channel::Union{String,Int}
    bustype::BusType
    bitrate::Int
    datarate::Union{Nothing,Int}
    silent::Bool
    loopback::Bool
    sample_point::Real
    sample_point_fd::Real
    stdfilter::Union{Nothing,AcceptanceFilter}
    extfilter::Union{Nothing,AcceptanceFilter}
    vendor_specific::Dict
end


function InterfaceConfig(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int)

    InterfaceConfig(device, channel, bustype, bitrate, nothing,
        false, false, 70, 70, nothing, nothing, Dict())
end


struct Interface{T1<:AbstractDriver}
    driver::T1
end


"""
    iface = Interface(ifacecfg::InterfaceConfig)

"""
function Interfaces.Interface(cfg::InterfaceConfig)
    # argument check (except vendor_specific)
    # TODO: write this

    # construct
    d = open(Val(cfg.device), cfg)
    Interface(d)
end

