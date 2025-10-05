module CANBus

# internal use
module misc
include("misc/SerialHAL.jl")
include("misc/WinWrap.jl")
include("misc/BitTiming.jl")
end # module misc


# public api: frame structure
include("core/Frames.jl")
import .Frames: Frame, FDFrame
export Frame, FDFrame


# public api: interface config
include("core/InterfaceCfgs.jl")
import .InterfaceCfgs:
    InterfaceConfig, AcceptanceFilter,
    InterfaceConfigCAN, InterfaceConfigFD
import .InterfaceCfgs:
    VECTOR, KVASER, SOCKETCAN, SLCAN,
    CAN_20, CAN_FD, CAN_FD_NONISO
export
    InterfaceConfig, AcceptanceFilter,
    InterfaceConfigCAN, InterfaceConfigFD
export
    VECTOR, KVASER, SOCKETCAN, SLCAN,
    CAN_20, CAN_FD, CAN_FD_NONISO


# public api: interfaces
include("applications/Interfaces.jl")
import .Interfaces:
    send, recv, shutdown, Interface

export Interface, send, recv, shutdown


end # module CANBus
