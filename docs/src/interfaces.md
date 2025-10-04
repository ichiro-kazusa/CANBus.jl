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
CANBus.InterfaceCfgs.AcceptanceFilter
```

### InterfaceConfig struct

```@docs
CANBus.InterfaceCfgs.InterfaceConfig(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.InterfaceCfgs.InterfaceConfigCAN(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.InterfaceCfgs.InterfaceConfigFD(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int, datarate::Int; kwargs...)
```