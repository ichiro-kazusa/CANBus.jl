module Interfaces

import ..Frames

"""
Abstract type for Interfaces.
"""
abstract type AbstractCANInterface end

"""
    send(interface::T<:AbstractCANInterface, frame::AbstractFrame)

Abstract function for send message.

Common behavior of concrete implements:
* When send successed, return nothing.
* When send failed, throws error.
* Classic CAN interfaces can send ONLY `Frame`
* CAN FD interfaces can send both `Frame` and `FDFrame`
"""
function send()
    error("abstract 'send' is not implemented.")
end

"""
    recv(interface::T<:AbstractCANInterface; timeout_s::Real=0)

Abstract function for receive message.

Common behavior of concrete implements:
* Default non-blocking.
    * For blocking receivement, set `timeout_s` in seconds. 
    * Set `timeout_s` < 0 for infinite bloking.
* When receive successed, returns `Frame` or `FDFrame`.
* When receive queue is empty, returns nothing.
* When fails to receive in other reasons, throws error.
* Classic CAN interfaces return only `Frame` object (except `slcan`).
* CAN FD interfaces return either `Frame` or `FDFrame` object.
"""
function recv()
    error("abstract 'recv' is not implemented.")
end


"""
    shutdown(interface::T<:AbstractCANInterface)

Abstract function for shutdown interface.
Always returns nothing.
"""
function shutdown()
    error("abstract 'shutdown' is not implemented.")
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


include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")


end # Interfaces