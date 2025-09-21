```@meta
CurrentModule = CANBus
```

# CANBus.jl

*A can-bus communication package for Julia.*

## Introduction

`CANBus.jl` is a package for communicating on Controller Area Network (CAN, CANBus), supports several hardware interfaces.

## Features

* Setup device and Transmit/Receive CAN messages in unified easy way.
* Pure julia implementation, directly calls native or C apis, does not depend on other languages.
* CAN FD support.

## Installation
Install via package mode.

```julia-repl
pkg> add CANBus
```

## TODO

### Upcoming plans until v0.1.0

I'm going to:
* Support Bit-Timing configuration.
* Support do-end statement. -> done
* Add blocking-recv function. -> done
* Test Vector & Kvaser interfaces with physical hardware. -> done
* Add timestamp to frames. -> done
* Add RTR / Error frame implementation. -> done
* Reconsider data structure about CAN/CANFD distinction. -> done

### Further ahead

* Try to support PCAN-Basic API for Windows.
* Careful error-handling.
* Support other interfaces.
* Performance optimization.
* Thread-safe send (shareable send interfaces between threads).