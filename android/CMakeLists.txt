cmake_minimum_required(VERSION 3.4.1)  # for example
project(native_tflite LANGUAGES CXX)

# add oboe pre-release lib hosted at https://maven.google.com/web/index.html
# under com.google.oboe:oboe. For documentation about oboe pre-built lib, refer to
# https://github.com/google/oboe/blob/master/docs/GettingStarted.md#option-1-using-pre-built-binaries-and-headers
find_package(oboe REQUIRED CONFIG)

add_library(${PROJECT_NAME}

        # Sets the library as a shared library.
        SHARED

        # Provides a relative path to your source file(s).
        ../ios/Classes/native_tflite.cpp
        ../ios/Classes/native_audio.cpp
        ../ios/Classes/audio_engine.cpp
        ../ios/Classes/audio_engine.h
        ../ios/Classes/logging_macros.h)
target_link_libraries(${PROJECT_NAME} oboe::oboe android log)

# Enable optimization flags: if having problems with source level debugging,
# disable -Ofast ( and debug ), re-enable after done debugging.
target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Werror "$<$<CONFIG:RELEASE>:-Ofast>")