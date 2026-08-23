cmake_minimum_required(VERSION 3.24)
project(yunhai-plugins LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Qml)
qt_standard_project_setup(REQUIRES 6.5)

set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/imports)

add_subdirectory(sys)
