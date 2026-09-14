qt_add_library(QGroundControlModule STATIC)

set_source_files_properties(UI/MainWindow.qml PROPERTIES QT_RESOURCE_ALIAS MainWindow.qml)

target_link_libraries(QGroundControlModule PRIVATE Qt6::Core)

qt_add_qml_module(QGroundControlModule
    URI QGroundControl
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES

    IMPORTS
        QGC
    NO_PLUGIN
    SOURCES Utilities/Audio/SpeechLocalizer.h
    SOURCES Utilities/Audio/SpeechLocalizer.h Utilities/Audio/speechlocalizer.cpp
    QML_FILES
    QML_FILES UI/TopStatusPanel.qml
    QML_FILES UI/SideMenu.qml
    QML_FILES UI/SideMenu_AparatQurgusu.qml
    QML_FILES UI/SideMenu_Cercive.qml
    QML_FILES UI/SideMenu_Motors.qml
    QML_FILES UI/SideMenu_Sensors_Level.qml
    QML_FILES UI/MainWindow.qml
    QML_FILES UI/TopStatusPanel_GPS.qml
    QML_FILES UI/Side_Parameter.qml
    QML_FILES UI/Side_Proqram_Teminati.qml
    QML_FILES UI/SideMenu_Enerji.qml
    QML_FILES UI/SideMenu_FlightMode.qml
    QML_FILES UI/SideMenu_Joystick.qml
    QML_FILES UI/SideMenu_Radio.qml
    QML_FILES UI/SideMenu_Sensors.qml
    QML_FILES UI/SideMenu_Sensors_Accelerometer.qml
    QML_FILES UI/SideMenu_Sensors_Barometr.qml
    QML_FILES UI/SideMenu_Sensors_Compass.qml
    QML_FILES UI/SideMenu_Sensors_CompassMot.qml
    QML_FILES UI/SideMenu_Sensors_Settings.qml
    QML_FILES UI/SideMenu_Tehlukesizlik.qml
    QML_FILES UI/TopStatusMessage.qml
    QML_FILES UI/TopStatusPanel_Battery.qml
    QML_FILES UI/TopStatusPanel_Battery_Settings.qml
    QML_FILES UI/TopStatusPanel_GPS_Settings.qml
    QML_FILES UI/TopStatusPanel_RCSignal.qml
    QML_FILES UI/TopStatusPanel_RCSignal_Settings.qml
    QML_FILES UI/TopStatusPanel_UcusRejimi.qml
    QML_FILES UI/TopStatusPanel_UcusRejimi_Settings.qml
    QML_FILES
    QML_FILES UI/SideMenu_Summary.qml
    QML_FILES UI/SideMenu_PIDTuning.qml
    QML_FILES UI/General_Settings.qml
    QML_FILES UI/Tenzimlemeler.qml
    QML_FILES UI/Comm_links.qml
    QML_FILES UI/SettingsPage.qml
    QML_FILES UI/Fly_ViewSettings.qml
    QML_FILES
    QML_FILES UI/SerialSettings.qml
    QML_FILES UI/NTRIP_Settings.qml
    QML_FILES UI/Telemetry_Settings.qml
    QML_FILES UI/PX4LogTransfer_Settings.qml
    QML_FILES UI/ADSBServer.qml
    QML_FILES UI/Console.qml
    QML_FILES UI/AppSetting_VideoSettings.qml
    QML_FILES UI/AppSettings_MapSettings.qml
    QML_FILES UI/AppSettings_RemoteIdSettings.qml
    QML_FILES UI/AppSettings_PlanView.qml
    QML_FILES UI/AppHelp.qml
    QML_FILES UI/Qeyd_Analizi.qml
    QML_FILES UI/GeoTag.qml
    QML_FILES UI/Log_Download.qml
    QML_FILES UI/LogViewer_Page.qml
    QML_FILES UI/MAXLink_Console.qml
    QML_FILES UI/MAXLink_Inspector.qml
    QML_FILES UI/Vibration.qml
    QML_FILES
    QML_FILES UI/TopStatusPanel_Telemetry.qml
    QML_FILES
    QML_FILES UI/CheckList.qml
    QML_FILES
    QML_FILES
    QML_FILES
    QML_FILES
    QML_FILES
    QML_FILES
    QML_FILES UI/BottomCenterStatusPanel.qml
    QML_FILES UI/TopStatusPanel_UDPPosition.qml
    QML_FILES UI/TopStatusPanel_VehicleSelector.qml
)

target_include_directories(QGroundControlModule PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/MAVLink
    ${CMAKE_SOURCE_DIR}/src/MAVLink/LibEvents
    ${CMAKE_SOURCE_DIR}/src/Vehicle
    ${CMAKE_SOURCE_DIR}/src/Comms
    ${CMAKE_BINARY_DIR}/_deps/mavlink-src
    ${CMAKE_BINARY_DIR}/_deps/mavlink-src/intercept
)

add_subdirectory(ADSB)
add_subdirectory(AnalyzeView)
add_subdirectory(Android)
add_subdirectory(API)
add_subdirectory(AutoPilotPlugins)
add_subdirectory(Camera)
add_subdirectory(Comms)
add_subdirectory(FactSystem)
add_subdirectory(FirmwarePlugin)
add_subdirectory(FlightDisplay)
add_subdirectory(FlightMap)
add_subdirectory(FollowMe)
add_subdirectory(Gimbal)
add_subdirectory(GPS)
add_subdirectory(Joystick)
add_subdirectory(MAVLink)
add_subdirectory(MissionManager)
add_subdirectory(PositionManager)
add_subdirectory(QmlControls)
add_subdirectory(Settings)
add_subdirectory(Terrain)
add_subdirectory(UI)
add_subdirectory(Utilities)
add_subdirectory(UTMSP)
add_subdirectory(Vehicle)
add_subdirectory(VideoManager)
add_subdirectory(Viewer3D)

add_subdirectory(QtLocationPlugin)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        main.cc
        pch.h
        QGCApplication.cc
        QGCApplication.h
)

if(WIN32)
    set(APP_ICON_RC "${CMAKE_CURRENT_BINARY_DIR}/appicon.rc")
    configure_file(
        "${CMAKE_SOURCE_DIR}/deploy/windows/appicon.rc.in"
        "${APP_ICON_RC}"
        @ONLY
    )
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE "${APP_ICON_RC}")
endif()


if(NOT ANDROID AND NOT IOS)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            RunGuard.cc
            RunGuard.h
    )
endif()

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/src/MAVLink
    ${CMAKE_BINARY_DIR}/_deps/mavlink-src
    ${CMAKE_BINARY_DIR}/_deps/mavlink-src/ardupilotmega
    ${CMAKE_BINARY_DIR}/_deps/mavlink-src/intercept
)


target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        Qt6::Charts
        Qt6::Concurrent
        Qt6::Core
        Qt6::Core5Compat
        Qt6::CorePrivate
        Qt6::Gui
        Qt6::Location
        Qt6::LocationPrivate
        Qt6::Multimedia
        Qt6::MultimediaQuickPrivate
        Qt6::Network
        Qt6::Positioning
        Qt6::PositioningPrivate
        Qt6::Qml
        Qt6::QmlIntegration
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sensors
        Qt6::Svg
        Qt6::TextToSpeech
        Qt6::Widgets
        Qt6::Xml
        AnalyzeViewModule
        AppSettingsModule
        AutoPilotPluginsCommonModule
        FactControlsModule
        FirstRunPromptDialogsModule
        FlightDisplayModule
        FlightMapModule
        QGroundControlControlsModule
        QGroundControlModule
        ToolbarModule
        UTMSPModule
        VehicleSetupModule
)

if(NOT QGC_DISABLE_APM_PLUGIN)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AutoPilotPluginsAPMModule)
endif()
if(NOT QGC_DISABLE_PX4_PLUGIN)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AutoPilotPluginsPX4Module)
endif()
if(QGC_VIEWER3D)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Viewer3DModule)
endif()
if(NOT QGC_AIRLINK_DISABLED)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE AirLinkModule)
endif()

target_compile_definitions(${CMAKE_PROJECT_NAME}
    PRIVATE
        QGC_APP_NAME="${QGC_APP_NAME}"
        QGC_ORG_NAME="${QGC_ORG_NAME}"
        QGC_ORG_DOMAIN="${QGC_ORG_DOMAIN}"
        QGC_APP_VERSION_STR="${QGC_APP_VERSION_STR}"
        QGC_APP_DATE="${QGC_APP_DATE}"
        QGC_APP_DESCRIPTION="${QGC_APP_DESCRIPTION}"
        QGC_SETTINGS_VERSION=${QGC_SETTINGS_VERSION}
        $<$<NOT:$<BOOL:${QGC_STABLE_BUILD}>>:QGC_DAILY_BUILD>
        $<$<BOOL:${QGC_DISABLE_APM_MAVLINK}>:QGC_NO_ARDUPILOT_DIALECT>
)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            NDEBUG
            QT_NO_DEBUG
            QT_MESSAGELOGCONTEXT
    )
else()
    target_compile_definitions(${CMAKE_PROJECT_NAME}
        PRIVATE
            QT_DISABLE_DEPRECATED_UP_TO=0x060800
            QT_ENABLE_STRICT_MODE_UP_TO=0x060800
            $<$<BOOL:${QGC_DEBUG_QML}>:QT_QML_DEBUG>
    )
endif()

# set_target_properties(${CMAKE_PROJECT_NAME}
#     PROPERTIES
#         QT_RESOURCE_PREFIX "/qml"
#         OUTPUT_NAME ${CMAKE_PROJECT_NAME}
# )


set_target_properties(${CMAKE_PROJECT_NAME}
    PROPERTIES
        QT_RESOURCE_PREFIX "/qml"
        OUTPUT_NAME "AzShieldGCS"
)

# Android üçün QGC-nin öz android/ template-ni məcburi istifadə et
if(ANDROID)
    set_property(TARGET ${CMAKE_PROJECT_NAME}
        PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
        "${CMAKE_SOURCE_DIR}/android"
    )
endif()


target_precompile_headers(${CMAKE_PROJECT_NAME} PRIVATE pch.h)

if(QGC_CUSTOM_BUILD)
    find_package(Qt6 REQUIRED COMPONENTS ${CUSTOM_QT_COMPONENTS})
    find_package(Qt6 REQUIRED COMPONENTS Core)
    target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_SOURCES})
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_LIBRARIES})
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_INCLUDE_DIRECTORIES})
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE ${CUSTOM_DEFINITIONS})
endif()
