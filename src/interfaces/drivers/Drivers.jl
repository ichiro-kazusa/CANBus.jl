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


# プロトタイプ関数群。あとで、直接呼ぶとエラーを返すように修正する
drv_open(::Val, ::Interfaces.InterfaceConfig) = throw(ErrorException("Not Implemented"))

drv_send(::AbstractDriver, ::Frames.AnyFrame) = throw(ErrorException("Not Implemented"))

drv_recv(::AbstractDriver; kwargs...) = throw(ErrorException("Not Implemented"))

drv_close(::AbstractDriver) = throw(ErrorException("Not Implemented"))



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Drivers