# C# Native Interop Code-generation Tools Hello-World samples

This repository contains hello-world style samples for each of the three following tools:

- SWIG
- CppSharp
- SharpGenTools

Each of the Powershell scripts in the root folder show the steps to generate code with each of the tools. Each of these scripts can be used with Powershell Core or adapted to Bash scripts.

- `native-swig-build.ps1`
  - Builds the native library we are using, as well as the SWIG native and managed wrappers. Uses CMake for the native build and SWIG integration.
- `cppsharp-build.ps1`
  - Builds CppSharp and the generator project. Runs the generator project. Builds the required generated native files. Builds the managed wrapper from the generated files.
- `sharpgen-build.ps1`
  - Builds the managed wrapper as part of the project. The mappings are described in the Mapping.xml file.
