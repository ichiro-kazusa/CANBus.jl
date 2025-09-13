# CANBus.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ichiro-kazusa.github.io/CANBus.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ichiro-kazusa.github.io/CANBus.jl/dev/)
[![Build Status](https://github.com/ichiro-kazusa/CANBus.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ichiro-kazusa/CANBus.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ichiro-kazusa/CANBus.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ichiro-kazusa/CANBus.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)


`CANBus.jl` is a Controller Area Network (CAN Bus) communication package for julia language.

`CANBus.jl` only does communication itself.

To decode messages, use tsavelmann's [`CANalyze.jl`](https://github.com/tsabelmann/CANalyze.jl/tree/main).

At this time, this is an alpha version software. 
* Fewer supported devices.
* Several interfaces are tested only on virtual bus.
* Package behavior changes frequently.

For more details, read [documentation](https://ichiro-kazusa.github.io/CANBus.jl/stable/).

## Installation
Install via julia package mode, 

```julia-repl
pkg> add CANBus
```

## Supported hardwares at this time

* Kvaser
* slcan - tested on CANable 2.0
* SocketCAN
* Vector - requires [XL Driver Library](https://www.vector.com/int/en/download/xl-driver-library/)

### Features List

|Interface|CAN|Ext.ID|Filter|CANFD|Platform|
|----|----|----|----|----|----|
|Kvaser|✓|✓|✓|✓|Win64|
|slcan|✓|✓|NO|✓|Win64, Linux|
|SocketCAN|✓|✓|✓|✓|Linux|
|Vector|✓|✓|✓|✓|Win64|

## Example usage

### Kvaser Hardware

```jl
using CANBus

function main()
    kvaser1 = KvaserInterface(0, 500000)
    kvaser2 = KvaserInterface(1, 500000;
        extfilter=AcceptanceFilter(0x01, 0x01))

    println(kvaser1)
    println(kvaser2)

    msg = CANBus.Frame(2, [1, 1, 2, 2, 3, 3, 4], true)
    send(kvaser1, msg)

    msg = recv(kvaser2) # accept by filter
    println(msg)

    shutdown(kvaser1)
    shutdown(kvaser2)

    # use CAN FD
    kvaserfd1 = KvaserFDInterface(0, 500000, 2000000)
    kvaserfd2 = KvaserFDInterface(1, 500000, 2000000)
    println(kvaserfd1)
    println(kvaserfd2)

    msg = CANBus.FDFrame(1, collect(1:16), false, false, false)
    send(kvaserfd1, msg)

    msg = recv(kvaserfd2)
    println(msg)

    shutdown(kvaserfd1)
    shutdown(kvaserfd2)

    true
end

main()
```

Other interfaces are similar, see `examples` directory.
