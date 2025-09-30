# Interfaces

## Interface

```@docs
CANBus.Interfaces.Interface
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

### InterfaceConfig struct

```@docs
CANBus.Interfaces.InterfaceConfig(device::CANBus.Interfaces.DeviceType, channel::Union{String,Int}, bustype::CANBus.Interfaces.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.Interfaces.InterfaceConfigCAN(device::CANBus.Interfaces.DeviceType, channel::Union{String,Int}, bustype::CANBus.Interfaces.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.Interfaces.InterfaceConfigFD(device::CANBus.Interfaces.DeviceType, channel::Union{String,Int}, bustype::CANBus.Interfaces.BusType, bitrate::Int, datarate::Int; kwargs...)
```