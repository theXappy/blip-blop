#Requires -Version 5.1
<#
.SYNOPSIS
    Builds Blip'n Blop 3 on Windows using the Visual Studio 2026 toolchain.

.DESCRIPTION
    Requires the SDL2 and SDL2_mixer VC dev packages.
    Expected locations (edit the variables below if yours differ):
        SDL2       - C:\Users\<you>\Downloads\SDL2-devel-2.30.11-VC\SDL2-2.30.11
        SDL2_mixer - C:\Users\<you>\Downloads\SDL2_mixer-devel-2.8.1-VC\SDL2_mixer-2.8.1

    Output: build\cmake\Release\blipblop.exe  (with SDL2 DLLs copied alongside)
#>
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# ─── Tool locations ───────────────────────────────────────────────────────────
$vsRoot  = 'C:\Program Files\Microsoft Visual Studio\18\Insiders'
$cmake   = "$vsRoot\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

foreach ($tool in $cmake) {
    if (-not (Test-Path $tool)) {
        throw "Required tool not found: $tool`nPlease verify your Visual Studio installation."
    }
}

# ─── Dependency locations (edit these if your downloads are elsewhere) ────────
$sdl2Root  = 'C:\Users\Shai\Downloads\SDL2-devel-2.30.11-VC\SDL2-2.30.11'
$mixerRoot = 'C:\Users\Shai\Downloads\SDL2_mixer-devel-2.8.1-VC\SDL2_mixer-2.8.1'

foreach ($dep in $sdl2Root, $mixerRoot) {
    if (-not (Test-Path $dep)) {
        throw "Dependency not found: $dep`nPlease download the SDL2 / SDL2_mixer VC dev packages."
    }
}

# ─── Directories ──────────────────────────────────────────────────────────────
$srcDir        = "$PSScriptRoot\vc-projects\Blip_n_Blop_3"
$buildDir      = "$PSScriptRoot\build"
$cmakeBuildDir = "$buildDir\cmake"

# ─── Create merged SDL2 include staging dir ───────────────────────────────────
# The code uses <SDL2/SDL.h> / <SDL2/SDL_mixer.h> style includes, but the VC
# dev packages put headers flat in include/ (not include/SDL2/).  We create a
# staging directory build\sdl2_inc\SDL2\ that the compiler sees as the SDL2
# subfolder, then tell CMake to use build\sdl2_inc as the include root.
$sdlIncStaging = "$buildDir\sdl2_inc"
$sdlIncSDL2dir = "$sdlIncStaging\SDL2"

Write-Host "Setting up SDL2 include staging dir..."
New-Item -ItemType Directory -Force $sdlIncSDL2dir | Out-Null
Copy-Item "$sdl2Root\include\*.h"  $sdlIncSDL2dir -Force
Copy-Item "$mixerRoot\include\*.h" $sdlIncSDL2dir -Force

# ─── CMake configure ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Configuring (CMake)..."
New-Item -ItemType Directory -Force $cmakeBuildDir | Out-Null

& $cmake `
    -S $srcDir `
    -B $cmakeBuildDir `
    -G "Visual Studio 18 2026" `
    -A x64 `
    "-DSDL2_DIR=$sdl2Root\cmake" `
    "-DSDL2_INCLUDE_DIRS=$sdlIncStaging" `
    "-DSDL2MIXER_LIBRARIES=$mixerRoot\lib\x64\SDL2_mixer.lib"

if ($LASTEXITCODE -ne 0) { throw "CMake configure failed (exit code $LASTEXITCODE)" }

# ─── Build ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Building (Release)..."

& $cmake --build $cmakeBuildDir --config Release

if ($LASTEXITCODE -ne 0) { throw "CMake build failed (exit code $LASTEXITCODE)" }

# ─── Copy runtime DLLs and game data next to the executable ──────────────────
$outDir = "$cmakeBuildDir\Release"
Write-Host ""
Write-Host "Copying runtime DLLs to $outDir ..."
Copy-Item "$sdl2Root\lib\x64\SDL2.dll"        $outDir -Force
Copy-Item "$mixerRoot\lib\x64\SDL2_mixer.dll" $outDir -Force

Write-Host "Copying game data to $outDir ..."
Copy-Item "$srcDir\data" $outDir -Recurse -Force

Write-Host ""
Write-Host "Build complete."
Write-Host "Executable : $outDir\blipblop.exe"
