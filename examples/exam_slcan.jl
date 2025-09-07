using Revise
using CANBus


function main()

    # # CAN
    slcan1 = SlcanFDInterface("COM3", 1000000, 2000000)
    slcan2 = SlcanFDInterface("COM4", 1000000, 2000000)

    
    frm = FDFrame(0x111112e, collect(1:16), true, true, false)
    
    for i in 1:20
        send(slcan1, frm)
        sleep(0.5)
        frm = recv(slcan2)
        if frm !== nothing
            println(frm)
        end
    end
    
    shutdown(slcan1)
    shutdown(slcan2)
end


main()