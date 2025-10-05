# CANBus.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ichiro-kazusa.github.io/CANBus.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ichiro-kazusa.github.io/CANBus.jl/dev/)
[![Build Status](https://github.com/ichiro-kazusa/CANBus.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ichiro-kazusa/CANBus.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
<!-- [![Coverage](https://codecov.io/gh/ichiro-kazusa/CANBus.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ichiro-kazusa/CANBus.jl) -->


`CANBus.jl` is a Controller Area Network (CAN Bus) communication package for julia language.

`CANBus.jl` only does communication itself.

To decode messages, use tsavelmann's [`CANalyze.jl`](https://github.com/tsabelmann/CANalyze.jl/tree/main).

At this time, this is an alpha version software. 
* Fewer supported devices.
* Basic tests has been conducted, but further testing is needed under broader conditions.
* Only basic error handling is performed.

For more details, read [documentation](https://ichiro-kazusa.github.io/CANBus.jl/stable/).

## Features

* Setup device and Transmit/Receive CAN messages in unified easy way.
* Pure julia implementation, directly calls native or C apis, does not depend on other languages.
* CAN FD support.

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

## Example usage

```julia
using CANBus

function main()
    bustype = CAN_FD
    device = VECTOR

    ch0 = 0
    ch1 = 1

    # -------------------------------------

    ifcfg1 = InterfaceConfig(device, ch0, bustype, 500000;
        datarate=2000000, vector_appname="NewApp")

    f = AcceptanceFilter(0x02, 0x02)

    ifcfg2 = InterfaceConfig(device, ch1, bustype, 500000;
        datarate=2000000, vector_appname="NewApp", stdfilter=f)

    iface1 = Interface(ifcfg1)
    Interface(ifcfg2) do iface2 # do-end example

        frm1 = Frame(0x02, [00, 01, 02, 03, 04, 05])
        frm2 = FDFrame(0x02, collect(1:12); is_extended=true)
        send(iface1, frm1)
        send(iface1, frm2)

        sleep(0.1)

        ret1 = recv(iface2; timeout_s=1)
        println(ret1)

        ret2 = recv(iface2; timeout_s=1)
        println(ret2)

    end
    shutdown(iface1)

end

main()
```

Other interfaces are similar, see `examples` directory.
