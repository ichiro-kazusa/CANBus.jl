module Interfaces

using CANalyze

export
    send, recv, shutdown

abstract type AbstractCANInterface end


function send(interface::AbstractCANInterface, frame::CANalyze.CANFrame)
    error("abstract 'send' is not implemented.")
end

function recv(interface::AbstractCANInterface, frame::CANalyze.CANFrame)
    error("abstract 'send' is not implemented.")
end

function shutdown(interface::AbstractCANInterface)
    error("abstract 'shutdown' is not implemented.")
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