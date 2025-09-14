"Low level API for Kvaser CANlib SDK"
module Canlib

using StaticArrays

include("canlibdef.jl")

const canlib = "canlib32"

#########################################################
# function wrappers
#########################################################

function canInitializeLibrary()
    ccall((:canInitializeLibrary, canlib), Cvoid, ())
end

function canOpenChannel(channel::Cint, flags::Cint)::Cint
    ccall((:canOpenChannel, canlib), Cint,
        (Cint, Cint), channel, flags)
end

function canClose(handle::Cint)::canStatus
    ccall((:canClose, canlib), canStatus, (Cint,), handle)
end

function canSetBusParams(handle::Cint, freq::Clong,
    tseg1::Cuint, tseg2::Cuint, sjw::Cuint,
    noSamp::Cuint, syncmode::Cuint)::canStatus

    ccall((:canSetBusParams, canlib), canStatus,
        (Cint, Clong, Cuint, Cuint, Cuint, Cuint, Cuint),
        handle, freq, tseg1, tseg2, sjw, noSamp, syncmode)
end

function canSetBusParamsFd(handle::Cint, freq_brs::Clong,
    tseg1_brs::Cuint, tseg2_brs::Cuint, sjw_brs::Cuint)::canStatus

    ccall((:canSetBusParamsFd, canlib), canStatus,
        (Cint, Clong, Cuint, Cuint, Cuint),
        handle, freq_brs, tseg1_brs, tseg2_brs, sjw_brs)
end

function canSetBusOutputControl(handle::Cint, drivertype::Cuint)::canStatus
    ccall((:canSetBusOutputControl, canlib), canStatus,
        (Cint, Cuint),
        handle, drivertype)
end

function canGetBusOutputControl(handle::Cint, pdrivertype::Ref{Cuint})::canStatus
    ccall((:canGetBusOutputControl, canlib), canStatus,
        (Cint, Ptr{Cuint}), handle, pdrivertype)
end

function canBusOn(handle::Cint)::canStatus
    ccall((:canBusOn, canlib), canStatus, (Cint,), handle)
end

function canBusOff(handle::Cint)::canStatus
    ccall((:canBusOff, canlib), canStatus, (Cint,), handle)
end

function canWrite(handle::Cint, id::Clong,
    pmsg::Base.RefArray{Cuchar,Vector{Cuchar},Nothing},
    dlc::Cuint, flag::Cuint)::canStatus

    ccall((:canWrite, canlib), canStatus,
        (Cint, Clong, Ptr{Cuchar}, Cuint, Cuint),
        handle, id, pmsg, dlc, flag)
end

function canRead(handle::Cint, pid::Base.RefValue{Clong},
    pmsg::Base.RefArray{Cuchar,Vector{Cuchar},Nothing},
    pdlc::Base.RefValue{Cuint}, pflag::Base.RefValue{Cuint},
    ptime::Base.RefValue{Culong})::canStatus

    ccall((:canRead, canlib), canStatus,
        (Cint, Ptr{Clong}, Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Culong}),
        handle, pid, pmsg, pdlc, pflag, ptime)
end

function canSetAcceptanceFilter(handle::Cint, code::Cuint,
    mask::Cuint, is_extended::Cint)::canStatus

    ccall((:canSetAcceptanceFilter, canlib), canStatus,
        (Cint, Cuint, Cuint, Cint),
        handle, code, mask, is_extended)
end

function kvReadTimer(handle::Cint, ptime::Ref{Cuint})::canStatus
    ccall((:kvReadTimer, canlib), canStatus,
        (Cint, Ptr{Cuint}), handle, ptime)
end

function canIoCtl(hnd::Cint, func::Cuint,
    buf::Base.RefValue{UInt32}, buflen::Cuint)::canStatus

    ccall((:canIoCtl, canlib), canStatus,
        (Cint, Cuint, Ptr{Cvoid}, Cuint),
        hnd, func, buf, buflen)
end

end # Canlib
