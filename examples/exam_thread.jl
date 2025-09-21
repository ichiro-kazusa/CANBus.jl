using CANBus


"""receive thread"""
function recvthread(chn::Channel{Bool})
    thid = Threads.threadid()

    SlcanFDInterface("COM3", 1000000, 2000000) do bus
        while true
            msg = recv(bus)
            if msg !== nothing
                println("thread $thid: ", msg)
            end

            termflag = isready(chn) ? take!(chn) : false
            if termflag
                break
            end

            sleep(0.001)
        end

    end
    println("thread $thid ends...")

end


"""main thread"""
function main()

    println(Threads.threadid())

    chn1 = Channel{Bool}(Inf)
    t = Threads.@spawn recvthread(chn1) # multi-threading

    sleep(20)

    put!(chn1, true) # send termination signal

    wait(t)

end


main()