# ============================================================================
# Parsing Utilities
# APMDataFlash (ArduPilot DataFlash binary log) and PX4ULog (PX4 ULog) readers
# shared by the Log Viewer.
#
# ulog_cpp is added and linked in src/AnalyzeView, which already needs it for
# GeoTag, so PX4ULogUtility picks up its headers from the project target.
# ============================================================================

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        APMDataFlash/APMDataFlashUtility.cc
        APMDataFlash/APMDataFlashUtility.h
        PX4ULog/PX4ULogUtility.cc
        PX4ULog/PX4ULogUtility.h
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/APMDataFlash
        ${CMAKE_CURRENT_SOURCE_DIR}/PX4ULog
)
