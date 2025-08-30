"""
    module Vxlapi

low-level api for Vector XL Library
"""
module Vxlapi

include("xltypes.jl")

const vxlapi = "vxlapi64"

#########################################################
# function wrappers
#########################################################

function xlOpenDriver()::XLstatus
    ccall((:xlOpenDriver, vxlapi), XLstatus, (Ptr{Cvoid},), C_NULL)
end

function xlCloseDriver()::XLstatus
    ccall((:xlCloseDriver, vxlapi), XLstatus, (Ptr{Cvoid},), C_NULL)
end

function xlGetApplConfig(appName::String, appChannel::Cuint,
    pHwType::Base.RefValue{Cuint}, pHwIndex::Base.RefValue{Cuint},
    pHwChannel::Base.RefValue{Cuint}, busType::Cuint)::XLstatus

    ccall((:xlGetApplConfig, vxlapi), XLstatus,
        (Ptr{Cchar}, Cuint, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}, Cuint),
        appName, appChannel, pHwType, pHwIndex, pHwChannel, busType)
end

function xlGetChannelMask(hwType::Cint, hwIndex::Cint, hwChannel::Cint)::XLaccess
    ccall((:xlGetChannelMask, vxlapi), XLaccess,
        (Cint, Cint, Cint), hwType, hwIndex, hwChannel)
end

function xlOpenPort!(pportHandle::Base.RefValue{XLportHandle}, userName::String,
    accessMask::XLaccess, ppermissionMask::Base.RefValue{XLaccess},
    rxQueueSize::Cuint, xlInterfaceVersion::Cuint, busType::Cuint)::XLstatus

    ccall((:xlOpenPort, vxlapi), XLstatus,
        (Ptr{XLportHandle}, Ptr{Cchar}, XLaccess, Ptr{XLaccess}, Cuint, Cuint, Cuint),
        pportHandle, userName, accessMask, ppermissionMask,
        rxQueueSize, xlInterfaceVersion, busType)
end

function xlClosePort(portHandle::XLportHandle)::XLstatus
    ccall((:xlClosePort, vxlapi), XLstatus, (XLportHandle,), portHandle)
end

function xlActivateChannel(portHandle::XLportHandle, accessMask::XLaccess,
    busType::Cuint, flags::Cuint)::XLstatus

    ccall((:xlActivateChannel, vxlapi), XLstatus,
        (XLportHandle, XLaccess, Cuint, Cuint),
        portHandle, accessMask, busType, flags)
end

function xlDeactivateChannel(portHandle::XLportHandle, accessMask::XLaccess)::XLstatus
    ccall((:xlDeactivateChannel, vxlapi), XLstatus,
        (XLportHandle, XLaccess), portHandle, accessMask)
end

function xlCanSetChannelBitrate(portHandle::XLportHandle, accessMask::XLaccess, bitrate::Culong)::XLstatus
    ccall((:xlCanSetChannelBitrate, vxlapi), XLstatus,
        (XLportHandle, XLaccess, Culong),
        portHandle, accessMask, bitrate)
end

function xlReceive!(portHandle::XLportHandle, pEventCount::Base.RefValue{Cuint},
    pEventList::Base.RefArray{XLevent,Vector{XLevent},Nothing})::XLstatus

    ccall((:xlReceive, vxlapi), XLstatus,
        (XLportHandle, Ptr{Cuint}, Ptr{XLevent}),
        portHandle, pEventCount, pEventList)
end

function xlCanTransmit!(portHandle::XLportHandle, accessMask::XLaccess,
    pmessageCount::Base.RefValue{Cuint},
    pMessages::Base.RefArray{XLevent,Vector{XLevent},Nothing})::XLstatus

    ccall((:xlCanTransmit, vxlapi), XLstatus,
        (XLportHandle, XLaccess, Ptr{Cuint}, Ptr{Cvoid}),
        portHandle, accessMask, pmessageCount, pMessages)
end

end # Vxlapi