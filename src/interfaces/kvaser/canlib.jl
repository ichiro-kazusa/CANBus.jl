"""
    module Canlib

low-level api for Kvaser canlib sdk
"""
module Canlib

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

function canSetBusOutputControl(handle::Cint, drivertype::Cuint)::canStatus
    ccall((:canSetBusOutputControl, canlib), canStatus,
        (Cint, Cuint),
        handle, drivertype)
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
    pmsg::Base.RefArray{Cchar,Vector{Cchar},Nothing},
    pdlc::Base.RefValue{Cuint}, pflag::Base.RefValue{Cuint},
    ptime::Base.RefValue{Culong})::canStatus

    ccall((:canRead, canlib), canStatus,
        (Cint, Ptr{Clong}, Ptr{Cchar}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Culong}),
        handle, pid, pmsg, pdlc, pflag, ptime)
end

end # Canlib
