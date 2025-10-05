module TestSlcan
using CANBus
using Test


include("iface_common.jl")


const device = SLCAN

@static if Sys.iswindows()
    const ch1 = "COM3"
    const ch2 = "COM4"
else
    const ch1 = "/dev/ttyACM0"
    const ch2 = "/dev/ttyACM1"
end
const ch3 = 2 # not exist

const filter = AcceptanceFilter(0x01, 0x01)

const cfg1 = InterfaceConfigCAN(device, ch1, 500000;)
const cfg2 = InterfaceConfigCAN(device, ch2, 500000; extfilter=filter)
const cfg3 = InterfaceConfigCAN(device, ch3, 500000;) # must be error

const cfg1_fd = InterfaceConfigFD(device, ch1, 500000, 2000000;)
const cfg2_fd = InterfaceConfigFD(device, ch2, 500000, 2000000; extfilter=filter)



# This feature can not be able to test on GitHub Actions.
if !haskey(ENV, "GITHUB_ACTIONS") && (Sys.iswindows() || Sys.islinux())
    @testset "Slcan" begin
        @test test_device_normal(cfg1, cfg2)
        @test_throws MethodError test_device_nodevice(cfg3)
        @test test_device_normal_fd(cfg1_fd, cfg2_fd)
        @test test_device_timeout(cfg1_fd, cfg2_fd)
        @test test_device_do_end(cfg1, cfg1_fd)
    end
end

end # module TestSlcan