using CANBus
using Test

function main()

    # # CAN
    slcan1 = SlcanFDInterface("COM3", 1_000_000, 2000000)
    slcan2 = SlcanFDInterface("COM4", 1000000, 2000000)

    laststamp = time()
    @time for i in 1:10
        frm_t = FDFrame(0x1, rand(UInt8, 7))
        send(slcan1, frm_t)
        sleep(0.5)

        frm = recv(slcan2)
        if frm !== nothing
            println(frm.timestamp - laststamp)
            laststamp = frm.timestamp
            println(frm)
        end
    end


    # use CAN FD & timeout
    # timeout sample
    msg = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)

    t1 = @async begin
        sleep(1)
        println("sending")
        send(slcan1, msg)
    end

    t2 = @async begin
        local ret
        et = @elapsed begin
            ret = recv(slcan2, timeout_s=3)
        end
        println(et)
        println(ret)
    end

    wait(t1)
    wait(t2)

    msg = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(slcan1, msg)
    sleep(0.1)
    ret = recv(slcan2)
    println(ret)
    ret = recv(slcan2)
    println(ret)


    # end
    shutdown(slcan1)
    shutdown(slcan2)

    true
end


@test main()