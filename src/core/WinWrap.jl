
"""Wrappers for Windows system call."""
module WinWrap

const winkernel = "kernel32"


function WaitForSingleObject(hHandle::Ptr{Cvoid}, dwMilliseconds::Culong)

    # use @threadcall instead ccall for avoid blocking
    Threads.@threadcall((:WaitForSingleObject, winkernel), Culong,
        (Ptr{Cvoid}, Culong),
        hHandle, dwMilliseconds)
end

end # WinWrap