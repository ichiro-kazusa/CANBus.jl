using CAN
using CANalyze

function main()
    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp")

    println(vector1)
    println(vector2)

    frame = CANalyze.CANFrame(15, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(vector1, frame)

    frame = recv(vector2)
    println(frame)

    frame = recv(vector2) # non-blocking receive
    println(frame)

    shutdown(vector1)
    shutdown(vector2)
end

main()