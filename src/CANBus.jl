module CANBus

include("frames/Frames.jl")
import .Frames: Frame, FDFrame
export Frame, FDFrame



include("interfaces/Interfaces.jl")
import .Interfaces.VectorInterfaces: VectorInterface, VectorFDInterface
import .Interfaces.KvaserInterfaces: KvaserInterface, KvaserFDInterface
import .Interfaces.SocketCANInterfaces: SocketCANInterface, SocketCANFDInterface
import .Interfaces: AcceptanceFilter, send, recv, shutdown

export VectorInterface, VectorFDInterface,
    KvaserInterface, KvaserFDInterface,
    SocketCANInterface, SocketCANFDInterface

export send, recv, shutdown, AcceptanceFilter


end # module CANBus
