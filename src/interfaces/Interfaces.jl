module Interfaces

using CANalyze

export
    send, recv, shutdown, AcceptanceFilter


"""
Abstract type for Interfaces.
"""
abstract type AbstractCANInterface end

"""
    send(interface::T<:AbstractCANInterface, frame::CANalyze.CANFrame)

Abstract function for send message.

Common behavior of concrete implements:
* When send successed, return nothing.
* When send failed, throws error.
"""
function send(interface::AbstractCANInterface, frame::CANalyze.CANFrame)
    error("abstract 'send' is not implemented.")
end

"""
    recv(interface::T<:AbstractCANInterface)

Abstract function for receive message.

Common behavior of concrete implements:
* non-blocking
* When receive successed, returns CANalyze.CANFrame.
* When receive queue is empty, returns nothing.
"""
function recv(interface::AbstractCANInterface)
    error("abstract 'recv' is not implemented.")
end


"""
    shutdown(interface::T<:AbstractCANInterface)

Abstract function for shutdown interface.
Always returns nothing.
"""
function shutdown(interface::AbstractCANInterface)
    error("abstract 'shutdown' is not implemented.")
end


"""
struct for accept filter.
"""
struct AcceptanceFilter
    code_id::UInt32
    mask::UInt32
end


include("vector/Vector.jl")
import .VectorInterfaces: VectorInterface
export VectorInterface

include("kvaser/Kvaser.jl")
import .KvaserInterfaces: KvaserInterface
export KvaserInterface

include("socketcan/Socketcan.jl")
import .SocketcanInterfaces: SocketcanInterface
export SocketcanInterface


end # Interfaces