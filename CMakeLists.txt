cmake_minimum_required(VERSION 3.15)

project(poker)

add_custom_target(poker
        COMMAND dub build --dest ${CMAKE_BINARY_DIR} --build=debug
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)