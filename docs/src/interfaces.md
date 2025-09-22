# Interfaces

## Base type

```@docs
CANBus.Interfaces.AbstractCANInterface
```

```@docs
CANBus.Interfaces.send
```

```@docs
CANBus.Interfaces.recv
```

```@docs
CANBus.Interfaces.shutdown
```

### Fiilter struct

```@docs
CANBus.Interfaces.AcceptanceFilter
```

## Kvaser

```@docs
CANBus.Interfaces.KvaserInterfaces.KvaserInterface
```

```@docs
CANBus.Interfaces.KvaserInterfaces.KvaserFDInterface
```

## slcan

`slcan` does not support hardware filter.

```@docs
CANBus.Interfaces.SlcanInterfaces.SlcanInterface
```

```@docs
CANBus.Interfaces.SlcanInterfaces.SlcanFDInterface
```

## SocketCAN

```@docs
CANBus.Interfaces.SocketCANInterfaces.SocketCANInterface
```

```@docs
CANBus.Interfaces.SocketCANInterfaces.SocketCANFDInterface
```

## Vector

```@docs
CANBus.Interfaces.VectorInterfaces.VectorInterface
```

```@docs
CANBus.Interfaces.VectorInterfaces.VectorFDInterface
```

## `do` block support

Every interface supports automatic shutdown by `do` - `end` block like below:

```jl
SocketCANInterface("can0") do iface
    res = recv(iface)
end # shutdown(iface)
```