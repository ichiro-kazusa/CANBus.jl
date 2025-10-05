using Revise
using CANBus


function main()
    # bustype = CAN_20
    bustype = CAN_FD

    # device = VECTOR
    # device = KVASER
    device = SLCAN
    # device = SOCKETCAN

    if device in (VECTOR, KVASER)
        ch0 = 0
        ch1 = 1
    elseif device == SOCKETCAN
        ch0 = "vcan0"
        ch1 = "vcan1"
    elseif Sys.iswindows() # slcan for windows
        ch0 = "COM3"
        ch1 = "COM4"
    else # slcan linux
        ch0 = "/dev/ttyACM0"
        ch1 = "/dev/ttyACM1"
    end

    # -------------------------------------

    ifcfg1 = InterfaceConfig(device, ch0, bustype, 500000;
        datarate=2000000, vector_appname="NewApp")

    f = AcceptanceFilter(0x02, 0x02)

    ifcfg2 = InterfaceConfig(device, ch1, bustype, 500000;
        datarate=2000000, vector_appname="NewApp", stdfilter=f)

    iface1 = Interface(ifcfg1)
    Interface(ifcfg2) do iface2 # do-end example

        # println(iface1)

        frm1 = Frame(0x02, [00, 01, 02, 03, 04, 05])
        frm2 = bustype == CAN_20 ? frm1 : FDFrame(0x02, collect(1:12); is_extended=true)
        send(iface1, frm1)
        send(iface1, frm2)

        sleep(0.1)

        ret1 = recv(iface2; timeout_s=1)
        println(ret1)

        ret2 = recv(iface2; timeout_s=1)
        println(ret2)

    end
    shutdown(iface1)

end

main()