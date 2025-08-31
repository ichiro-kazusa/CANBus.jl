```@meta
CurrentModule = CAN
```

# CAN.jl

*A can-bus communication package for Julia.*

## Introduction

`CAN.jl` is a package for communicating on Control Area Network (CAN, CANbus), supports several hardware interfaces.

## Features

* Setup device and Transmit/Receive CAN messages in unified easy way.

## Installation
Install from GitHub.

```julia-repl
pkg> add https://github.com/ichiro-kazusa/CAN.jl
```

## TODO

* supports Filters
* supports CANFD
* supports other interfaces
* supports multi-threading
* supports async programming