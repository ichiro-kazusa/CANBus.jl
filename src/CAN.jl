module CAN

include("messages/Messages.jl")
import .Messages: CANMessage, CANFDMessage
export CANMessage, CANFDMessage



include("interfaces/Interfaces.jl")
import .Interfaces.VectorInterfaces: VectorInterface, VectorFDInterface
import .Interfaces.KvaserInterfaces: KvaserInterface, KvaserFDInterface
import .Interfaces.SocketcanInterfaces: SocketcanInterface
import .Interfaces: AcceptanceFilter, send, recv, shutdown

export VectorInterface, VectorFDInterface,
    KvaserInterface, KvaserFDInterface,
    SocketcanInterface

export send, recv, shutdown, AcceptanceFilter


end # module CAN
