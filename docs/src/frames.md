# Frames

In `CANBus.jl`, send/receive messages are represented in `CANBus.Frames` module.
For CAN frame, `Frame` is used, or for CAN FD frame, `FDFrame` is used.

## Base type

```@docs
CANBus.Frames.AbstractFrame
```

## Frame

```@docs
CANBus.Frames.Frame
```

## FDFrame

```@docs
CANBus.Frames.FDFrame
```

## Compatibility with `CANalyze` package

`Frame` and `FDFrame` has intercompatibility with `CANalyze.CANFrame` and `CANAlyze.CANFdFrame` respectively.

For instance, `Frame` constructor has a converter from `CANalyze.CANFrame` struct, you can use it like below:

```jl
using CANBus
using CANalyze

vector1 = VectorInterface(0, 500000, "NewApp")

frm = CANalyze.CANFrame(1, [1, 2, 3, 4, 5, 6, 7, 8])
msg = Frame(frm)
send(vector1, msg)
```

In the opposite direction, `CANalyze.CANFrame` and `CANalyze.CANFdFrame` constructors are overridden, 
so that you can feed `Frame` and `FDFrame` structs to `CANalyze.Decode.decode` function with conversion.

```jl
frm = CANBus.Frame(0x0e, [1, 2, 3, 4], false)

signal = CANalyze.Signals.NamedSignal("myfloat", nothing, nothing,
    CANalyze.Signals.Float32Signal(start=0; byte_order=:little_endian))
msg = CANalyze.Messages.Message(0x0e, 4, "msg1", signal)

d = CANalyze.Decode.decode(msg, CANalyze.Frames.CANFrame(frm))
```