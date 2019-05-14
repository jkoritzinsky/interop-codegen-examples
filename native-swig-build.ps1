cmake -S . -B build -DCMAKE_INSTALL_PREFIX=bin
cmake --build build --target install

dotnet build .\SwigWrapperLibrary\SwigWrapperLibrary.csproj