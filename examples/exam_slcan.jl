using Revise
using CANBus

function main()

    # # CAN
    slcan1 = SlcanFDInterface("/dev/ttyACM0", 1000000,2000000)
    # slcan2 = SlcanFDInterface("/dev/ttyACM3", 1000000,2000000)


    println(slcan1)

    for i in 1:40
        frm_t = FDFrame(0x1, collect(1:7), false, false, false)
        send(slcan1, frm_t)
        sleep(0.5)

        frm = recv(slcan1)
        if frm !== nothing
            println(frm)
        end
    end
    
    shutdown(slcan1)
    # shutdown(slcan2)
end


main()