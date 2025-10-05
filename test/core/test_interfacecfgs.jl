using CANBus
using Test


function test_interfaceconfig_invalid_bitrate()
    InterfaceConfig(VECTOR, 0, CAN_20, -500_000) # must be error
end

function test_interfaceconfig_invalid_bitrate_fd()
    InterfaceConfig(VECTOR, 0, CAN_FD, 500_000; datarate=-200) # must be error
end


@testset "InterfaceConfig" begin
    @test_throws ErrorException test_interfaceconfig_invalid_bitrate()
    @test_throws ErrorException test_interfaceconfig_invalid_bitrate_fd()
end