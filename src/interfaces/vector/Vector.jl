module VectorInterfaces

using CANalyze
import ..Interfaces

include("xlapi.jl")
import .Vxlapi



"""
    VectorInterface(channel::Int, bitrate::Int, appname::String)

Setup Vector interface with channel number, bitrate(bps), application name.
"""
struct VectorInterface <: Interfaces.AbstractCANInterface
    portHandle::Vxlapi.XLportHandle
    channelMask::Vxlapi.XLaccess


    function VectorInterface(channel::Union{Int,AbstractVector{Int}},
        bitrate::Int, appname::String, rxqueuesize::Cuint=Cuint(16384);
        fd::Bool=false,
        stdfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing,
        extfilter::Union{Nothing,Interfaces.AcceptanceFilter}=nothing)

        # open driver
        status = Vxlapi.xlOpenDriver()

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
                Vxlapi.xlCloseDriver()
                throw(ErrorException("Vector: CH=$ch does not exist. Check channel index or application name."))
            end
            push!(hwInfo, (Cint(pHwType[]), Cint(pHwIndex[]), Cint(pHwChannel[])))
        end

        # get channel masks
        channelMask = Vxlapi.XLaccess(0)
        for info in hwInfo
            channelMask += Vxlapi.xlGetChannelMask(info...)
        end

        # open port
        pportHandle = Ref(Vxlapi.XLportHandle(0))
        pchannelMask = Ref(channelMask)
        status = Vxlapi.xlOpenPort!(pportHandle, appname, channelMask, pchannelMask, rxqueuesize, Vxlapi.XL_INTERFACE_VERSION, Vxlapi.XL_BUS_TYPE_CAN)
        if status != Vxlapi.XL_SUCCESS
            Vxlapi.xlCloseDriver()
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
        status = Vxlapi.xlCanSetChannelBitrate(pportHandle[], channelMask, Culong(bitrate))

        # activate channels
        status = Vxlapi.xlActivateChannel(pportHandle[], channelMask, Vxlapi.XL_BUS_TYPE_CAN, Vxlapi.XL_ACTIVATE_RESET_CLOCK)


        new(pportHandle[], channelMask)
    end

end


function Interfaces.send(interface::VectorInterface, frame::CANalyze.CANFrame)
    # construct XLEvent
    messageCount = Cuint(1)
    dlc = size(frame.data, 1)
    data_pad = zeros(Cuchar, Vxlapi.MAX_MSG_LEN)
    data_pad[1:dlc] .= frame.data
    id = frame.is_extended ? frame.frame_id |= Vxlapi.XL_CAN_EXT_MSG_ID : frame.frame_id

    # construct XLEvent
    EventList_t = Vector{Vxlapi.XLevent}([
        Vxlapi.XLevent(Vxlapi.XL_TRANSMIT_MSG, 0, 0, 0, 0, 0, 0,
            Vxlapi.s_xl_can_msg(id, 0, dlc, 0, data_pad, 0))
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


function Interfaces.recv(interface::VectorInterface)::Union{Nothing,CANalyze.CANFrame}
    pEventCount = Ref(Cuint(1))
    EventList_r = Vector{Vxlapi.XLevent}([Vxlapi.XLevent() for i in 1:pEventCount[]])
    pEventList_r = Ref(EventList_r, 1)

    status = Vxlapi.xlReceive!(interface.portHandle, pEventCount, pEventList_r)

    if status != Vxlapi.XL_ERR_QUEUE_IS_EMPTY
        if EventList_r[1].tag == Vxlapi.XL_RECEIVE_MSG
            # split id to extended flag
            totalid = EventList_r[1].tagData.id
            isext = (totalid & Vxlapi.XL_CAN_EXT_MSG_ID) != 0
            id = isext ? totalid - Vxlapi.XL_CAN_EXT_MSG_ID : totalid

            # frame
            frame = CANalyze.CANFrame(
                id,
                EventList_r[1].tagData.data[1:EventList_r[1].tagData.dlc],
                is_extended=isext
            )
            return frame
        end
    end
    return nothing
end


function Interfaces.shutdown(interface::VectorInterface)
    status = Vxlapi.xlDeactivateChannel(interface.portHandle, interface.channelMask)
    status = Vxlapi.xlClosePort(interface.portHandle)
    status = Vxlapi.xlCloseDriver()
    return nothing
end


end # VectorInterfaces