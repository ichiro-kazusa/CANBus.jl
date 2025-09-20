#########################################################
# in module Vxlapi
#########################################################


const HANDLE = Ptr{Cvoid}

const XLlong = Clong
const XLuint64 = Culonglong
const XLaccess = XLuint64
const XLstatus = Cshort
const XLportHandle = XLlong
const XLeventTag = Cuchar
const XLhandle = HANDLE

const MAX_MSG_LEN = 8
const XL_CAN_MAX_DATA_LEN = 64
const XL_CANFD_RX_EVENT_HEADER_SIZE = 32
const XL_CANFD_MAX_EVENT_SIZE = 128


@kwdef struct s_xl_can_msg # 32bytes
    id::Culong = 0
    flags::Cushort = 0
    dlc::Cushort = 0
    resl::XLuint64 = 0
    data::NTuple{MAX_MSG_LEN,Cuchar} = (zeros(Cuchar, MAX_MSG_LEN)...,)
    res2::XLuint64 = 0
end

@kwdef struct XLevent # 48 bytes
    tag::XLeventTag = 0
    chanIndex::Cuchar = 0
    transId::Cushort = 0
    portHandle::Cushort = 0
    flags::Cuchar = 0
    reserved::Cuchar = 0
    timeStamp::XLuint64 = 0
    tagData::s_xl_can_msg = s_xl_can_msg() # this is union originally, but this package focuses on CANBus.
end


struct XLcanFdConf
    arbitrationBitRate::Cuint
    sjwAbr::Cuint
    tseg1Abr::Cuint
    tseg2Abr::Cuint
    dataBitRate::Cuint
    sjwDbr::Cuint
    tseg1Dbr::Cuint
    tseg2Dbr::Cuint
    reserved::Cuchar
    options::Cuchar
    reserved1::NTuple{2,Cuchar}
    reserved2::Cuint

    function XLcanFdConf(bitrate::Cuint, datarate::Cuint, non_iso::Bool)
        flag = non_iso ? CANFD_CONFOPT_NO_ISO : Cuchar(0)
        new(bitrate, 2, 6, 3, datarate, 2, 6, 3, 0, flag, (0, 0), 0)
    end
end


struct XL_CAN_TX_MSG
    canId::Cuint
    msgFlags::Cuint
    dlc::Cuchar
    reserved::NTuple{7,Cuchar}
    data::NTuple{XL_CAN_MAX_DATA_LEN,Cuchar}
end


struct XLcanTxEvent
    tag::Cushort
    transId::Cushort
    channelIndex::Cuchar
    reserved::NTuple{3,Cuchar}
    canMsg::XL_CAN_TX_MSG
end


struct XL_CAN_EV_RX_MSG
    canId::Cuint
    msgFlags::Cuint
    crc::Cuint
    reserved1::NTuple{12,Cuchar}
    totalBitCnt::Cushort
    dlc::Cuchar
    reserved::NTuple{5,Cuchar}
    data::NTuple{XL_CAN_MAX_DATA_LEN,Cuchar}
end


struct XLcanRxEvent
    size::Cuint
    tag::Cushort
    channelIndex::Cuchar
    reserved::Cuchar
    userHandle::Cuint
    flagsChip::Cushort
    reserved0::Cushort
    reserved1::XLuint64
    timeStampSync::XLuint64
    tagData::XL_CAN_EV_RX_MSG
end


const CANFD_LEN2DLC::Dict{Int,Int} = Dict([
    12 => 9, 16 => 10, 20 => 11, 24 => 12,
    32 => 13, 48 => 14, 64 => 15
])

const CANFD_DLC2LEN::Dict{Int,Int} = Dict([
    9 => 12, 10 => 16, 11 => 20, 12 => 24,
    13 => 32, 14 => 48, 15 => 64
])


#//////////////////////////////////////////////////////////////////////////////
# driver status
const XL_SUCCESS::XLstatus = 0                          # =0x0000
const XL_PENDING::XLstatus = 1                          # =0x0001
#
const XL_ERR_QUEUE_IS_EMPTY::XLstatus = 10              # =0x000A
const XL_ERR_QUEUE_IS_FULL::XLstatus = 11               # =0x000B
const XL_ERR_TX_NOT_POSSIBLE::XLstatus = 12             # =0x000C
const XL_ERR_NO_LICENSE::XLstatus = 14                  # =0x000E
const XL_ERR_WRONG_PARAMETER::XLstatus = 101            # =0x0065
const XL_ERR_TWICE_REGISTER::XLstatus = 110             # =0x006E
const XL_ERR_INVALID_CHAN_INDEX::XLstatus = 111         # =0x006F
const XL_ERR_INVALID_ACCESS::XLstatus = 112             # =0x0070
const XL_ERR_PORT_IS_OFFLINE::XLstatus = 113            # =0x0071
const XL_ERR_CHAN_IS_ONLINE::XLstatus = 116             # =0x0074
const XL_ERR_NOT_IMPLEMENTED::XLstatus = 117            # =0x0075
const XL_ERR_INVALID_PORT::XLstatus = 118               # =0x0076
const XL_ERR_HW_NOT_READY::XLstatus = 120               # =0x0078
const XL_ERR_CMD_TIMEOUT::XLstatus = 121                # =0x0079
const XL_ERR_CMD_HANDLING::XLstatus = 122               # =0x007A
const XL_ERR_HW_NOT_PRESENT::XLstatus = 129             # =0x0081
const XL_ERR_NOTIFY_ALREADY_ACTIVE::XLstatus = 131      # =0x0083
const XL_ERR_INVALID_TAG::XLstatus = 132                # =0x0084
const XL_ERR_INVALID_RESERVED_FLD::XLstatus = 133       # =0x0085
const XL_ERR_INVALID_SIZE::XLstatus = 134               # =0x0086
const XL_ERR_INSUFFICIENT_BUFFER::XLstatus = 135        # =0x0087
const XL_ERR_ERROR_CRC::XLstatus = 136                  # =0x0088
const XL_ERR_BAD_EXE_FORMAT::XLstatus = 137             # =0x0089
const XL_ERR_NO_SYSTEM_RESOURCES::XLstatus = 138        # =0x008A
const XL_ERR_NOT_FOUND::XLstatus = 139                  # =0x008B
const XL_ERR_INVALID_ADDRESS::XLstatus = 140            # =0x008C
const XL_ERR_REQ_NOT_ACCEP::XLstatus = 141              # =0x008D
const XL_ERR_INVALID_LEVEL::XLstatus = 142              # =0x008E
const XL_ERR_NO_DATA_DETECTED::XLstatus = 143           # =0x008F
const XL_ERR_INTERNAL_ERROR::XLstatus = 144             # =0x0090
const XL_ERR_UNEXP_NET_ERR::XLstatus = 145              # =0x0091
const XL_ERR_INVALID_USER_BUFFER::XLstatus = 146        # =0x0092
const XL_ERR_INVALID_PORT_ACCESS_TYPE::XLstatus = 147   # =0x0093
const XL_ERR_NO_RESOURCES::XLstatus = 152               # =0x0098
const XL_ERR_WRONG_CHIP_TYPE::XLstatus = 153            # =0x0099
const XL_ERR_WRONG_COMMAND::XLstatus = 154              # =0x009A
const XL_ERR_INVALID_HANDLE::XLstatus = 155             # =0x009B
const XL_ERR_RESERVED_NOT_ZERO::XLstatus = 157          # =0x009D
const XL_ERR_INIT_ACCESS_MISSING::XLstatus = 158        # =0x009E
const XL_ERR_WRONG_VERSION::XLstatus = 160              # =0x00A0
const XL_ERR_ALREADY_EXISTS::XLstatus = 183             # =0x00B7
const XL_ERR_CANNOT_OPEN_DRIVER::XLstatus = 201         # =0x00C9
const XL_ERR_WRONG_BUS_TYPE::XLstatus = 202             # =0x00CA
const XL_ERR_DLL_NOT_FOUND::XLstatus = 203              # =0x00CB
const XL_ERR_INVALID_CHANNEL_MASK::XLstatus = 204       # =0x00CC
const XL_ERR_NOT_SUPPORTED::XLstatus = 205              # =0x00CD
# special stream defines
const XL_ERR_CONNECTION_BROKEN::XLstatus = 210          # =0x00D2
const XL_ERR_CONNECTION_CLOSED::XLstatus = 211          # =0x00D3
const XL_ERR_INVALID_STREAM_NAME::XLstatus = 212        # =0x00D4
const XL_ERR_CONNECTION_FAILED::XLstatus = 213          # =0x00D5
const XL_ERR_STREAM_NOT_FOUND::XLstatus = 214           # =0x00D6
const XL_ERR_STREAM_NOT_CONNECTED::XLstatus = 215       # =0x00D7
const XL_ERR_QUEUE_OVERRUN::XLstatus = 216              # =0x00D8
const XL_ERROR::XLstatus = 255                          # =0x00FF



#------------------------------------------------------------------------------
# defines for the supported hardware
const XL_HWTYPE_NONE::Cint = 0
const XL_HWTYPE_VIRTUAL::Cint = 1
const XL_HWTYPE_CANCARDX::Cint = 2
const XL_HWTYPE_CANAC2PCI::Cint = 6
const XL_HWTYPE_CANCARDY::Cint = 12
const XL_HWTYPE_CANCARDXL::Cint = 15
const XL_HWTYPE_CANCASEXL::Cint = 21
const XL_HWTYPE_CANCASEXL_LOG_OBSOLETE::Cint = 23
const XL_HWTYPE_CANBOARDXL::Cint = 25  # CANboardXL, CANboardXL PCIe
const XL_HWTYPE_CANBOARDXL_PXI::Cint = 27  # CANboardXL pxi
const XL_HWTYPE_VN2600::Cint = 29
const XL_HWTYPE_VN2610::Cint = XL_HWTYPE_VN2600
const XL_HWTYPE_VN3300::Cint = 37
const XL_HWTYPE_VN3600::Cint = 39
const XL_HWTYPE_VN7600::Cint = 41
const XL_HWTYPE_CANCARDXLE::Cint = 43
const XL_HWTYPE_VN8900::Cint = 45
const XL_HWTYPE_VN8950::Cint = 47
const XL_HWTYPE_VN2640::Cint = 53
const XL_HWTYPE_VN1610::Cint = 55
const XL_HWTYPE_VN1614::Cint = 56
const XL_HWTYPE_VN1630::Cint = 57
const XL_HWTYPE_VN1615::Cint = 58
const XL_HWTYPE_VN1640::Cint = 59
const XL_HWTYPE_VN8970::Cint = 61
const XL_HWTYPE_VN1611::Cint = 63
const XL_HWTYPE_VN5240::Cint = 64
const XL_HWTYPE_VN5610::Cint = 65
const XL_HWTYPE_VN5620::Cint = 66
const XL_HWTYPE_VN7570::Cint = 67
const XL_HWTYPE_VN5650::Cint = 68
const XL_HWTYPE_IPCLIENT::Cint = 69
const XL_HWTYPE_VN5611::Cint = 70
const XL_HWTYPE_IPSERVER::Cint = 71
const XL_HWTYPE_VN5612::Cint = 72
const XL_HWTYPE_VX1121::Cint = 73
const XL_HWTYPE_VX1131::Cint = 75
const XL_HWTYPE_VT6204::Cint = 77
const XL_HWTYPE_VN5614::Cint = 78
const XL_HWTYPE_VN1630_LOG::Cint = 79
const XL_HWTYPE_VN7610::Cint = 81
const XL_HWTYPE_VN7572::Cint = 83
const XL_HWTYPE_VN8972::Cint = 85
const XL_HWTYPE_VN1641::Cint = 86
const XL_HWTYPE_VN0601::Cint = 87
const XL_HWTYPE_VT6104B::Cint = 88
const XL_HWTYPE_VN5640::Cint = 89
const XL_HWTYPE_VT6204B::Cint = 90
const XL_HWTYPE_VX0312::Cint = 91
const XL_HWTYPE_VH6501::Cint = 94
const XL_HWTYPE_VN8800::Cint = 95
const XL_HWTYPE_IPCL8800::Cint = 96
const XL_HWTYPE_IPSRV8800::Cint = 97
const XL_HWTYPE_CSMCAN::Cint = 98
const XL_HWTYPE_VN5610A::Cint = 101
const XL_HWTYPE_VN7640::Cint = 102
const XL_HWTYPE_VX1135::Cint = 104
const XL_HWTYPE_VN4610::Cint = 105
const XL_HWTYPE_VT6306::Cint = 107
const XL_HWTYPE_VT6104A::Cint = 108
const XL_HWTYPE_VN5430::Cint = 109
const XL_HWTYPE_VTSSERVICE::Cint = 110
const XL_HWTYPE_VN1530::Cint = 112
const XL_HWTYPE_VN1531::Cint = 113
const XL_HWTYPE_VX1161A::Cint = 114
const XL_HWTYPE_VX1161B::Cint = 115
const XL_HWTYPE_VN1670::Cint = 120
const XL_HWTYPE_VN5620A::Cint = 121
const XL_MAX_HWTYPE::Cint = 123



# interface version for our events
const XL_INTERFACE_VERSION_V2::Cuint = 2
const XL_INTERFACE_VERSION_V3::Cuint = 3
const XL_INTERFACE_VERSION_V4::Cuint = 4
# current version
const XL_INTERFACE_VERSION = XL_INTERFACE_VERSION_V3


# Bus types
const XL_BUS_TYPE_NONE::Cuint = 0x00000000
const XL_BUS_TYPE_CAN::Cuint = 0x00000001
const XL_BUS_TYPE_LIN::Cuint = 0x00000002
const XL_BUS_TYPE_FLEXRAY::Cuint = 0x00000004
const XL_BUS_TYPE_AFDX::Cuint = 0x00000008  # former BUS_TYPE_BEAN
const XL_BUS_TYPE_MOST::Cuint = 0x00000010
const XL_BUS_TYPE_DAIO::Cuint = 0x00000040  # IO cab/piggy
const XL_BUS_TYPE_J1708::Cuint = 0x00000100
const XL_BUS_TYPE_KLINE::Cuint = 0x00000800
const XL_BUS_TYPE_ETHERNET::Cuint = 0x00001000
const XL_BUS_TYPE_A429::Cuint = 0x00002000
const XL_BUS_TYPE_STATUS::Cuint = 0x00020000




# porthandle
const XL_INVALID_PORTHANDLE::XLportHandle = -1


# activate - channel flags
const XL_ACTIVATE_NONE::Cuint = 0
const XL_ACTIVATE_RESET_CLOCK::Cuint =
    8  # using this flag with time synchronisation protocols supported by Vector Timesync Service is not recommended



const XL_EVENT_FLAG_OVERRUN::Cuchar = 0x01  #!< Used in XLevent.flags


# flags in s_xl_can_msg
const XL_CAN_MSG_FLAG_ERROR_FRAME::Cushort = 0x01
const XL_CAN_MSG_FLAG_OVERRUN::Cushort = 0x02  #//!< Overrun in Driver or CAN Controller, previous msgs have been lost.
const XL_CAN_MSG_FLAG_NERR::Cushort = 0x04  #//!< Line Error on Lowspeed
const XL_CAN_MSG_FLAG_WAKEUP::Cushort = 0x08  #//!< High Voltage Message on Single Wire CAN
const XL_CAN_MSG_FLAG_REMOTE_FRAME::Cushort = 0x10
const XL_CAN_MSG_FLAG_RESERVED_1::Cushort = 0x20
const XL_CAN_MSG_FLAG_TX_COMPLETED::Cushort = 0x40  #//!< Message Transmitted
const XL_CAN_MSG_FLAG_TX_REQUEST::Cushort = 0x80  #//!< Transmit Message stored into Controller
const XL_CAN_MSG_FLAG_SRR_BIT_DOM::Cushort = 0x0200  #//!< SRR bit in CAN message is dominant


# //
# // common event tags
# //
const XL_RECEIVE_MSG::Cushort = 0x0001
const XL_CHIP_STATE::Cushort = 0x0004
const XL_TRANSCEIVER_INFO::Cushort = 0x0006
const XL_TRANSCEIVER = XL_TRANSCEIVER_INFO
const XL_TIMER_EVENT::Cushort = 0x0008
const XL_TIMER = XL_TIMER_EVENT
const XL_TRANSMIT_MSG::Cushort = 0x000A
const XL_SYNC_PULSE::Cushort = 0x000B
const XL_APPLICATION_NOTIFICATION::Cushort = 0x000F


const XL_CAN_EXT_MSG_ID::Culong = 0x80000000 # CAN EXT ID FLAG


#//------------------------------------------------------------------------------
#// acceptance filter
#
const XL_CAN_STD::Cuint = 01  #//!< flag for standard ID's
const XL_CAN_EXT::Cuint = 02  #//!< flag for extended ID's


#//------------------------------------------------------------------------------
#// defines for SET_OUTPUT_MODE
const XL_OUTPUT_MODE_SILENT::Cuchar = 0  #//!< switch CAN trx into default silent mode
const XL_OUTPUT_MODE_NORMAL::Cuchar = 1  #//!< switch CAN trx into normal mode


const CANFD_CONFOPT_NO_ISO::Cuchar = 0x08  #// configuration option CANFD-BOSCH


# // CAN/CAN-FD event tags
# // Tx
const XL_CAN_EV_TAG_TX_MSG::Cushort = 0x0440



#///////////////////////////////////////////////////////////////////////
#// CAN / CAN-FD types and definitions
#///////////////////////////////////////////////////////////////////////



#// to be used with XLcanTxEvent::XL_CAN_TX_MSG::msgFlags
const XL_CAN_TXMSG_FLAG_EDL::Cuint = 0x0001  #// extended data length
const XL_CAN_TXMSG_FLAG_BRS::Cuint = 0x0002  #// baud rate switch
const XL_CAN_TXMSG_FLAG_RTR::Cuint = 0x0010  #// remote transmission request
const XL_CAN_TXMSG_FLAG_HIGHPRIO::Cuint = 0x0080  #// high priority message - clears all send buffers - then transmits
const XL_CAN_TXMSG_FLAG_WAKEUP::Cuint = 0x0200  #// generate a wakeup message


#//
#// CAN/CAN-FD event tags
#// Rx
const XL_CAN_EV_TAG_RX_OK::Cushort = 0x0400
const XL_CAN_EV_TAG_RX_ERROR::Cushort = 0x0401
const XL_CAN_EV_TAG_TX_ERROR::Cushort = 0x0402
const XL_CAN_EV_TAG_TX_REQUEST::Cushort = 0x0403
const XL_CAN_EV_TAG_TX_OK::Cushort = 0x0404
const XL_CAN_EV_TAG_CHIP_STATE::Cushort = 0x0409


# // to be used with
# // XLcanRxEvent::XL_CAN_EV_RX_MSG::msgFlags
# // XLcanRxEvent::XL_CAN_EV_TX_REQUEST::msgFlags
# // XLcanRxEvent::XL_CAN_EV_RX_MSG::msgFlags
# // XLcanRxEvent::XL_CAN_EV_TX_REMOVED::msgFlags
# // XLcanRxEvent::XL_CAN_EV_ERROR::msgFlags
const XL_CAN_RXMSG_FLAG_EDL::Cuint = 0x0001  #// extended data length
const XL_CAN_RXMSG_FLAG_BRS::Cuint = 0x0002  #// baud rate switch
const XL_CAN_RXMSG_FLAG_ESI::Cuint = 0x0004  #// error state indicator
const XL_CAN_RXMSG_FLAG_RTR::Cuint = 0x0010  #// remote transmission request
const XL_CAN_RXMSG_FLAG_EF::Cuint = 0x0200  #// error frame (only posssible in XL_CAN_EV_TX_REQUEST/XL_CAN_EV_TX_REMOVED)
const XL_CAN_RXMSG_FLAG_ARB_LOST::Cuint = 0x0400  #// Arbitration Lost set if the receiving node tried to transmit a message but lost arbitration process
const XL_CAN_RXMSG_FLAG_WAKEUP::Cuint = 0x2000  #// high voltage message on single wire CAN
const XL_CAN_RXMSG_FLAG_TE::Cuint = 0x4000  #// 1: transceiver error detected

