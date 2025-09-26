module CANBus

module core
# internal use
include("core/SerialHAL.jl")
include("core/WinWrap.jl")
include("core/BitTiming.jl")
end # module core


# public api: data structure
include("frames/Frames.jl")
import .Frames: Frame, FDFrame
export Frame, FDFrame

# public api: interfaces
include("interfaces/Interfaces.jl")
import .Interfaces:
    AcceptanceFilter, send, recv, shutdown,
    Interface, InterfaceConfig
import .Interfaces:
    VECTOR, KVASER, SOCKETCAN, SLCAN,
    CAN_20, CAN_FD, CAN_FD_NONISO


export Interface, InterfaceConfig
export send, recv, shutdown, AcceptanceFilter
export
    VECTOR, KVASER, SOCKETCAN, SLCAN,
    CAN_20, CAN_FD, CAN_FD_NONISO


end # module CANBus
