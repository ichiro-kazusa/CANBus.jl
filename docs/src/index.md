```@meta
CurrentModule = CAN
```

# CAN.jl

*A can-bus communication package for Julia.*

## Introduction

`CAN.jl` is a package for communicating on Controller Area Network (CAN, CANbus), supports several hardware interfaces.

## Features

* Setup device and Transmit/Receive CAN messages in unified easy way.
* CAN FD support (experimental).

## Installation
Install from GitHub.

```julia-repl
pkg> add https://github.com/ichiro-kazusa/CAN.jl
```

## TODO

* supports Bit-Timings configuration
* supports other interfaces
* supports multi-threading
* supports async programming