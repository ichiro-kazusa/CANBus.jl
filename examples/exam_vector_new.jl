using CANBus

function main()
    # bustype = CAN_20
    bustype = CAN_FD
    # vendor = KVASER
    # vendor = VECTOR
    vendor = SLCAN
    # ch0 = 0#"vcan0"
    # ch1 = 1#"vcan1"
    ch0 = "COM3"
    ch1 = "COM4"

    ifcfg1 = InterfaceConfig(vendor, ch0, bustype, 500000)
    ifcfg1.datarate = 2000000
    ifcfg1.vendor_specific = Dict([:appname => "NewApp"])

    iface1 = Interface(ifcfg1)

    ifcfg2 = InterfaceConfig(vendor, ch1, bustype, 500000)
    ifcfg2.datarate = 2000000
    ifcfg2.vendor_specific = Dict([:appname => "NewApp"])

    iface2 = Interface(ifcfg2)

    frm1 = Frame(0x02, [00, 01, 02, 03, 04, 05])
    frm2 = bustype == CAN_FD ? FDFrame(0x02, collect(1:12); is_extended=true) : frm1
    send(iface1, frm1)
    send(iface1, frm2)

    sleep(0.1)

    ret = recv(iface2; timeout_s=-1)
    println(ret)
    ret = recv(iface2; timeout_s=-1)
    println(ret)

    shutdown(iface1)
    shutdown(iface2)

end

main()