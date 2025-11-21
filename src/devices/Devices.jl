module Devices

import ...InterfaceCfgs
import ...Frames
import ...Errors


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
function dev_open(v::Val, ::InterfaceCfgs.InterfaceConfig)
    throw(Errors.CANBusNotImplementedError("CANBus: Function to open $v is not implemented."))
end


""" Abstract function for send frame. """
function dev_send(ad::AbstractDevice, ::Frames.AnyFrame)
    throw(Errors.CANBusNotImplementedError("CANBus: Function to send on $ad is not implemented."))
end


""" Abstract function for receive frame. """
function dev_recv(ad::AbstractDevice; timeout_s::Real)
    throw(Errors.CANBusNotImplementedError("CANBus: Function to receive on $ad is not implemented."))
end


""" Abstract function for close device. """
function dev_close(ad::AbstractDevice)
    throw(Errors.CANBusNotImplementedError("CANBus: Function to close $ad is not implemented."))
end



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Devices