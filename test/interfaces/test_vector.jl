using CANBus
using Test

function test_vector_normal()
    # use CAN
    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, msg_t1)

    msg_t2 = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(vector1, msg_t2) # decline by filter

    sleep(0.1)

    msg_r = recv(vector2) # accept by filter
    @assert msg_r == msg_t1

    msg_r = recv(vector2) # decline by filter
    @assert msg_r === nothing

    msg_r = recv(vector2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(vector1)
    @assert ret === nothing
    shutdown(vector2)

    true
end


function test_vector_nodevice()
    VectorInterface(10, 500000, "NewApp") # must be error
end


function test_vector_invalidrate()
    VectorInterface(10, -500000, "NewApp") # must be error
end


function test_vector_normal_fd()

    vectorfd1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
    vectorfd2 = VectorFDInterface(1, 500000, 2000000, "NewApp";
        extfilter=AcceptanceFilter(0x01, 0x01))

    msg_t1 = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(vectorfd1, msg_t1)

    sleep(0.1)

    msg_t2 = CANBus.FDFrame(1, collect(1:16))
    send(vectorfd1, msg_t2)

    sleep(0.1)

    msg_r1 = recv(vectorfd2)
    @assert msg_t1 == msg_r1

    msg_r2 = recv(vectorfd2)
    @assert msg_t2 == msg_r2

    @assert 0.099 < msg_r2.timestamp - msg_r1.timestamp < 0.11

    msg_t = CANBus.FDFrame(2, collect(1:16); is_extended=true)
    send(vectorfd1, msg_t)

    sleep(0.1)

    msg_r = recv(vectorfd2) # filtered
    @assert msg_r === nothing

    msg_r = recv(vectorfd2) # empty
    @assert msg_r === nothing

    shutdown(vectorfd1)
    shutdown(vectorfd2)

    true
end

function test_vector_timeout()
    # recv for classic CAN interface
    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp")

    msg = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    t1 = @async begin
        sleep(1)
        send(vector1, msg)
    end

    t2 = @async begin
        local ret
        et = @elapsed begin
            ret = recv(vector2, timeout_s=3)
        end
        @assert 0.9 < et < 1.1
    end

    wait(t1)
    wait(t2)

    shutdown(vector1)
    shutdown(vector2)

    # recv for CANFD interface
    vectorfd1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
    vectorfd2 = VectorFDInterface(1, 500000, 2000000, "NewApp")

    msg = CANBus.FDFrame(2, collect(1:16); is_extended=true)
    t1 = @async begin
        sleep(1)
        send(vectorfd1, msg)
    end

    t2 = @async begin
        local ret
        et = @elapsed begin
            ret = recv(vectorfd2, timeout_s=3)
        end
        @assert 0.9 < et < 1.1
    end

    wait(t1)
    wait(t2)

    shutdown(vectorfd1)
    shutdown(vectorfd2)

    true
end

function test_vector_do_end()
    VectorInterface(0, 500000, "NewApp") do vector
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(vector, msg_t)
    end

    VectorFDInterface(0, 500000, 2000000, "NewApp") do vectorfd
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(vectorfd, msg_t)
    end

    true
end



# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.iswindows()
    @testset "Vector" begin
        @test test_vector_normal()
        @test_throws ErrorException test_vector_nodevice()
        @test_throws ErrorException test_vector_invalidrate()
        @test test_vector_normal_fd()
        @test test_vector_timeout()
        @test test_vector_do_end()
    end
end
