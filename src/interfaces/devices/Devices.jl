module Devices

import ...InterfaceCfgs
import ...Frames


abstract type AbstractBusType end
struct BUS_20 <: AbstractBusType end
struct BUS_FD <: AbstractBusType end

#= internal helper function to determine bustype =#
function helper_bustype(cfg::InterfaceCfgs.InterfaceConfig)
    cfg.bustype in (InterfaceCfgs.CAN_FD, InterfaceCfgs.CAN_FD_NONISO) ?
    BUS_FD : BUS_20
end

abstract type AbstractDevice{T<:AbstractBusType} end


#= prototype functions =#
dev_open(::Val, ::InterfaceCfgs.InterfaceConfig) = error("Not Implemented")

dev_send(::AbstractDevice, ::Frames.AnyFrame) = error("Not Implemented")

dev_recv(::AbstractDevice; timeout_s::Real) = error("Not Implemented")

dev_close(::AbstractDevice) = error("Not Implemented")



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Devices