module Interfaces

include("InterfaceCfg.jl")

#= import internal Device module =#
import ..Frames
include("devices/Devices.jl")
import .Devices


struct Interface{T1<:Devices.AbstractDevice}
    driver::T1
end


"""
    iface = Interface(ifacecfg::InterfaceConfig)

Setup CAN Bus Interfaces. 
"""
function Interface(cfg::InterfaceConfig)
    # construct
    d = Devices.dev_open(Val(cfg.device), cfg)
    Interface(d)
end


"""
    Interface(ifacecfg::InterfaceConfig) do iface
        # do something like:
        # ret = recv(iface)
    end

Construnctor for `do` statement.
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
    Devices.dev_send(iface.driver, frm)
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
    Devices.dev_recv(iface.driver; timeout_s)
end


"""
    shutdown(interface::T<:AbstractCANInterface)

function for shutdown interface.
Always returns nothing.
"""
function shutdown(iface::Interface)
    Devices.dev_close(iface.driver)
end


end # Interfaces