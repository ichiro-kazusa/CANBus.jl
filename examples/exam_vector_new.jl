using CANBus

function main()
    # bustype = CAN_20
    bustype = CAN_FD
    vendor = KVASER

    ifcfg1 = InterfaceConfig(vendor, 0, bustype, 500000)
    ifcfg1.datarate = 2000000
    ifcfg1.vendor_specific = Dict([:appname => "NewApp"])

    iface1 = Interface(ifcfg1)

    ifcfg2 = InterfaceConfig(vendor, 1, bustype, 500000)
    ifcfg2.datarate = 2000000
    ifcfg2.vendor_specific = Dict([:appname => "NewApp"])

    iface2 = Interface(ifcfg2)

    frm1 = Frame(0x02, [00, 01, 02, 03, 04, 05])
    frm2 = FDFrame(0x02, collect(1:12); is_extended=true)
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