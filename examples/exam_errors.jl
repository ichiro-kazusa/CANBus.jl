using Revise
using CANBus
import CANBus


struct mydevice{T} <: CANBus.Interfaces.Devices.AbstractDevice{T} end


function main()

    device = CANBus.InterfaceCfgs.NULL
    ch0 = 0
    bustype = CAN_20

    cfg = InterfaceConfig(device, ch0, bustype, 500000;
        datarate=2000000, vector_appname="NewApp")

    try
        CANBus.Interfaces.Devices.dev_open(Val(device), cfg)
    catch e
        println(e)
    end

    try
        CANBus.Interfaces.Devices.dev_recv(mydevice{CANBus.Interfaces.Devices.BUS_20}(); timeout_s=0)
    catch e
        println(e)
    end
end

main()