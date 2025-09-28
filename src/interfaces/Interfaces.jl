module Interfaces


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

#= helper function that cfg for FD? =#
function isfd(cfg::InterfaceConfig)
    return cfg.bustype in [CAN_FD, CAN_FD_NONISO]
end


#= import internal Driver module =#
import ..Frames
include("drivers/Drivers.jl")
import .Drivers


struct Interface{T1<:Drivers.AbstractDriver}
    driver::T1
end


"""
    iface = Interface(ifacecfg::InterfaceConfig)

"""
function Interface(cfg::InterfaceConfig)
    # argument check (except vendor_specific)
    # TODO: write this

    # construct
    d = Drivers.drv_open(Val(cfg.device), cfg)
    Interface(d)
end


"""
    Interface(ifacecfg::InterfaceConfig) do iface
        # do something
    end

construnctor for `do` statement.
"""
function Interface(f::Function, args...; kwargs...)
    iface = Interface(args...; kwargs...)

    try
        return f(iface)
    finally
        shutdown(iface)
    end
end


"""
    send(interface::T<:AbstractCANInterface, frame::AbstractFrame)

function for send message.

It behaves:
* When send successed, return nothing.
* When send failed, throws error.
* Classic CAN interfaces can send ONLY `Frame`
* CAN FD interfaces can send both `Frame` and `FDFrame`
"""
function send(iface::Interface, frm::Frames.AnyFrame)
    Drivers.drv_send(iface.driver, frm)
end


"""
    recv(interface::T<:AbstractCANInterface; timeout_s::Real=0)

function for receive message.

It behaves:
* Default non-blocking.
    * For blocking receivement, set kwarg `timeout_s` in seconds. 
    * Set `timeout_s` < 0 for infinite bloking.
* When receive successed, returns `Frame` or `FDFrame`.
* When receive queue is empty, returns nothing.
* When fails to receive in other reasons, throws error.
* Classic CAN interfaces return only `Frame` object (except `slcan`).
* CAN FD interfaces return either `Frame` or `FDFrame` object.
"""
function recv(iface::Interface; timeout_s::Real=0)
    Drivers.drv_recv(iface.driver; timeout_s)
end


"""
    shutdown(interface::T<:AbstractCANInterface)

function for shutdown interface.
Always returns nothing.
"""
function shutdown(iface::Interface)
    Drivers.drv_close(iface.driver)
end


end # Interfaces