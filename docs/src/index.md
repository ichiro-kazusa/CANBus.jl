```@meta
CurrentModule = CANBus
```

# CANBus.jl

*A can-bus communication package for Julia.*

## Introduction

`CANBus.jl` is a package for communicating on Controller Area Network (CAN, CANbus), supports several hardware interfaces.

## Features

* Setup device and Transmit/Receive CAN messages in unified easy way.
* CAN FD support (experimental).

## Installation
Install in package mode.

```julia-repl
pkg> add CANBus
```

## TODO

* supports Bit-Timings configuration
* supports other interfaces
* supports multi-threading
* supports async programming
* performance optimization