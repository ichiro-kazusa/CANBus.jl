module InterfaceCfgs

"""
Device indicator constants.

* `VECTOR`: Vector
* `KVASER`: Kvaser
* `SOCKETCAN`: SocketCAN (Linux only)
* `SLCAN`: Serial CAN (slcan)
"""
@enum DeviceType::UInt8 begin
    VECTOR
    KVASER
    SOCKETCAN
    SLCAN
end


"""
Bus type indicator constants.

* `CAN_20`: CAN 2.0
* `CAN_FD`: CAN FD (ISO compliant)
* `CAN_FD_NONISO`: CAN FD (non-ISO compliant)
"""
@enum BusType::UInt8 begin
    CAN_20
    CAN_FD
    CAN_FD_NONISO
end


"""
    AcceptanceFilter(code_id, mask)

Struct for accept filter. 
    
If this struct is set to Interface,
the id is accepted when 
`<received_id> & mask == code_id & mask`
or
`(<received_id> xor code_id) & mask == 0 `.
Those are equivalent.
"""
struct AcceptanceFilter
    code_id::UInt32
    mask::UInt32
end



"""
    InterfaceConfig(device::DeviceType, channel::Union{String,Int},
        bustype::BusType, bitrate::Int;
        datarate=nothing, silent=false,
        sample_point=70, sample_point_fd=70,
        stdfilter=nothing, extfilter=nothing,
        vector_appname="CANalyzer", slcan_serialbaud=2_000_000)

Strunct for interface configuration.
"""
struct InterfaceConfig
    device::DeviceType
    channel::Union{String,Int}
    bustype::BusType
    bitrate::Int
    datarate::Union{Nothing,Int}
    silent::Bool
    sample_point::Real
    sample_point_fd::Real
    stdfilter::Union{Nothing,AcceptanceFilter,Vector{AcceptanceFilter}}
    extfilter::Union{Nothing,AcceptanceFilter,Vector{AcceptanceFilter}}
    vector_appname::String
    slcan_serialbaud::Integer
end


"""
Always required:
* device: ::DeviceType. (`KVASER`, `SLCAN`...)
* channel: Device specific channel name(`0`, `can0`, `COM3`...).
* bustype: ::BusType. (`CAN_20`, `CAN_FD`...)

Required kwarg when bustype is `CAN_FD` or `CAN_FD_NONISO`:
* datarate

Other optional kwargs:

* `silent`: Bool. silent mode for some devices. (default: false)
* `sample_point`: Real. sample point in percentage for CAN2.0. (default: 70)
* `sample_point_fd`: Real. sample point in percentage for CAN-FD. (default: 70)
* `stdfilter`: ::AcceptanceFilter or Vector{AcceptanceFilter} or nothing. standard id filter. (default: nothing)
* `extfilter`: ::AcceptanceFilter or Vector{AcceptanceFilter} or nothing. extended id filter. (default: nothing)
* `vector_appname`: String. application name for Vector device. (default: "CANalyzer")
* `slcan_serialbaud`: Integer. serial baudrate for slcan device. (default: 2_000_000)


| Device     | silent | sample\\_point/\\_fd | std/extfilter   | vector\\_appname |
| ---------- | ------ | ---------------- | --------------- | -------------- |
| `KVASER`     |   ✓   |   ✓             |   ✓            |   ign           |
| `SLCAN`      |   ✓   |   ign            |   ign           |   ign          |
| `SOCKETCAN`  |   ign  |   ign            |   ✓            |   ign          |
| `VECTOR`     |   ✓   |   ✓             |   ✓            |   ◯           |

◯:required,
✓:supported,
ign:ignored.

See Hardwares section to see vendor specific notations.
"""
function InterfaceConfig(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int;
    datarate=nothing, silent=false,
    sample_point=70, sample_point_fd=70,
    stdfilter=nothing, extfilter=nothing,
    vector_appname="CANalyzer", slcan_serialbaud=2_000_000)

    # check validity
    if !(0 < bitrate <= 1_000_000)
        error("invalid bitrate")
    end
    if !(50 < sample_point < 100)
        error("invalid samplepoint")
    end
    if bustype in (CAN_FD, CAN_FD_NONISO)
        if datarate === nothing || datarate <= 0
            error("invalid datarate")
        end
        if !(50 < sample_point_fd < 100)
            error("invalid fd samplepoint")
        end
    end

    # construct
    InterfaceConfig(device, channel, bustype, bitrate, datarate,
        silent, sample_point, sample_point_fd,
        stdfilter, extfilter,
        vector_appname, slcan_serialbaud)
end


"""
    InterfaceConfigCAN(device::DeviceType, channel::Union{String,Int},
        bustype::BusType, bitrate::Int; kwargs...)

Helper function to construct InterfaceConfig object for CAN2.0 setup.
kwargs is same as [InterfaceConfig](@ref CANBus.InterfaceCfgs.InterfaceConfig(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)) constructor.
"""
function InterfaceConfigCAN(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int; kwargs...)::InterfaceConfig

    InterfaceConfig(device, channel, CAN_20, bitrate; kwargs...)
end


"""
    InterfaceConfigFD(device::DeviceType, channel::Union{String,Int},
        bustype::BusType, bitrate::Int, datarate::Int; kwargs...)

Helper function to construct InterfaceConfig object for CAN-FD (ISO type) setup.
kwargs is same as [InterfaceConfig](@ref CANBus.InterfaceCfgs.InterfaceConfig(device::CANBus.InterfaceCfgs.DeviceType, channel::Union{String,Int}, bustype::CANBus.InterfaceCfgs.BusType, bitrate::Int; kwargs...)) constructor.
"""
function InterfaceConfigFD(device::DeviceType, channel::Union{String,Int},
    bustype::BusType, bitrate::Int, datarate::Int; kwargs...)::InterfaceConfig

    InterfaceConfig(device, channel, CAN_FD, bitrate;
        datarate=datarate, kwargs...)
end


#= internal helper function that cfg for FD? =#
helper_isfd(cfg::InterfaceConfig) = cfg.bustype in (CAN_FD, CAN_FD_NONISO)


end # InterfaceCfgs