# Changelog

### v0.1.0

first beta release.

* Support do-end statement.
* Add automatic bittiming calculation from samplepoint.
* Tested on physical hardware (Vector, Kvaser).
* bug fix: Timeout notification object is infinitely reproduced in Vector.
* bug fix: Timeout behavior when rx buffer is not empty in Vector, Slcan

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
