# Set the minimum version of CMake that can be used
cmake_minimum_required(VERSION 3.5)

set(CMAKE_CXX_STANDARD 14)
cmake_policy(SET CMP0065 NEW)

if (STATIC_BINARY)
    message("Building static portable binary with small size")
endif ()


# Set the project name
project(DPITunnel-cli)

find_package(PkgConfig REQUIRED)

# Add dependencies
add_subdirectory(RawSocket)

pkg_check_modules(OPENSSL REQUIRED openssl)
pkg_check_modules(OPENSSL_CRYPTO REQUIRED libcrypto)
pkg_check_modules(LIBNL REQUIRED libnl-genl-3.0)
pkg_check_modules(CPP-HTTPLIB REQUIRED cpp-httplib)
pkg_check_modules(DNSLIB REQUIRED dnslib)

set(OPENSSL_ROOT_DIR "${OPENSSL_PREFIX}")

# Add an executable
add_executable(DPITunnel-cli-exec
        autoconf.cpp
        desync.cpp
        dns.cpp
        dpitunnel-cli.cpp
        netiface.cpp
        packet.cpp
        profiles.cpp
        socket.cpp
        ssl.cpp
        utils.cpp
        )

if (STATIC_BINARY)
    target_link_libraries(DPITunnel-cli-exec -static)
    target_link_options(DPITunnel-cli-exec PRIVATE "LINKER:--gc-sections")
    target_link_options(DPITunnel-cli-exec PRIVATE "LINKER:-s")
    target_compile_options(DPITunnel-cli-exec PRIVATE -ffunction-sections)
endif ()

# Set the directories that should be included in the build command for this target
target_include_directories(DPITunnel-cli-exec
        PRIVATE
        ${PROJECT_SOURCE_DIR}/include
        ${PROJECT_SOURCE_DIR}/RawSocket/include
        )

target_include_directories(DPITunnel-cli-exec PUBLIC ${LIBNL_INCLUDE_DIRS})
target_include_directories(DPITunnel-cli-exec PUBLIC ${CPP-HTTPLIB_INCLUDE_DIRS})
target_include_directories(DPITunnel-cli-exec PUBLIC ${DNSLIB_INCLUDE_DIRS})

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

if (STATIC_BINARY)
    set(OPENSSL_USE_STATIC_LIBS TRUE)
endif ()
find_package(OpenSSL REQUIRED)

target_link_libraries(DPITunnel-cli-exec
        RawSocket
        cpp-httplib
        dnslib
        Threads::Threads
        OpenSSL::SSL
        OpenSSL::Crypto
        )
target_link_libraries(DPITunnel-cli-exec ${LIBNL_LIBRARIES})
target_link_libraries(DPITunnel-cli-exec ${CPP-HTTPLIB_LIBRARIES})
target_link_libraries(DPITunnel-cli-exec ${DNSLIB_LIBRARIES})

if (STATIC_BINARY)
    target_link_libraries(DPITunnel-cli-exec ${CMAKE_DL_LIBS})
endif ()
