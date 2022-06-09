# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


cmake_minimum_required(VERSION 3.16.3)

project(peers)

# Find Proton components

find_package(Proton 0.37)
if (Proton_FOUND)
    get_filename_component(PROTON_INSTALL_DIR ${Proton_INCLUDE_DIRS} PATH CACHE PATH "Proton install directory")
    message(STATUS "Qpid proton found. Version ${Proton_VERSION} at ${Proton_INCLUDE_DIRS}")
else ()
    message(STATUS "ERROR: Qpid proton not found, but is required")
    set (ErrorFlag TRUE)
endif ()

find_package(ProtonCpp 0.37)
if (ProtonCpp_FOUND)
    get_filename_component(PROTON_CPP_INSTALL_DIR ${ProtonCpp_INCLUDE_DIRS} PATH CACHE PATH "ProtonCpp install directory")
    message(STATUS "Qpid proton c++ binding found. Version ${ProtonCpp_VERSION} at ${ProtonCpp_INCLUDE_DIRS}")
else()
    message(STATUS "ERROR: Qpid proton c++ binding not found, but is required")
    set (ErrorFlag TRUE)
endif ()

if (ErrorFlag)
    message(FATAL_ERROR "Proton components missing")
endif ()

include_directories(${PROTON_INSTALL_DIR}/include)
link_directories(${PROTON_INSTALL_DIR}/lib64)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

add_executable(sender
               src/sender.cpp
               src/options.hpp)
target_link_libraries(sender
                      qpid-proton-cpp)
