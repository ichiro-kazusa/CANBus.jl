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


""" Base Type of Devices """
abstract type AbstractDevice{T<:AbstractBusType} end


#= prototype functions =#

""" Abstract function for setup and open device. """
dev_open(::Val, ::InterfaceCfgs.InterfaceConfig) = error("Not Implemented")

""" Abstract function for send frame. """
dev_send(::AbstractDevice, ::Frames.AnyFrame) = error("Not Implemented")

""" Abstract function for receive frame. """
dev_recv(::AbstractDevice; timeout_s::Real) = error("Not Implemented")

""" Abstract function for close device. """
dev_close(::AbstractDevice) = error("Not Implemented")



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Devices