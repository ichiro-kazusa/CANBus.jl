using Revise
using LibSerialPort
using CAN


function main()

    # # CAN
    slcan = SlcanInterface("COM3", 1000000)

    frm = Frame(0x111111e, collect(1:7), true)


    for i in 1:100
        # send(slcan, frm)
        frm = recv(slcan)
        if frm !== nothing
            println(frm)
        end
        sleep(0.1)
    end

    shutdown(slcan)

    return nothing

    # CAN FD
    slcan = SlcanFDInterface("COM3", 1000000, 2000000)

    frm = FDFrame(0x111112e, collect(1:16), true, true, false)

    for i in 1:20
        # send(slcan, frm)
        frm = recv(slcan)
        if frm !== nothing
            println(frm)
        end
        sleep(0.5)
    end

    shutdown(slcan)
end


main()