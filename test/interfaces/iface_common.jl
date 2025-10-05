using CANBus


function test_device_normal(cfg1, cfg2)

    iface1 = CANBus.Interface(cfg1)
    iface2 = CANBus.Interface(cfg2)


    msg_t1 = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(iface1, msg_t1)

    msg_t2 = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
    send(iface1, msg_t2) # decline by filter

    sleep(0.1)

    msg_r = recv(iface2) # accept by filter
    @assert msg_r == msg_t1

    msg_r = recv(iface2) # decline by filter
    @assert msg_r === nothing

    msg_r = recv(iface2) # receive nothing
    @assert msg_r === nothing

    ret = shutdown(iface1)
    @assert ret === nothing
    shutdown(iface2)

    true
end


function test_device_nodevice(cfg3)
    Interface(cfg3) # must be error
end


function test_device_normal_fd(cfg1_fd, cfg2_fd)
    ifacefd1 = Interface(cfg1_fd)
    ifacefd2 = Interface(cfg2_fd)

    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)
    send(ifacefd1, msg_t)
    sleep(0.1)

    msg_r = recv(ifacefd2)
    @assert msg_t == msg_r

    msg_t = CANBus.FDFrame(1, collect(1:16)) # first message
    send(ifacefd1, msg_t)
    sleep(1)
    msg_t = CANBus.FDFrame(1, collect(1:16)) # check timestamp
    send(ifacefd1, msg_t)

    sleep(0.1) # wait for arrive

    msg_r1 = recv(ifacefd2)
    @assert msg_t == msg_r1

    msg_r2 = recv(ifacefd2)
    isslcan = isa(ifacefd2.device, CANBus.Interfaces.Devices.SlcanDevices.SlcanDevice)
    if !isslcan
        @assert 0.999 <= msg_r2.timestamp - msg_r1.timestamp <= 1.1 # check timestamp
    end

    msg_t = CANBus.FDFrame(2, collect(1:16); is_extended=true)
    send(ifacefd1, msg_t)
    sleep(0.1)

    msg_r = recv(ifacefd2) # filtered
    @assert msg_r === nothing

    msg_r = recv(ifacefd2) # empty
    @assert msg_r === nothing

    shutdown(ifacefd1)
    shutdown(ifacefd2)

    true
end


function test_device_timeout(cfg1_fd, cfg2_fd)

    ifacefd1 = Interface(cfg1_fd)
    ifacefd2 = Interface(cfg2_fd)

    # compile
    msg_t = CANBus.FDFrame(1, collect(1:16); bitrate_switch=false)

    # tests
    res = @elapsed begin
        ret = recv(ifacefd1; timeout_s=1)
        @assert ret === nothing
    end
    @assert 0.9 < res < 1.2

    res = @elapsed begin
        ret = recv(ifacefd1)
        @assert ret === nothing
    end
    @assert 0. < res < 0.1


    t1 = @async begin
        res = @elapsed begin
            recv(ifacefd1; timeout_s=2)
        end
        res
    end

    t2 = @async begin
        sleep(1)
        send(ifacefd2, msg_t)
    end

    res = fetch(t1)
    wait(t2)

    @assert 0.9 < res < 1.1

    shutdown(ifacefd1)
    shutdown(ifacefd2)

    true
end


function test_device_do_end(cfg1, cfg1_fd)
    Interface(cfg1) do iface
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(iface, msg_t)
    end

    Interface(cfg1_fd) do ifacefd
        msg_t = CANBus.Frame(1, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)
        send(ifacefd, msg_t)
    end

    true
end

