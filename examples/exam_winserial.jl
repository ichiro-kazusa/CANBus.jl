import CANBus: WinSerial


function main()

    hnd = WinSerial.open("COM3", 115200)
    println(hnd)

    
    ret = WinSerial.write(hnd, "E\r")
    WinSerial.drain(hnd)
    println(ret)


    read = WinSerial.nonblocking_read(hnd)
    println(String(read))

    WinSerial.close(hnd)

end




main()