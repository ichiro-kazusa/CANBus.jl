module Drivers

import ..Interface
import ...Frames

abstract type AbstractDriver end


# プロトタイプ関数群。あとで、直接呼ぶとエラーを返すように修正する
function drv_open(::Val, ::InterfaceConfig)
end

function drv_send(::AbstractDriver, ::Frames.AnyFrame)
end

function drv_recv(::AbstractDriver; kwargs...)
end

function drv_close(::AbstractDriver)
end


include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Drivers