# InterfaceCgfs

## InterfaceConfig

```@docs
CANBus.InterfaceCfgs.InterfaceConfig
```

```@docs
CANBus.InterfaceCfgs.InterfaceConfig(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.InterfaceCfgs.InterfaceConfigCAN(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)
```

```@docs
CANBus.InterfaceCfgs.InterfaceConfigFD(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int, datarate::Int; kwargs...)
```

## Enumerates

```@docs
CANBus.InterfaceCfgs.DeviceType
```

```@docs
CANBus.InterfaceCfgs.BusType
```

## Fiilter struct

```@docs
CANBus.InterfaceCfgs.AcceptanceFilter
```
