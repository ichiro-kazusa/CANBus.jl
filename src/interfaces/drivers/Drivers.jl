module Drivers

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

abstract type AbstractDriver{T<:AbstractBusType} end


#= prototype functions =#
drv_open(::Val, ::Interfaces.InterfaceConfig) = error("Not Implemented")

drv_send(::AbstractDriver, ::Frames.AnyFrame) = error("Not Implemented")

drv_recv(::AbstractDriver; timeout_s::Real) = error("Not Implemented")

drv_close(::AbstractDriver) = error("Not Implemented")



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Drivers