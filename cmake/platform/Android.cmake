if(NOT ANDROID)
    message(FATAL_ERROR "Invalid Platform")
    return()
endif()

# Qt ships prebuilt Android libraries built against one NDK. Crossing a major
# version brings a different libc++_shared along with it, which shows up as
# link errors or as symbol mismatches at load time rather than here, so pin it.
if(${Qt6_VERSION} VERSION_GREATER_EQUAL 6.11)
    if(NOT ${CMAKE_ANDROID_NDK_VERSION} VERSION_EQUAL 27.2)
        message(FATAL_ERROR "Invalid NDK Version: ${CMAKE_ANDROID_NDK_VERSION}. Qt ${Qt6_VERSION} is built against 27C, use ndk;27.2.12479018.")
    endif()
elseif(${Qt6_VERSION} VERSION_EQUAL 6.8.3)
    if(NOT ${CMAKE_ANDROID_NDK_VERSION} VERSION_EQUAL 26.1 AND NOT ${CMAKE_ANDROID_NDK_VERSION} VERSION_EQUAL 27.2)
        message(FATAL_ERROR "Invalid NDK Version: ${CMAKE_ANDROID_NDK_VERSION}, Use Version 26B of 27C instead.")
    endif()
endif()

# Generation of android version numbers must be consistent release to release such that they are always increasing
if(${CMAKE_PROJECT_VERSION_MAJOR} GREATER 9)
    message(FATAL_ERROR "Major version larger than 1 digit: ${CMAKE_PROJECT_VERSION_MAJOR}")
endif()
if(${CMAKE_PROJECT_VERSION_MINOR} GREATER 9)
    message(FATAL_ERROR "Minor version larger than 1 digit: ${CMAKE_PROJECT_VERSION_MINOR}")
endif()
if(${CMAKE_PROJECT_VERSION_PATCH} GREATER 99)
    message(FATAL_ERROR "Patch version larger than 2 digits: ${CMAKE_PROJECT_VERSION_PATCH}")
endif()

# Bitness for android version number is 66/34 instead of 64/32 in because of a required version number bump screw-up ages ago
set(ANDROID_BITNESS_CODE)
if(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "armeabi-v7a" OR ${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86")
    set(ANDROID_BITNESS_CODE 34)
elseif(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "arm64-v8a" OR ${CMAKE_ANDROID_ARCH_ABI} STREQUAL "x86_64")
    set(ANDROID_BITNESS_CODE 66)
else()
    message(FATAL_ERROR "Unsupported Android ABI: ${CMAKE_ANDROID_ARCH_ABI}")
endif()

set(ANDROID_PATCH_VERSION ${CMAKE_PROJECT_VERSION_PATCH})
if(${CMAKE_PROJECT_VERSION_PATCH} LESS 10)
    set(ANDROID_PATCH_VERSION "0${CMAKE_PROJECT_VERSION_PATCH}")
endif()

# Version code format: BBMIPPDDD (B=Bitness, M=Major, I=Minor, P=Patch, D=Dev) - Dev not currently supported and always 000
set(ANDROID_VERSION_CODE "${ANDROID_BITNESS_CODE}${CMAKE_PROJECT_VERSION_MAJOR}${CMAKE_PROJECT_VERSION_MINOR}${ANDROID_PATCH_VERSION}000")
message(STATUS "Android version code: ${ANDROID_VERSION_CODE}")

# android/build.gradle sets applicationId itself (its namespace stays the Java
# package), so QT_ANDROID_PACKAGE_NAME alone does not decide the installed
# package. Catch the two drifting apart here rather than on the device.
file(STRINGS "${QGC_ANDROID_PACKAGE_SOURCE_DIR}/build.gradle" _qgc_gradle_app_id
    REGEX "^[ \t]*applicationId[ \t]*=?[ \t]*\"[^\"]+\"")
string(REGEX MATCH "\"([^\"]+)\"" _qgc_gradle_app_id_match "${_qgc_gradle_app_id}")
if(NOT CMAKE_MATCH_1 STREQUAL QGC_ANDROID_PACKAGE_NAME)
    message(FATAL_ERROR "QGC: android/build.gradle applicationId (${CMAKE_MATCH_1}) does not match QGC_ANDROID_PACKAGE_NAME (${QGC_ANDROID_PACKAGE_NAME})")
endif()

set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        # QT_ANDROID_ABIS ${CMAKE_ANDROID_ARCH_ABI}
        # QT_ANDROID_SDK_BUILD_TOOLS_REVISION
        QT_ANDROID_MIN_SDK_VERSION ${QGC_QT_ANDROID_MIN_SDK_VERSION}
        QT_ANDROID_TARGET_SDK_VERSION ${QGC_QT_ANDROID_TARGET_SDK_VERSION}
        # QT_ANDROID_COMPILE_SDK_VERSION
        QT_ANDROID_PACKAGE_NAME "${QGC_ANDROID_PACKAGE_NAME}"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${QGC_ANDROID_PACKAGE_SOURCE_DIR}"
        QT_ANDROID_VERSION_NAME "${CMAKE_PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE ${ANDROID_VERSION_CODE}
        # QT_ANDROID_APP_NAME
        # QT_ANDROID_APP_ICON
        # QT_QML_IMPORT_PATH
        QT_QML_ROOT_PATH "${CMAKE_SOURCE_DIR}"
        # QT_ANDROID_SYSTEM_LIBS_PREFIX
)

# if(CMAKE_BUILD_TYPE STREQUAL "Debug")
#     set(QT_ANDROID_APPLICATION_ARGUMENTS)
# endif()

list(APPEND QT_ANDROID_MULTI_ABI_FORWARD_VARS QGC_STABLE_BUILD QT_HOST_PATH)

CPMAddPackage(
    NAME android_openssl
    URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
)
include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
add_android_openssl_libraries(${CMAKE_PROJECT_NAME})
