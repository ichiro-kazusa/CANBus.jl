module Interfaces

import ..Frames

include("InterfaceDef.jl")

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
    send(iface.driver, frm)
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
    recv(iface.driver; timeout_s)
end


"""
    shutdown(interface::T<:AbstractCANInterface)

function for shutdown interface.
Always returns nothing.
"""
function shutdown(iface::Interface)
    shutdown(iface.driver)
end




include("vector/Vector.jl")
# include("kvaser/Kvaser.jl")
# include("socketcan/Socketcan.jl")
# include("slcan/Slcan.jl")


end # Interfaces