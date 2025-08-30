module CAN


include("interfaces/Interfaces.jl")
using .Interfaces
export VectorInterface,
    KvaserInterface
export send, recv, shutdown




end # module CAN
