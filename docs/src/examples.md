# Example Usage

Let us assume that we have 2-channel Vector interface, the simplest example is below:

```julia
using CAN
using CANalyze

function main()
    vector1 = VectorInterface(0, 500000, "NewApp")
    vector2 = VectorInterface(1, 500000, "NewApp")

    frame = CANalyze.CANFrame(15, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(vector1, frame)

    frame = recv(vector2) # non-blocking receive
    println(frame)

    frame = recv(vector2) # returns nothing
    println(frame)

    shutdown(vector1)
    shutdown(vector2)
end

main()
```

Arguments of interface setup are different depends on kind of interface, see References.

