module Interfaces


import ..InterfaceCfgs
import ..Frames
include("../devices/Devices.jl")
import .Devices


struct Interface{T1<:Devices.AbstractDevice}
    device::T1
end


"""
    iface = Interface(ifacecfg::InterfaceConfig)

Setup CAN Bus Interfaces. 

This function throws `CANBusOpenError` when it failed to setup.
"""
function Interface(cfg::InterfaceCfgs.InterfaceConfig)
    # construct
    d = Devices.dev_open(Val(cfg.device), cfg)
    Interface(d)
end


"""
`do` statement is also supported.

    Interface(ifacecfg::InterfaceConfig) do iface
        # do something like:
        # ret = recv(iface)
    end
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
    send(interface::T<:Interface, frame::AbstractFrame)

function for send message.

It behaves:
* When send successed, returns `nothing`.
* When send failed, throws error.
* Classic CAN interfaces can send ONLY `Frame`
* CAN FD interfaces can send both `Frame` and `FDFrame`
"""
function send(iface::Interface, frm::Frames.AnyFrame)
    Devices.dev_send(iface.device, frm)
end


"""
    recv(interface::T<:Interface; timeout_s::Real=0)

function for receive message.

It behaves:
* Default non-blocking.
    * For blocking receivement, set kwarg `timeout_s` in seconds. 
    * Set `timeout_s` < 0 for infinite bloking.
* When receive successed, returns `Frame` or `FDFrame`.
* When receive queue is empty, returns `nothing`.
* When fails to receive in other reasons, throws error.
* Classic CAN interfaces return only `Frame` object (except `slcan`).
* CAN FD compliant interfaces return either `Frame` or `FDFrame` object.
"""
function recv(iface::Interface; timeout_s::Real=0)
    Devices.dev_recv(iface.device; timeout_s)
end


"""
    shutdown(interface::T<:Interface)

function for shutdown interface.
Always returns nothing.
"""
function shutdown(iface::Interface)
    Devices.dev_close(iface.device)
end



"""
    status(interface::T<:Interface)

This functions checks and returns bus status.

The bus status is any of the following:

* NO_STATUS: No status information.
* BUSOFF: Bus is offline.
* ERROR_ACTIVE: Bus is fine.
* ERROR_WARNING: The error counter has reached the warning level.
* ERROR_PASSIVE: The error counter has reached the error level.

More details is described in many websites, such as [here](https://www.csselectronics.com/pages/can-bus-errors-intro-tutorial).

`ERROR_WARNING` level is vendor-specific status.
See official documents of their APIs for details.
"""
function status(iface::Interface)
    Devices.dev_status(iface.device)
end


end # Interfaces