using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CppSharp;
using CppSharp.AST;
using CppSharp.Passes;

namespace CppSharpGenerator
{
    class TestLibrary : ILibrary
    {
        public void Postprocess(Driver driver, ASTContext ctx)
        {
        }

        public void Preprocess(Driver driver, ASTContext ctx)
        {
        }

        public void Setup(Driver driver)
        {
            var options = driver.Options;
            options.GeneratorKind = CppSharp.Generators.GeneratorKind.CSharp;

            var module = options.AddModule("Native");
            module.IncludeDirs.Add(@"C:\Users\jekoritz\source\experiments\CppSharp\bin\inc");
            module.Headers.Add("Native.h");
            module.LibraryDirs.Add(@"C:\Users\jekoritz\source\experiments\CppSharp\bin\bin");
            module.Libraries.Add("Native.dll");
        }

        public void SetupPasses(Driver driver)
        {
            driver.Context.TranslationUnitPasses.RenameDeclsUpperCase(RenameTargets.Any);
        }
    }
}
