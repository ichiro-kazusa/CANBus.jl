using CAN
using CANalyze
using Test


function test_equal_can()
    msg1 = Frame(0x12345, collect(1:7), true)
    msg2_frm = CANalyze.CANFrame(0x12345, collect(1:7); is_extended=true)
    msg2 = Frame(msg2_frm)
    msg3 = Frame(0x123, collect(1:8), false)

    @assert msg1 == msg2 # 8th bytes are different, but must be return true.
    @assert msg1 != msg3
    @assert length(msg1) == 7 # length test

    true
end


function test_message_can()
    Frame(0x12345, collect(1:9), true) # throws AssertionError
end


function test_convert_can()
    msg = Frame(0x12345, collect(1:6), true)
    frm = CANalyze.CANFrame(msg)
    frm_true = CANalyze.CANFrame(0x12345, collect(1:6); is_extended=true)

    frm == frm_true
end


function test_equal_fd()
    msg1 = FDFrame(0x12345, collect(1:64), true, false, false)
    msg2_frm = CANalyze.CANFdFrame(0x12345, collect(1:64); is_extended=true)
    msg2 = FDFrame(msg2_frm, false)
    msg3 = FDFrame(0x123, collect(1:24), false, false, false)

    @assert msg1 == msg2 # 8th bytes are different, but must be return true.
    @assert msg1 != msg3
    @assert length(msg3) == 24 # length test

    true
end


function test_message_fd_over()
    FDFrame(0x12345, collect(1:128), true, false, false) # AssertionError
end


function test_message_fd_invalid_dlc()
    FDFrame(0x12345, collect(1:29), true, false, false) # AssertionError
end


function test_convert_fd()
    msg = FDFrame(0x12345, collect(1:32), true, false, false)
    frm = CANalyze.CANFdFrame(msg)
    frm_true = CANalyze.CANFdFrame(0x12345, collect(1:32); is_extended=true)
    
    repr(frm) == repr(frm_true) # :(==) between CANFdFrame is not implemented.
end



@testset "messages" begin
    @test test_equal_can()
    @test_throws AssertionError test_message_can()
    @test test_convert_can()
    @test test_equal_fd()
    @test_throws AssertionError test_message_fd_over()
    @test_throws AssertionError test_message_fd_invalid_dlc()
    @test test_convert_fd()
end
