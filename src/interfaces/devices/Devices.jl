module Devices

import ..Interfaces
import ...Frames


abstract type AbstractBusType end
struct BUS_20 <: AbstractBusType end
struct BUS_FD <: AbstractBusType end

#= internal helper function to determine bustype =#
function bustype_helper(cfg::Interfaces.InterfaceConfig)
    cfg.bustype in (Interfaces.CAN_FD, Interfaces.CAN_FD_NONISO) ?
    BUS_FD : BUS_20
end

abstract type AbstractDevice{T<:AbstractBusType} end


#= prototype functions =#
dev_open(::Val, ::Interfaces.InterfaceConfig) = error("Not Implemented")

dev_send(::AbstractDevice, ::Frames.AnyFrame) = error("Not Implemented")

dev_recv(::AbstractDevice; timeout_s::Real) = error("Not Implemented")

dev_close(::AbstractDevice) = error("Not Implemented")



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Devices