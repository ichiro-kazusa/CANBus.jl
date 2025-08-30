using Revise
import CAN.Interfaces.VectorInterfaces: Vxlapi as Vxlapi
using StaticArrays

const userName = "Canalyzer"



"""
example program to check internal low-level api "CAN.Interfaces.VectorInterfaces.Vxlapi"
"""
function main()
    status = Vxlapi.xlOpenDriver()
    println(status)

    channelMask1 = Vxlapi.xlGetChannelMask(Vxlapi.XL_HWTYPE_VIRTUAL, Cint(0), Cint(0))
    println("Mask1 ", channelMask1)
    channelMask2 = Vxlapi.xlGetChannelMask(Vxlapi.XL_HWTYPE_VIRTUAL, Cint(0), Cint(1))
    println("Mask2 ", channelMask2)

    totalMask = channelMask1 + channelMask2
    println("TotalMask: ", totalMask)

    pportHandle = Ref(Vxlapi.XLportHandle(0))
    ptotalMask = Ref(totalMask)
    status = Vxlapi.xlOpenPort!(pportHandle, userName, totalMask, ptotalMask, Cuint(16384), Vxlapi.XL_INTERFACE_VERSION, Vxlapi.XL_BUS_TYPE_CAN)
    portHandle::Vxlapi.XLportHandle = pportHandle[]
    println(status)
    println("PortHandle ", portHandle)
    println("InitAccess, ", ptotalMask[])


    status = Vxlapi.xlCanSetChannelBitrate(portHandle, totalMask, Culong(500000))
    println(status)

    # open channel 1
    status = Vxlapi.xlActivateChannel(portHandle, totalMask, Vxlapi.XL_BUS_TYPE_CAN, Vxlapi.XL_ACTIVATE_RESET_CLOCK)
    println(status)


    # communication
    # for i in 1:500000
    while true
        # transmit from ch1
        messageCount = Cuint(1)
        EventList_t = Vector{Vxlapi.XLevent}([
            Vxlapi.XLevent(Vxlapi.XL_TRANSMIT_MSG, 0, 0, 0, 0, 0, 0,
                Vxlapi.s_xl_can_msg(4, 0, 8, 0, [0, 1, 2, 3, 4, 5, 6, 7], 0))
        ])
        pMessageCount = Ref(messageCount)
        pEventList_t = Ref(EventList_t, 1)
        status = Vxlapi.xlCanTransmit!(portHandle, channelMask1, pMessageCount, pEventList_t)
        println("TransmitStatus: ", status)
        println("TXMsgCount: ", pMessageCount[])

        # receive at every ch
        pEventCount = Ref(Cuint(5))
        EventList_r = Vector{Vxlapi.XLevent}([Vxlapi.XLevent() for i in 1:pEventCount[]])
        pEventList_r = Ref(EventList_r, 1)
        status = Vxlapi.xlReceive!(portHandle, pEventCount, pEventList_r)
        println("ReceiveStatus: ", status)
        if status != Vxlapi.XL_ERR_QUEUE_IS_EMPTY
            println("RecvEventCount: ", pEventCount[])
            for i in 1:pEventCount[]
                println(EventList_r[i])
                if EventList_r[i].tag == Vxlapi.XL_RECEIVE_MSG
                    println("\tEventTag: ", EventList_r[i].tag)
                    println("\tDLC: ", EventList_r[i].tagData.dlc)
                    println("\tDATA: ", EventList_r[i].tagData.data)
                end
            end
        end

        sleep(0.5)
    end


    status = Vxlapi.xlDeactivateChannel(portHandle, totalMask)
    println(status)

    status = Vxlapi.xlClosePort(portHandle)
    println(status)


    status = Vxlapi.xlCloseDriver()
    println(status)
end

main()





