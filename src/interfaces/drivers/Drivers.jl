module Drivers

abstract type AbstractDriver end



# プロトタイプ関数群。あとで、直接呼ぶとエラーを返すように修正する
function drv_open()
end

function drv_send()
end

function drv_recv()
end

function drv_close()
end



include("vector/Vector.jl")
include("kvaser/Kvaser.jl")
include("socketcan/Socketcan.jl")
include("slcan/Slcan.jl")

end # Drivers