using Revise
using CANBus

function main()

    # # CAN
    slcan1 = SlcanFDInterface("/dev/ttyACM0", 1000000,5000000)
    # slcan2 = SlcanFDInterface("/dev/ttyACM3", 1000000,2000000)

    @time for i in 1:40
        frm_t = FDFrame(0x1, rand(UInt8, 7), false, true, false)
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