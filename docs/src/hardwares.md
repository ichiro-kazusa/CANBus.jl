# Supported Hardwares

This section describes basic usage for each supported hardwares.

## Kvaser

`KVASER` supports Win64 platform.

This interface requires `canlib32.dll` (supposed to be installed along with the device driver). 

To setup interface, do something like below,

```jl
cfg = InterfaceConfigCAN(KVASER, 0, 500_000) # channel 0, 500kbps
iface = Interface(cfg)
```

For CAN FD,
```jl
cfg = InterfaceConfigFD(KVASER, 0, 500_000, 2_000_000) # channel 0, 500kbps, 2Mbps
iface = Interface(cfg)  
```

## slcan

`SLCAN` supports Win64/Linux platform. Tested on [CANable 2.0](https://canable.io/) firmware.

To setup interface, 

```jl
cfg = InterfaceConfigCAN(SLCAN, "COM3", 500_000) # channel COM3, 500kbps
iface = Interface(cfg)
```

channel name is supposed to be like `COM3` on Windows, like `/dev/ttyACM0` on Linux.

For CAN FD,
```jl
cfg = InterfaceConfigFD(SLCAN, "COM3", 500_000, 2_000_000) # channel COM3, 500kbps, 2Mbps
iface = Interface(cfg)  
```

CAN FD on `SLCAN`, datarate can be chosen from `2000000`, `5000000`.

!!! note

    `SLCAN` with FD firmware (b158aa7) is seemd to be always on FD mode,
    thus there is **no pure CAN mode**. Therefore, even if this interface is set up for `CAN_20`, exceptionally receives `FDFrame` when someone sends that.

## SocketCAN

`SOCKETCAN` supports Linux platform.

To setup interface, 

```jl
cfg = InterfaceConfigCAN(SOCKETCAN, "can0", 0) # bitrate is ignored.
iface = Interface(cfg)
```

For CAN FD,
```jl
cfg = InterfaceConfigFD(SOCKETCAN, "can0", 0, 0) # bitrate, datarate is ignored.
iface = Interface(cfg)
```

!!! note

    Bitrate and Datarate can not be modified from CANBus library,
    so use `ip link` command from terminal.


## Vector

`VECTOR` supports Win64 platform. 

To use this interface, 
please install [Vector XL-Driver-Library](https://www.vector.com/jp/ja/products/products-a-z/libraries-drivers/xl-driver-library/#) separately. Check `vxlapi64.dll` is in your path.


```jl
cfg = InterfaceConfigCAN(VECTOR, 0, 500_000; vecor_appname="NewApp") # channel 0, 500kbps
iface = Interface(cfg)
```

`vector_appname` kwarg is always required. It means corresponding name in Vector Hardware Manager.

For CAN FD,
```jl
cfg = InterfaceConfigFD(VECTOR, 0, 500_000, 2_000_000; vecor_appname="NewApp") # channel 0, 500kbps, 2Mbps
iface = Interface(cfg)  
```

