module Errors


"""
    abstract type CANBusError <: Exception end

Base type of error exception of `CANBus.jl`
"""
abstract type CANBusError <: Exception end


"""
    struct CANBusValueError <: CANBusError
        msg::String
        context::String
    end

This error is thrown when passed value is invalid on specific context.
"""
struct CANBusValueError <: CANBusError
    msg::String
    context::String
end


"""
    struct CANBusOpenError <: CANBusError
        msg::String
        device::String
        status::String
    end

This error is thrown when interface initialization function.

It's status code(3rd entry) is native error code of device driver.
"""
struct CANBusOpenError <: CANBusError
    msg::String
    device::String
    status::String
end


"""
    struct CANBusIOError <: CANBusError
        msg::String
        context::String
        device::String
        status::String
    end

This error is thrown when interface operation is failed.

It's status code(4th entry) is native error code of device driver.
"""
struct CANBusIOError <: CANBusError
    msg::String
    context::String
    device::String
    status::String
end


"""
    struct CANBusNotImplementedError <: CANBusError
        msg::String
    end

This error is thrown when api is not implemented for specific device.
"""
struct CANBusNotImplementedError <: CANBusError
    msg::String
end


end # Errors