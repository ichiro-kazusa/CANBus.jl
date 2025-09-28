using CANBus

function main()
    # bustype = CAN_20
    bustype = CAN_FD
    device = VECTOR
    # device = KVASER
    # device = SLCAN
    # device = SOCKETCAN
    # ch0 = "vcan0"
    # ch1 = "vcan1"
    # ch0 = "COM3"
    # ch1 = "COM4"
    # ch0 = "/dev/ttyACM0"
    # ch1 = "/dev/ttyACM1"
    ch0 = 0
    ch1 = 1

    ifcfg1 = InterfaceConfig(device, ch0, bustype, 500000;
        datarate=2000000, vector_appname="NewApp")

    ifcfg2 = InterfaceConfig(device, ch1, bustype, 500000;
        datarate=2000000, vector_appname="NewApp")

    iface1 = Interface(ifcfg1)
    Interface(ifcfg2) do iface2

        println(iface1)

        frm1 = Frame(0x02, [00, 01, 02, 03, 04, 05])
        frm2 = bustype == CAN_FD ? FDFrame(0x02, collect(1:12); is_extended=true) : frm1
        send(iface1, frm1)
        send(iface1, frm2)

        sleep(0.1)

        ret = recv(iface2; timeout_s=-1)
        println(ret)
        ret = recv(iface2; timeout_s=-1)
        println(ret)

    end
    shutdown(iface1)

end

main()