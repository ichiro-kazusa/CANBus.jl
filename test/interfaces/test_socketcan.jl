module TestSocketcan
using CANBus
using Test


include("iface_common.jl")

""" to prepare test environment
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link add dev vcan1 type vcan
sudo ip link set up vcan0
sudo ip link set up vcan1
sudo modprobe can-gw
sudo cangw -A -s vcan0 -d vcan1 -e
sudo cangw -A -s vcan1 -d vcan0 -e
sudo cangw -A -X -s vcan0 -d vcan1 -e
sudo cangw -A -X -s vcan1 -d vcan0 -e
"""

const device = SOCKETCAN

const ch1 = "vcan0"
const ch2 = "vcan1"
const ch3 = "vcan2" # not exist

const filter = AcceptanceFilter(0x01, 0x01)

const cfg1 = InterfaceConfigCAN(device, ch1, 500000)
const cfg2 = InterfaceConfigCAN(device, ch2, 500000; extfilter=filter)
const cfg3 = InterfaceConfigCAN(device, ch3, 500000) # must be error

const cfg1_fd = InterfaceConfigFD(device, ch1, 500000, 2000000)
const cfg2_fd = InterfaceConfigFD(device, ch2, 500000, 2000000;
    stdfilter=filter, extfilter=filter)


# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && Sys.islinux()
    @testset "SocketCAN" begin
        @test test_device_normal(cfg1, cfg2)
        @test_throws ErrorException test_device_nodevice(cfg3)
        @test test_device_normal_fd(cfg1_fd, cfg2_fd)
        @test test_device_timeout(cfg1_fd, cfg2_fd)
        @test test_device_do_end(cfg1, cfg1_fd)
    end
end

end # module TestKvaser