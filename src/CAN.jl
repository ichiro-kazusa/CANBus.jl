module CAN


include("interfaces/Interfaces.jl")
using .Interfaces
export VectorInterface,
    KvaserInterface,
    SocketcanInterface
export send, recv, shutdown




end # module CAN
