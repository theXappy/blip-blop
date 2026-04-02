cmake_minimum_required(VERSION 3.10)

project(blipblop)

find_package(SDL2 REQUIRED)
find_library(SDL2_LIBRARIES SDL2)
find_library(SDL2MIXER_LIBRARIES SDL2_mixer)
find_path(SDL2_INCLUDE_DIRS SDL2/SDL.h)

aux_source_directory(. SRC)
aux_source_directory(Engine ENGINE_SRC)
aux_source_directory(menus MENUS_SRC)

if(WIN32)
    add_executable(blipblop ${SRC} ${ENGINE_SRC} ${MENUS_SRC})

    # SDL2main.lib also defines main() (for its console-app entry shim), which
    # conflicts with the game's own main().  Using SDL_MAIN_HANDLED prevents
    # SDL_main.h from renaming main→SDL_main, so we link only SDL2 (not SDL2main).
    target_compile_definitions(blipblop PRIVATE SDL_MAIN_HANDLED)
    target_link_libraries(blipblop PUBLIC SDL2::SDL2)

    target_link_libraries(blipblop PUBLIC ${SDL2MIXER_LIBRARIES})

    # find_package(SDL2) sets SDL2_INCLUDE_DIRS as a normal variable pointing to
    # the flat include/ dir of the VC dev package (no SDL2/ subdir). The code
    # uses <SDL2/SDL.h> style includes, so we use a staged include dir (created
    # by build.ps1) that has the SDL2/ subfolder.  Unset the normal variable so
    # the cache value supplied via -DSDL2_INCLUDE_DIRS takes effect.
    unset(SDL2_INCLUDE_DIRS)
    target_include_directories(blipblop SYSTEM PUBLIC ${SDL2_INCLUDE_DIRS})

    set(CMAKE_INSTALL_UCRT_LIBRARIES true)
    include(InstallRequiredSystemLibraries)
    install(DIRECTORY
        "${CMAKE_CURRENT_BINARY_DIR}/\${CMAKE_INSTALL_CONFIG_NAME}/"
        DESTINATION .
        FILES_MATCHING PATTERN "*.dll")
else()
    add_executable(blipblop WIN32 ${SRC} ${ENGINE_SRC} ${MENUS_SRC})
    target_link_libraries(blipblop SDL2)
    target_link_libraries(blipblop SDL2_mixer)
endif()

install(DIRECTORY ./data DESTINATION .)
install(TARGETS blipblop RUNTIME DESTINATION .)

set(CPACK_PACKAGE_NAME "BlipnBlop")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Blip & Blop revamped")
set(CPACK_PACKAGE_VENDOR "Loaded Studios")
set(CPACK_DEBIAN_PACKAGE_NAME "blipnblop")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libSDL2, libSD2-mixer")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Blip & Blop revamped")
set(CPACK_PACKAGE_EXECUTABLES "blipblop" "BlipnBlop")

if(WIN32)
    set(CPACK_NSIS_DISPLAY_NAME "Blip & Blop")
    set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
endif()

include(CPack)

