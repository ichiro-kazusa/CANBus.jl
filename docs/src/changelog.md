# Changelog

### v0.0.6

* **Breaks Compatibility**: New generic `Interface` setup API.
    * Old vendor-specific APIs are no longer available.
* Support `do`-`end` statement for `Interface`.
* Add automatic bit-timing calculation from samplepoint.
* Tested on physical hardware (Vector, Kvaser).
* bug fix: Timeout notification object is infinitely reproduced (Vector).
* bug fix: Infinite waiting when rx buffer is not empty (Vector, Slcan).
* bug fix: Handle leakage when stopping by error (all devices).

### v0.0.5

* Add receive timestamps
* Add receive timeout

### v0.0.4

* slcan (CANable2.0) support
* Redesigned `Frame` and `FDFrame` (breaks compatibility)
* Add RTR frame and ERR frame 

### v0.0.1-v0.0.3

first alpha release.

* Supports Kvaser, SocketCAN, Vector interfaces
* Supports CAN, Ext.ID.
* Supports CAN FD
* Supports Filter
