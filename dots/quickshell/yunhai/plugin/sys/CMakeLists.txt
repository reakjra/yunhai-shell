qt_add_qml_module(yunhaisys
    URI Yunhai.Sys
    VERSION 1.0
    PLUGIN_TARGET yunhaisysplugin
    SOURCES
        Sysfs.hpp
        Sysfs.cpp
        CpuStats.hpp
        CpuStats.cpp
        MemoryStats.hpp
        MemoryStats.cpp
        GpuDevice.hpp
        GpuDevice.cpp
        GpuBackend.hpp
        GpuBackend.cpp
        Backends.hpp
        AmdBackend.cpp
        IntelBackend.cpp
        NvidiaBackend.cpp
        SysMon.hpp
        SysMon.cpp
        ProcessEntry.hpp
        ProcessEntry.cpp
        ProcessTable.hpp
        ProcessTable.cpp
)

set_target_properties(yunhaisysplugin PROPERTIES INSTALL_RPATH "$ORIGIN" BUILD_RPATH "$ORIGIN")
