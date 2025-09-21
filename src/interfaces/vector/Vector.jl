module VectorInterfaces

import ..Interfaces
import ...Frames
import ...WinWrap

include("xlapi.jl")
import .Vxlapi

using FileWatching


"""
    VectorInterface(channel::Int, bitrate::Int, appname::String)

Setup Vector interface.
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.
* apppname: Application Name string in Vector Hardware Manager.
* silent(optional): listen only flag in bool.
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct VectorInterface <: Interfaces.AbstractCANInterface
    portHandle::Vxlapi.XLportHandle
    channelMask::Vxlapi.XLaccess
    time_offset::Float64
    notification_hnd::Vxlapi.XLhandle


    function VectorInterface(channel::Union{Int,AbstractVector{Int}},
        bitrate::Int, appname::String, rxqueuesize::Cuint=Cuint(16384);
        silent::Bool=false,
        stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
        extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)


        # init Vector CAN
        portHandle, channelMask, time_offset, notification_hnd = _init_vector(channel, bitrate, appname,
            rxqueuesize, silent, stdfilter, extfilter,
            false, false, 0)

        new(portHandle, channelMask, time_offset, notification_hnd)
    end
end


"""
    VectorFDInterface(channel::Int, bitrate::Int, datarate::Int, appname::String)

Setup Vector interface for CAN FD.
* channel: channel number in integer.
* bitrate: bitrate as bit/s in integer.
* datarate: datarate as bit/s in integer.
* apppname: Application Name string in Vector Hardware Manager.
* non_iso(optional): use non-iso version of CAN FD
* silent(optional): listen only flag in bool.
* stdfilter(optional): standard ID filter in AcceptanceFilter struct.
* extfilter(optional): extended ID filter in AcceptanceFilter struct.
"""
struct VectorFDInterface <: Interfaces.AbstractCANInterface
    portHandle::Vxlapi.XLportHandle
    channelMask::Vxlapi.XLaccess
    time_offset::Float64
    notification_hnd::Vxlapi.XLhandle


    function VectorFDInterface(channel::Union{Int,AbstractVector{Int}},
        bitrate::Int, datarate::Int, appname::String, rxqueuesize::Cuint=Cuint(262144);
        non_iso::Bool=false, silent::Bool=false,
        stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
        extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)


        # init Vector CAN
        portHandle, channelMask, time_offset, notification_hnd = _init_vector(channel, bitrate, appname,
            rxqueuesize, silent, stdfilter, extfilter,
            true, non_iso, datarate)

        new(portHandle, channelMask, time_offset, notification_hnd)
    end
end


function VectorInterface(f::Function, args...; kwargs...)
    # constructor for do-block
    bus = VectorInterface(args...; kwargs...)
    try
        return f(bus)
    finally
        Interfaces.shutdown(bus)
    end
end



function VectorFDInterface(f::Function, args...; kwargs...)
    # constructor for do-block
    bus = VectorFDInterface(args...; kwargs...)
    try
        return f(bus)
    finally
        Interfaces.shutdown(bus)
    end
end


function _init_vector(channel::Union{Int,AbstractVector{Int}},
    bitrate::Int, appname::String, rxqueuesize::Cuint, silent::Bool,
    stdfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    extfilter::Union{Nothing,Interfaces.AcceptanceFilter},
    fd::Bool, non_iso::Bool, datarate::Int)::Tuple{Vxlapi.XLportHandle,Vxlapi.XLaccess,Float64,Vxlapi.XLhandle}

    # open driver
    status = Vxlapi.xlOpenDriver()

    # search channel & get channel mask
    channelMask = _get_channel_mask(channel, appname)

    # open port
    pportHandle = Ref(Vxlapi.XLportHandle(0))
    pchannelMask = Ref(channelMask)
    ifv = fd ? Vxlapi.XL_INTERFACE_VERSION_V4 : Vxlapi.XL_INTERFACE_VERSION
    status = Vxlapi.xlOpenPort!(pportHandle, appname,
        channelMask, pchannelMask, rxqueuesize,
        ifv, Vxlapi.XL_BUS_TYPE_CAN)
    if status != Vxlapi.XL_SUCCESS
        throw(ErrorException("Vector: Failed to open port."))
    end

    # set filter
    if stdfilter !== nothing
        Vxlapi.xlCanSetChannelAcceptance(pportHandle[], channelMask,
            stdfilter.code_id, stdfilter.mask, Vxlapi.XL_CAN_STD)
    end
    if extfilter !== nothing
        Vxlapi.xlCanSetChannelAcceptance(pportHandle[], channelMask,
            extfilter.code_id, extfilter.mask, Vxlapi.XL_CAN_EXT)
    end

    # set bitrate
    local status::Vxlapi.XLstatus
    if fd
        fdconf = Vxlapi.XLcanFdConf(UInt32(bitrate), UInt32(datarate), non_iso)
        pfdconf = Ref(fdconf)
        status = Vxlapi.xlCanFdSetConfiguration(pportHandle[], channelMask, pfdconf)
    else
        status = Vxlapi.xlCanSetChannelBitrate(pportHandle[], channelMask, Culong(bitrate))
    end
    if status != Vxlapi.XL_SUCCESS
        error("Vector: failed to set bitrate. $status")
    end

    # set silent
    flag = silent ? Vxlapi.XL_OUTPUT_MODE_SILENT : Vxlapi.XL_OUTPUT_MODE_NORMAL
    status = Vxlapi.xlCanSetChannelOutput(pportHandle[], channelMask, flag)

    # activate channels
    status = Vxlapi.xlActivateChannel(pportHandle[], channelMask,
        Vxlapi.XL_BUS_TYPE_CAN, Vxlapi.XL_ACTIVATE_RESET_CLOCK)


    # get time offset
    status = Vxlapi.xlResetClock(pportHandle[])
    if status != Vxlapi.XL_SUCCESS
        error("Vector: clock reset failed. $status")
    end
    time_offset = time() # assume device clock is 0.

    # retrieve notirication object for timeout waiting
    r_hnd = Ref{Vxlapi.XLhandle}()
    st = Vxlapi.xlSetNotification(pportHandle[], r_hnd, Cint(1))
    if st != Vxlapi.XL_SUCCESS
        error("Vector: poll notifier set failed. $st")
    end

    return pportHandle[], channelMask, time_offset, r_hnd[]
end


function Interfaces.send(interface::VectorInterface, msg::Frames.Frame)
    # construct XLEvent
    messageCount = Cuint(1)
    dlc = size(msg.data, 1)
    data_pad = zeros(Cuchar, Vxlapi.MAX_MSG_LEN)
    data_pad[1:dlc] .= msg.data
    id = msg.is_extended ? msg.id | Vxlapi.XL_CAN_EXT_MSG_ID : msg.id
    can_msg_flag = msg.is_remote_frame ? Vxlapi.XL_CAN_MSG_FLAG_REMOTE_FRAME : Cushort(0)


    # construct XLEvent
    EventList_t = Vector{Vxlapi.XLevent}([
        Vxlapi.XLevent(Vxlapi.XL_TRANSMIT_MSG, 0, 0, 0, 0, 0, 0,
            Vxlapi.s_xl_can_msg(id, can_msg_flag, dlc, 0, (data_pad...,), 0))
        for i in 1:messageCount])

    # send message
    pMessageCount = Ref(messageCount)
    pEventList_t = Ref(EventList_t, 1)
    status = Vxlapi.xlCanTransmit!(interface.portHandle, interface.channelMask, pMessageCount, pEventList_t)

    if status != Vxlapi.XL_SUCCESS || pMessageCount[] != messageCount
        error("Vector: Failed to transmit.")
    end

    return nothing
end


function Interfaces.send(interface::VectorFDInterface, msg::T) where {T<:Union{Frames.Frame,Frames.FDFrame}}
    canid = msg.is_extended ? msg.id | Vxlapi.XL_CAN_EXT_MSG_ID : msg.id
    len = length(msg)
    dlc = len <= 8 ? len : Vxlapi.CANFD_LEN2DLC[len]
    data_pad = zeros(Cuchar, Vxlapi.XL_CAN_MAX_DATA_LEN)
    data_pad[1:len] .= msg.data

    flags = Cuint(0)
    if T == Frames.FDFrame
        flags |= Vxlapi.XL_CAN_TXMSG_FLAG_EDL
        flags |= msg.bitrate_switch ? Vxlapi.XL_CAN_TXMSG_FLAG_BRS : Cuint(0)
    else # classic frame
        flags |= msg.is_remote_frame ? Vxlapi.XL_CAN_TXMSG_FLAG_RTR : Cuint(0)
    end

    event = Vxlapi.XLcanTxEvent(Vxlapi.XL_CAN_EV_TAG_TX_MSG, 0, 0, (zeros(Cuchar, 3)...,),
        Vxlapi.XL_CAN_TX_MSG(canid, flags, dlc, (zeros(Cuchar, 7)...,), (data_pad...,)))
    pevent = Ref(event)
    pMsgCntSent = Ref(Cuint(0))

    status = Vxlapi.xlCanTransmitEx!(interface.portHandle, interface.channelMask,
        Cuint(1), pMsgCntSent, pevent)
    if status != Vxlapi.XL_SUCCESS || pMsgCntSent[] != 1
        error("Vector: Failed to transmit.")
    end

    return nothing
end


function Interfaces.recv(interface::VectorInterface; timeout_s::Real=0)::Union{Nothing,Frames.Frame}

    # poll
    _poll(interface, timeout_s)

    # prepare to receive
    pEventCount = Ref(Cuint(1))
    EventList_r = Vector{Vxlapi.XLevent}([Vxlapi.XLevent() for i in 1:pEventCount[]])
    pEventList_r = Ref(EventList_r, 1)

    status = Vxlapi.xlReceive!(interface.portHandle, pEventCount, pEventList_r)

    if status != Vxlapi.XL_ERR_QUEUE_IS_EMPTY
        if EventList_r[1].tag == Vxlapi.XL_RECEIVE_MSG

            timestamp = interface.time_offset + EventList_r[1].timeStamp * 1.e-9 # nsec -> sec

            # split id to extended flag
            totalid = EventList_r[1].tagData.id
            isext = (totalid & Vxlapi.XL_CAN_EXT_MSG_ID) != 0
            id = isext ? totalid - Vxlapi.XL_CAN_EXT_MSG_ID : totalid
            isrtr = (EventList_r[1].tagData.flags & Vxlapi.XL_CAN_MSG_FLAG_REMOTE_FRAME) != 0
            iserr = (EventList_r[1].tagData.flags & Vxlapi.XL_CAN_MSG_FLAG_ERROR_FRAME) != 0

            # frame
            frame = Frames.Frame(
                id,
                collect(EventList_r[1].tagData.data[1:EventList_r[1].tagData.dlc]);
                is_extended=isext, is_remote_frame=isrtr, is_error_frame=iserr,
                timestamp=timestamp
            )
            return frame
        end
    end
    return nothing
end


function Interfaces.recv(interface::VectorFDInterface; timeout_s::Real=0)::Union{Nothing,Frames.AnyFrame}

    # poll
    _poll(interface, timeout_s)

    # receive    
    canrxevt = Vxlapi.XLcanRxEvent(0, 0, 0, 0, 0, 0, 0, 0, 0,
        Vxlapi.XL_CAN_EV_RX_MSG(0, 0, 0, (zeros(Cuchar, 12)...,), 0, 0,
            (zeros(Cuchar, 5)...,), (zeros(Cuchar, Vxlapi.XL_CAN_MAX_DATA_LEN)...,)))
    pcanrxevt = Ref(canrxevt)

    status = Vxlapi.xlCanReceive!(interface.portHandle, pcanrxevt)

    if status == Vxlapi.XL_ERR_QUEUE_IS_EMPTY
        return nothing
    elseif status == Vxlapi.XL_SUCCESS
        if pcanrxevt[].tag == Vxlapi.XL_CAN_EV_TAG_RX_OK

            timestamp = interface.time_offset + pcanrxevt[].timeStampSync * 1.e-9

            dlc = pcanrxevt[].tagData.dlc
            len = dlc <= 8 ? dlc : Vxlapi.CANFD_DLC2LEN[dlc]
            isext = (pcanrxevt[].tagData.canId & Vxlapi.XL_CAN_EXT_MSG_ID) != 0
            id = isext ? pcanrxevt[].tagData.canId - Vxlapi.XL_CAN_EXT_MSG_ID : pcanrxevt[].tagData.canId
            isfd = (pcanrxevt[].tagData.msgFlags & Vxlapi.XL_CAN_RXMSG_FLAG_EDL) != 0
            isbrs = (pcanrxevt[].tagData.msgFlags & Vxlapi.XL_CAN_RXMSG_FLAG_BRS) != 0
            isesi = (pcanrxevt[].tagData.msgFlags & Vxlapi.XL_CAN_RXMSG_FLAG_ESI) != 0
            isrtr = (pcanrxevt[].tagData.msgFlags & Vxlapi.XL_CAN_RXMSG_FLAG_RTR) != 0
            iserr = (pcanrxevt[].tagData.msgFlags & Vxlapi.XL_CAN_RXMSG_FLAG_EF) != 0

            if isfd
                msg = Frames.FDFrame(id, collect(pcanrxevt[].tagData.data[1:len]);
                    is_extended=isext, bitrate_switch=isbrs, error_state=isesi,
                    is_error_frame=iserr, timestamp=timestamp)
                return msg
            else
                msg = Frames.Frame(id, collect(pcanrxevt[].tagdata.data[1:len]);
                    is_extended=isext, is_remote_frame=isrtr,
                    is_error_frame=iserr, timestamp=timestamp)
                return msg
            end
        end
    end
    error("Vector: receive failed. $status")
end


function Interfaces.shutdown(interface::T) where {T<:Union{VectorInterface,VectorFDInterface}}
    status = Vxlapi.xlDeactivateChannel(interface.portHandle, interface.channelMask)
    status = Vxlapi.xlClosePort(interface.portHandle)
    status = Vxlapi.xlCloseDriver()
    return nothing
end


function _get_channel_mask(channel::Union{Int,AbstractVector{Int}}, appname::String)
    # search HwIndex/HwChannel from appChannel
    local channels::Vector{Cuint}
    if isa(channel, Int)
        channels = [channel]
    else
        channels = channel
    end
    hwInfo::Vector{NTuple{3,Cint}} = []
    for ch in channels
        pHwType = Ref{Cuint}(0)
        pHwIndex = Ref{Cuint}(0)
        pHwChannel = Ref{Cuint}(0)
        status = Vxlapi.xlGetApplConfig(appname, ch,
            pHwType, pHwIndex, pHwChannel, Vxlapi.XL_BUS_TYPE_CAN)
        if status != Vxlapi.XL_SUCCESS
            throw(ErrorException("Vector: CH=$ch does not exist. Check channel index or application name."))
        end
        push!(hwInfo, (Cint(pHwType[]), Cint(pHwIndex[]), Cint(pHwChannel[])))
    end

    # get channel masks
    channelMask = Vxlapi.XLaccess(0)
    for info in hwInfo
        channelMask += Vxlapi.xlGetChannelMask(info...)
    end

    channelMask
end


function _poll(interface::T, timeout_s::Real) where {T<:Union{VectorInterface,VectorFDInterface}}
    # block until frame comes or timeout
    if timeout_s != 0
        WinWrap.WaitForSingleObject(interface.notification_hnd, Culong(timeout_s * 1e3))
    end
end


end # VectorInterfaces