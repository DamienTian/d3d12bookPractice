#include <Windows.h>
#include <DbgHelp.h>

void CreateMiniDump(EXCEPTION_POINTERS* pExceptionPointers) {
    HANDLE hFile = CreateFile(L"crashdump.dmp", GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile != INVALID_HANDLE_VALUE) {
        MINIDUMP_EXCEPTION_INFORMATION dumpInfo;
        dumpInfo.ThreadId = GetCurrentThreadId();
        dumpInfo.ExceptionPointers = pExceptionPointers;
        dumpInfo.ClientPointers = FALSE;
        MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), hFile, MiniDumpWithFullMemory, &dumpInfo, nullptr, nullptr);
        CloseHandle(hFile);
    }
}

LONG WINAPI CustomUnhandledExceptionFilter(EXCEPTION_POINTERS* pExceptionPointers) {
    CreateMiniDump(pExceptionPointers);
    return EXCEPTION_EXECUTE_HANDLER;
}
