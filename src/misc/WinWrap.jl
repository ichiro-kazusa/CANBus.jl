
"""Wrappers for Windows system call."""
module WinWrap

const winkernel = "kernel32"

const BOOL = Cint

function WaitForSingleObject(hHandle::Ptr{Cvoid}, dwMilliseconds::Culong)

    # use @threadcall instead ccall for avoid blocking
    Threads.@threadcall((:WaitForSingleObject, winkernel), Culong,
        (Ptr{Cvoid}, Culong),
        hHandle, dwMilliseconds)
end


function CloseHandle(hObject::Ptr{Cvoid})
    ccall((:CloseHandle, winkernel), BOOL,
        (Ptr{Cvoid},), hObject)
end


end # WinWrap