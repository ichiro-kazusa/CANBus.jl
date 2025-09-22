# Supported Hardwares

This section describes basic usage for each supported hardwares.

## Kvaser

`KvaserInterface` supports Win64 platform.

This interface requires `canlib32.dll` (should be installed along with the device driver). 

To setup interface, do something like below,

```jl
using CANBus

kvaser0 = KvaserInterface(0, 500000)  # channel 0, 500kbps
```

For CAN FD,
```jl
kvaser0 = KvaserFDInterface(0, 500000, 2000000)  # channel 0, 500kbps, 2Mbps
```

`send`, `recv`, `shutdown` functions can be use.


## slcan

`SlcanInterface` supports Win64/Linux platform. Tested on [CANable 2.0](https://canable.io/) firmware.

To setup interface, 

```jl
using CANBus

slcan0 = SlcanInterface("COM3", 1000000)  # for Linux, e.g. "/dev/ttyACM0"
```

For CAN FD,
```jl
slcan0 = SocketCANFDInterface("COM3", 1000000, 2000000) # bitrate 1Mbps, datarate 2Mbps
```

CAN FD on `slcan`, datarate can be chosen from `2000000`, `5000000`.


## SocketCAN

`SocketCANInterface` supports Linux platform.

To setup interface, 

```jl
using CANBus

sockcan0 = SocketCANInterface("can0")  # channel "can0"
```

For CAN FD,
```jl
sockcan0 = SocketCANFDInterface("can0")  # channel "can0"
```


`send`, `recv`, `shutdown` functions can be use.

Bitrate can not be modified from socket api, use `ip link` command from terminal.


## Vector

`VectorInterface` supports Win64 platform. 

In this time, author does not get permission to distribute DLLs. So to use this interface, 
please install [Vector XL-Driver-Library](https://www.vector.com/jp/ja/products/products-a-z/libraries-drivers/xl-driver-library/#) separately. Check `vxlapi64.dll` is in your path.

```jl
using CANBus

vector1 = VectorInterface(0, 500000, "NewApp") # channel 0, 500kbps, application name
```

"Application name" means corresponding name in Vector Hardware Manager.

For CAN FD,
```jl
vector1 = VectorFDInterface(0, 500000, 2000000, "NewApp")
# channel 0, 500kbps, 2Mbps, application name
```


`send`, `recv`, `shutdown` functions can be use.
