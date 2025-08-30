using Revise
using CAN
using CANalyze


function main()
    sockcan1 = SocketcanInterface("vcan0")
    sockcan2 = SocketcanInterface("vcan1")

    println(sockcan1)
    println(sockcan2)

    frame = CANalyze.CANFrame(14, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(sockcan1, frame)

    frame = recv(sockcan2) # non-blocking receive
    println(frame)

    frame = recv(sockcan2) # returns nothing
    println(frame)

    shutdown(sockcan1)
    shutdown(sockcan2)
end

main()