/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "Platform.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QProcessEnvironment>

#include "QGCCommandLineParser.h"

#ifdef Q_OS_ANDROID
    #include "AndroidInterface.h"
#endif

#if !defined(Q_OS_IOS) && !defined(Q_OS_ANDROID)
    #include "SignalHandler.h"
#endif

#if defined(Q_OS_MACOS)
    #include <CoreFoundation/CoreFoundation.h>
#elif defined(Q_OS_WIN)
    #include <qt_windows.h>
    #include <dbghelp.h>
    #include <cstring>
    #include <iostream>
    #include <iterator>  // std::size
    #include <cwchar>    // swprintf
    #if defined(_MSC_VER)
        #include <crtdbg.h>
        #include <stdlib.h>
        #include <cstdio> // _snwprintf_s
    #endif
#endif

namespace {

#if defined(Q_OS_MACOS)
void disableAppNapViaInfoDict()
{
    CFBundleRef bundle = CFBundleGetMainBundle();
    if (!bundle) {
        return;
    }
    CFMutableDictionaryRef infoDict = const_cast<CFMutableDictionaryRef>(CFBundleGetInfoDictionary(bundle));
    if (infoDict) {
        CFDictionarySetValue(infoDict, CFSTR("NSAppSleepDisabled"), kCFBooleanTrue);
    }
}
#endif // Q_OS_MACOS

#if defined(Q_OS_WIN)

#if defined(_MSC_VER)
int __cdecl WindowsCrtReportHook(int reportType, char* message, int* returnValue)
{
    if (message) {
        std::cerr << message << std::endl;
    }
    if (reportType == _CRT_ASSERT) {
        if (returnValue) {
            *returnValue = 0;
        }
        return 1; // handled
    }
    return 0; // let CRT continue
}

void __cdecl WindowsPurecallHandler()
{
    (void) OutputDebugStringW(L"QGC: _purecall\n");
}

void WindowsInvalidParameterHandler([[maybe_unused]] const wchar_t* expression,
                                    [[maybe_unused]] const wchar_t* function,
                                    [[maybe_unused]] const wchar_t* file,
                                    [[maybe_unused]] unsigned int line,
                                    [[maybe_unused]] uintptr_t pReserved)
{

}
#endif // _MSC_VER

LPTOP_LEVEL_EXCEPTION_FILTER g_prevUef = nullptr;

LONG WINAPI WindowsUnhandledExceptionFilter(EXCEPTION_POINTERS* ep)
{
    const DWORD code = (ep && ep->ExceptionRecord) ? ep->ExceptionRecord->ExceptionCode : 0;
    wchar_t buf[128] = {};
#if defined(_MSC_VER)
    (void) _snwprintf_s(buf, _TRUNCATE, L"QGC: unhandled SEH 0x%08lX\n", static_cast<unsigned long>(code));
#else
    (void) swprintf(buf, static_cast<int>(std::size(buf)), L"QGC: unhandled SEH 0x%08lX\n", static_cast<unsigned long>(code));
#endif
    (void) OutputDebugStringW(buf);

    const HANDLE h = GetStdHandle(STD_ERROR_HANDLE);
    if (h && (h != INVALID_HANDLE_VALUE)) {
        DWORD ignored = 0;
        const char narrow[] = "QGC: unhandled SEH\n";
        (void) WriteFile(h, narrow, (DWORD)sizeof(narrow) - 1, &ignored, nullptr);
    }

    // Without this the filter swallows the crash outright: no dump, no debugger break,
    // nothing to go on but the exception code. Walk the faulting stack and symbolise it so
    // even a non-debugger run reports where it died.
    if (ep && ep->ContextRecord) {
        const auto writeLine = [h](const char *text) {
            if (h && (h != INVALID_HANDLE_VALUE)) {
                DWORD ignored = 0;
                (void) WriteFile(h, text, static_cast<DWORD>(strlen(text)), &ignored, nullptr);
            }
            (void) OutputDebugStringA(text);
        };

        const HANDLE process = GetCurrentProcess();
        (void) SymSetOptions(SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME | SYMOPT_LOAD_LINES);
        (void) SymInitialize(process, nullptr, TRUE);

        CONTEXT context = *ep->ContextRecord;
        STACKFRAME64 frame = {};
        DWORD machine = IMAGE_FILE_MACHINE_UNKNOWN;
#if defined(_M_X64)
        machine = IMAGE_FILE_MACHINE_AMD64;
        frame.AddrPC.Offset = context.Rip;
        frame.AddrFrame.Offset = context.Rbp;
        frame.AddrStack.Offset = context.Rsp;
#elif defined(_M_ARM64)
        machine = IMAGE_FILE_MACHINE_ARM64;
        frame.AddrPC.Offset = context.Pc;
        frame.AddrFrame.Offset = context.Fp;
        frame.AddrStack.Offset = context.Sp;
#endif
        frame.AddrPC.Mode = AddrModeFlat;
        frame.AddrFrame.Mode = AddrModeFlat;
        frame.AddrStack.Mode = AddrModeFlat;

        alignas(SYMBOL_INFO) char symbolBuffer[sizeof(SYMBOL_INFO) + 512] = {};
        SYMBOL_INFO *const symbol = reinterpret_cast<SYMBOL_INFO*>(symbolBuffer);
        symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
        symbol->MaxNameLen = 511;

        char line[1024];
        for (int i = 0; (i < 48) && (machine != IMAGE_FILE_MACHINE_UNKNOWN); ++i) {
            if (!StackWalk64(machine, process, GetCurrentThread(), &frame, &context,
                             nullptr, SymFunctionTableAccess64, SymGetModuleBase64, nullptr)) {
                break;
            }
            if (frame.AddrPC.Offset == 0) {
                break;
            }

            DWORD64 displacement = 0;
            const char *const name = SymFromAddr(process, frame.AddrPC.Offset, &displacement, symbol)
                                         ? symbol->Name : "<unknown>";

            IMAGEHLP_LINE64 srcLine = {};
            srcLine.SizeOfStruct = sizeof(IMAGEHLP_LINE64);
            DWORD lineDisplacement = 0;
            if (SymGetLineFromAddr64(process, frame.AddrPC.Offset, &lineDisplacement, &srcLine)) {
                (void) _snprintf_s(line, _TRUNCATE, "  #%-2d %s  (%s:%lu)\n",
                                   i, name, srcLine.FileName, static_cast<unsigned long>(srcLine.LineNumber));
            } else {
                (void) _snprintf_s(line, _TRUNCATE, "  #%-2d %s  +0x%llx\n",
                                   i, name, static_cast<unsigned long long>(displacement));
            }
            writeLine(line);
        }

        (void) SymCleanup(process);
    }

    return EXCEPTION_EXECUTE_HANDLER;
}

void setWindowsErrorModes(bool quietWindowsAsserts)
{
    (void) SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    g_prevUef = SetUnhandledExceptionFilter(WindowsUnhandledExceptionFilter);

#if defined(_MSC_VER)
    (void) _set_invalid_parameter_handler(WindowsInvalidParameterHandler);
    (void) _set_purecall_handler(WindowsPurecallHandler);

    if (quietWindowsAsserts) {
        (void) _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_DEBUG);
        (void) _CrtSetReportMode(_CRT_ERROR,  _CRTDBG_MODE_DEBUG);
        (void) _CrtSetReportMode(_CRT_WARN,   _CRTDBG_MODE_DEBUG);
        (void) _CrtSetReportHook2(_CRT_RPTHOOK_INSTALL, WindowsCrtReportHook);
        (void) _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
        (void) _set_error_mode(_OUT_TO_STDERR);
    }
#else
    Q_UNUSED(quietWindowsAsserts);
#endif
}
#endif // Q_OS_WIN

} // namespace

void Platform::setupPreApp(const QGCCommandLineParser::CommandLineParseResult &cli)
{
#ifdef Q_OS_UNIX
    if (!qEnvironmentVariableIsSet("QT_ASSUME_STDERR_HAS_CONSOLE")) {
        (void) qputenv("QT_ASSUME_STDERR_HAS_CONSOLE", "1");
    }
    if (!qEnvironmentVariableIsSet("QT_FORCE_STDERR_LOGGING")) {
        (void) qputenv("QT_FORCE_STDERR_LOGGING", "1");
    }
#endif

#ifdef Q_OS_WIN
    // (void) qputenv("QT_OPENGL_BUGLIST", ":/opengl/resources/opengl/buglist.json");
    if (!qEnvironmentVariableIsSet("QT_WIN_DEBUG_CONSOLE")) {
        (void) qputenv("QT_WIN_DEBUG_CONSOLE", "attach");
    }
    setWindowsErrorModes(cli.quietWindowsAsserts);
#endif

#ifdef Q_OS_MACOS
    disableAppNapViaInfoDict();
#endif

    if (cli.useDesktopGL) {
        QCoreApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
    }

    if (cli.useSwRast) {
        QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL);
    }

    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QCoreApplication::setAttribute(Qt::AA_CompressTabletEvents);
}

void Platform::setupPostApp()
{
#if !defined(Q_OS_IOS) && !defined(Q_OS_ANDROID)
    SignalHandler* signalHandler = new SignalHandler(QCoreApplication::instance());
    (void) signalHandler->setupSignalHandlers();
#endif

#ifdef Q_OS_ANDROID
    AndroidInterface::checkStoragePermissions();
#endif
}
