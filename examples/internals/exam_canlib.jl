using Revise
import CAN.Interfaces.KvaserInterfaces: Canlib as Canlib



"""
example program to check internal low-level api "CAN.Interfaces.KvaserInterfaces.Canlib"
"""
function main()
    # initialize library
    Canlib.canInitializeLibrary()

    # open channel 0
    hnd0 = Canlib.canOpenChannel(Cint(0), Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd0 < 0
        error("Kvaser: can open failed.")
    end
    println("Handle0: ", hnd0)

    # open channel 1
    hnd1 = Canlib.canOpenChannel(Cint(1), Canlib.canOPEN_ACCEPT_VIRTUAL)
    if hnd1 < 0
        error("Kvaser: can open failed.")
    end
    println("Handle1: ", hnd1)

    # set bitrate
    status0 = Canlib.canSetBusParams(hnd0, Clong(500000), Cuint(0), Cuint(0), Cuint(0), Cuint(0), Cuint(0))
    status1 = Canlib.canSetBusParams(hnd1, Clong(500000), Cuint(0), Cuint(0), Cuint(0), Cuint(0), Cuint(0))
    println((status0, status1))

    # set drivertype
    status0 = Canlib.canSetBusOutputControl(hnd0, Canlib.canDRIVER_NORMAL)
    status1 = Canlib.canSetBusOutputControl(hnd1, Canlib.canDRIVER_NORMAL)
    println((status0, status1))

    # bus on
    status0 = Canlib.canBusOn(hnd0)
    status1 = Canlib.canBusOn(hnd1)
    println((status0, status1))

    # send message
    msg_t = Cchar[1, 1, 2, 2, 3, 3, 4, 4]
    dlc::Cuint = 8
    id::Clong = 8
    pmsg_t = Ref(msg_t, 1)
    status = Canlib.canWrite(hnd0, id, pmsg_t, dlc, Canlib.canMSG_STD)
    println(status)
    sleep(0.5)

    # recv message
    msg_r = Vector{Cchar}(undef, 8)
    pid = Ref{Clong}(0)
    pmsg_r = Ref(msg_r, 1)
    pdlc = Ref{Cuint}(0)
    pflag = Ref{Cuint}(0)
    ptime = Ref{Culong}(0)
    status = Canlib.canRead(hnd1, pid, pmsg_r, pdlc, pflag, ptime)
    if status == Canlib.canOK
        println("\tid: ", pid[])
        println("\tdlc: ", pdlc[])
        println("\tflag: ", pflag[])
        println("\tdata: ", msg_r)
    end

    # bus off
    status0 = Canlib.canBusOff(hnd0)
    status1 = Canlib.canBusOff(hnd1)
    println((status0, status1))

    # close channel
    status0 = Canlib.canClose(hnd0)
    status1 = Canlib.canClose(hnd1)
    println((status0, status1))
end

main()