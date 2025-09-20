#########################################################
# in module Canlib
#########################################################

const canStatus = Cint

const canOK::Cint = 0
const canERR_PARAM::Cint = -1
const canERR_NOMSG::Cint = -2
const canERR_NOTFOUND::Cint = -3
const canERR_NOMEM::Cint = -4
const canERR_NOCHANNELS::Cint = -5
const canERR_INTERRUPTED::Cint = -6 #///< Interrupted by signals
const canERR_TIMEOUT::Cint = -7
const canERR_NOTINITIALIZED::Cint = -8
const canERR_NOHANDLES::Cint = -9
const canERR_INVHANDLE::Cint = -10
const canERR_INIFILE::Cint = -11 #///< Error in the ini-file (16-bit only)
const canERR_DRIVER::Cint = -12
const canERR_TXBUFOFL::Cint = -13
const canERR_RESERVED_1::Cint = -14 #///< Reserved
const canERR_HARDWARE::Cint = -15
const canERR_DYNALOAD::Cint = -16
const canERR_DYNALIB::Cint = -17
const canERR_DYNAINIT::Cint = -18
const canERR_NOT_SUPPORTED::Cint = -19 #///< Operation not supported by hardware or firmware
const canERR_RESERVED_5::Cint = -20 #///< Reserved
const canERR_RESERVED_6::Cint = -21 #///< Reserved
const canERR_RESERVED_2::Cint = -22 #///< Reserved
const canERR_DRIVERLOAD::Cint = -23
const canERR_DRIVERFAILED::Cint = -24
const canERR_NOCONFIGMGR::Cint = -25 #///< Can't find req'd config s/w (e.g. CS/SS)
const canERR_NOCARD::Cint = -26 #///< The card was removed or not inserted
const canERR_RESERVED_7::Cint = -27 #///< Reserved
const canERR_REGISTRY::Cint = -28
const canERR_LICENSE::Cint = -29 #///< The license is not valid.
const canERR_INTERNAL::Cint = -30
const canERR_NO_ACCESS::Cint = -31
const canERR_NOT_IMPLEMENTED::Cint = -32
const canERR_DEVICE_FILE::Cint = -33
const canERR_HOST_FILE::Cint = -34
const canERR_DISK::Cint = -35
const canERR_CRC::Cint = -36
const canERR_CONFIG::Cint = -37
const canERR_MEMO_FAIL::Cint = -38
const canERR_SCRIPT_FAIL::Cint = -39
const canERR_SCRIPT_WRONG_VERSION::Cint = -40
const canERR_SCRIPT_TXE_CONTAINER_VERSION::Cint = -41
const canERR_SCRIPT_TXE_CONTAINER_FORMAT::Cint = -42
const canERR_BUFFER_TOO_SMALL::Cint = -43
const canERR_IO_WRONG_PIN_TYPE::Cint = -44
const canERR_IO_NOT_CONFIRMED::Cint = -45
const canERR_IO_CONFIG_CHANGED::Cint = -46
const canERR_IO_PENDING::Cint = -47
const canERR_IO_NO_VALID_CONFIG::Cint = -48
const canERR__RESERVED::Cint = -49    #///< Reserved



#############################################
# These defines are used in canOpenChannel(). 
const canOPEN_EXCLUSIVE::Cint = 0x0008
const canOPEN_REQUIRE_EXTENDED::Cint = 0x0010
const canOPEN_ACCEPT_VIRTUAL::Cint = 0x0020
const canOPEN_OVERRIDE_EXCLUSIVE::Cint = 0x0040
const canOPEN_REQUIRE_INIT_ACCESS::Cint = 0x0080
const canOPEN_NO_INIT_ACCESS::Cint = 0x0100
const canOPEN_ACCEPT_LARGE_DLC::Cint = 0x0200 #// DLC can be greater than 8
const canOPEN_CAN_FD::Cint = 0x0400
const canOPEN_CAN_FD_NONISO::Cint = 0x0800
const canOPEN_INTERNAL_L::Cint = 0x1000



#############################################
# These defines are used in canSetBusOutputControl(). 
const canDRIVER_NORMAL::Cuint = 4
const canDRIVER_SILENT::Cuint = 1
const canDRIVER_SELFRECEPTION::Cuint = 8
const canDRIVER_OFF::Cuint = 0


#############################################
# These defines are used in canWrite(). 
const canMSG_STD::Cuint = 0x0002 #///< Message has a standard (11-bit) identifier
const canMSG_EXT::Cuint = 0x0004 #///< Message has an extended (29-bit) identifier
const canMSG_RTR::Cuint = 0x0001
const canMSG_ERROR_FRAME::Cuint = 0x0020
const canFDMSG_FDF::Cuint = 0x010000 # Message is an FD message (CAN FD) 
const canFDMSG_BRS::Cuint = 0x020000 # Message is sent/received with bit rate switch (CAN FD) 
const canFDMSG_ESI::Cuint = 0x040000 # Sender of the message is in error passive mode (CAN FD) 




#############################################
# These defines are used in canIoCtl(). 
#define  canIOCTL_PREFER_EXT   1 
#define  canIOCTL_PREFER_STD   2 
#define  canIOCTL_CLEAR_ERROR_COUNTERS   5 
const canIOCTL_SET_TIMER_SCALE::Cuint = 6
#define  canIOCTL_SET_TXACK   7 
#define  canIOCTL_GET_RX_BUFFER_LEVEL   8 
#define  canIOCTL_GET_TX_BUFFER_LEVEL   9 
#define  canIOCTL_FLUSH_RX_BUFFER   10 
#define  canIOCTL_FLUSH_TX_BUFFER   11 
#define  canIOCTL_GET_TIMER_SCALE   12 
#define  canIOCTL_SET_TXRQ   13 
#define  canIOCTL_GET_EVENTHANDLE   14 
#define  canIOCTL_SET_BYPASS_MODE   15 
#define  canIOCTL_SET_WAKEUP   16 
#define  canIOCTL_GET_DRIVERHANDLE   17 
#define  canIOCTL_MAP_RXQUEUE   18 
#define  canIOCTL_GET_WAKEUP   19 
#define  canIOCTL_SET_REPORT_ACCESS_ERRORS   20 
#define  canIOCTL_GET_REPORT_ACCESS_ERRORS   21 
#define  canIOCTL_CONNECT_TO_VIRTUAL_BUS   22 
#define  canIOCTL_DISCONNECT_FROM_VIRTUAL_BUS   23 
#define  canIOCTL_SET_USER_IOPORT   24 
#define  canIOCTL_GET_USER_IOPORT   25 
#define  canIOCTL_SET_BUFFER_WRAPAROUND_MODE   26 
#define  canIOCTL_SET_RX_QUEUE_SIZE   27 
#define  canIOCTL_SET_USB_THROTTLE   28 
#define  canIOCTL_GET_USB_THROTTLE   29 
#define  canIOCTL_SET_BUSON_TIME_AUTO_RESET   30 
#define  canIOCTL_GET_TXACK   31 
#define  canIOCTL_SET_LOCAL_TXECHO   32 
#define  canIOCTL_SET_ERROR_FRAMES_REPORTING   33 
#define  canIOCTL_GET_CHANNEL_QUALITY   34 
#define  canIOCTL_GET_ROUNDTRIP_TIME   35 
#define  canIOCTL_GET_BUS_TYPE   36 
#define  canIOCTL_GET_DEVNAME_ASCII   37 
#define  canIOCTL_GET_TIME_SINCE_LAST_SEEN   38 
#define  canIOCTL_GET_TREF_LIST   39 
#define  canIOCTL_TX_INTERVAL   40 
#define  canIOCTL_SET_BRLIMIT   43 
#define  canIOCTL_SET_USB_THROTTLE_SCALED   41 
#define  canIOCTL_SET_THROTTLE_SCALED   41 
#define  canIOCTL_GET_USB_THROTTLE_SCALED   42 
#define  canIOCTL_GET_THROTTLE_SCALED   42 
#define  canIOCTL_RESET_OVERRUN_COUNT   44 
#define  canIOCTL_LIN_MODE   45 
