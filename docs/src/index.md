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

### Upcoming plans until v1.0.0

* Careful error-handling.
* Add Bus state check function
* Try to support PCAN-Basic API for Windows.
* Support other interfaces.
* Performance optimization.
* Thread-safe send (shareable send interfaces between threads).