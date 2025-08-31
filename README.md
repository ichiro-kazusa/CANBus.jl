# CAN.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ichiro-kazusa.github.io/CAN.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ichiro-kazusa.github.io/CAN.jl/dev/)
[![Build Status](https://github.com/ichiro-kazusa/CAN.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/ichiro-kazusa/CAN.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/ichiro-kazusa/CAN.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ichiro-kazusa/CAN.jl)



`CAN.jl` is a Control Area Network (CAN Bus) communication package for Julia language, inspired by [`python-can`](https://github.com/hardbyte/python-can) package.

`CAN.jl` only does communication itself.
To encode/decode messages, use tsavelmann's [`CANalyze.jl`](https://github.com/tsabelmann/CANalyze.jl/tree/main)

At this time, this is an alpha version software. 
* Only CAN protocol is supported (CANFD is not supported yet).
* Several interfaces are tested only on virtual bus.
* Writing documents.
* Writing tests.


## Installation
Install from GitHub. on julia package mode, 

```
pkg> add https://github.com/ichiro-kazusa/CAN.jl
```

This package depends on `CANalyze.jl`, `StaticArrays.jl`. Install them from Julia package manager.

## Supported hardwares at this time

* Vector - requires [XL Driver Library](https://www.vector.com/int/en/download/xl-driver-library/) is installed
* Kvaser - requires [Kvaser CANlib SDK](https://kvaser.com/single-download/?download_id=47112) is installed
* SocketCAN

### Features List

|Interface|CAN|Ext.ID|Filter|CANFD|Platform|
|----|----|----|----|----|----|
|Vector|✓|✓|NO|NO|Win64|
|Kvaser|✓|✓|NO|NO|Win64|
|SocketCAN|✓|✓|NO|NO|Linux|

## Example usage

### Vector Hardware

```jl
using CAN
using CANalyze

function main()
    vector1 = VectorInterface(0, 500000, "NewApp") # specify application name in Vector Hardware Manager
    vector2 = VectorInterface(1, 500000, "NewApp")

    println(vector1)
    println(vector2)

    frame = CANalyze.CANFrame(15, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(vector1, frame)

    frame = recv(vector2) # non-blocking receive
    println(frame)

    shutdown(vector1)
    shutdown(vector2)
end

main()
```

### Kvaser Hardware

```jl
using CAN
using CANalyze

function main()
    kvaser1 = KvaserInterface(0, 500000)
    kvaser2 = KvaserInterface(1, 500000)

    println(kvaser1)
    println(kvaser2)

    frame = CANalyze.CANFrame(15, [1, 1, 2, 2, 3, 3, 4]; is_extended=true)

    send(kvaser1, frame)

    frame = recv(kvaser2) # non-blocking receive
    println(frame)

    frame = recv(kvaser2) # returns nothing
    println(frame)

    shutdown(kvaser1)
    shutdown(kvaser2)
end

main()
```

### SocketCAN

```jl
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
```