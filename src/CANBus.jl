module CANBus

 # internal use
include("core/LinuxSerial.jl")
include("core/SerialHAL.jl")
import .LinuxSerial
import .SerialHAL


# public api: data structure
include("frames/Frames.jl")
import .Frames: Frame, FDFrame
export Frame, FDFrame

# public api: interfaces
include("interfaces/Interfaces.jl")
import .Interfaces.VectorInterfaces: VectorInterface, VectorFDInterface
import .Interfaces.KvaserInterfaces: KvaserInterface, KvaserFDInterface
import .Interfaces.SocketCANInterfaces: SocketCANInterface, SocketCANFDInterface
import .Interfaces.SlcanInterfaces: SlcanInterface, SlcanFDInterface
import .Interfaces: AcceptanceFilter, send, recv, shutdown

export VectorInterface, VectorFDInterface,
    KvaserInterface, KvaserFDInterface,
    SocketCANInterface, SocketCANFDInterface,
    SlcanInterface, SlcanFDInterface

export send, recv, shutdown, AcceptanceFilter


end # module CANBus
