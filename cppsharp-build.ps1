$env:VS_VERSION='vs2017'
$env:BUILD_PLATFORM='x86'
$env:DEPS_PATH="$PWD" + "/CppSharp/deps"
$env:LLVM_PATH=$env:DEPS_PATH + "/llvm"
$env:BUILD_PATH = "$PWD" + "/CppSharp/build/$env:VS_VERSION"
$env:LIB_PATH = $env:LIB_PATH + "/lib/Debug_$env:BUILD_PLATFORM"

Start-Developer-Prompt
.\CppSharp\build\premake5.exe --file=.\CppSharp\build\scripts\LLVM.lua download_llvm RelWithDebInfo
.\CppSharp\build\premake5.exe --file=.\CppSharp\build\premake5.lua $env:VS_VERSION

msbuild $env:BUILD_PATH\CppSharp.sln /p:Configuration=Release /p:Platform=x86

msbuild .\CppSharpGenerator\CppSharpGenerator.csproj

.\CppSharpGenerator\bin\Debug\CppSharpGenerator.exe
