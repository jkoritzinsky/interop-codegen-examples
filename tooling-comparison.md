# Interop CodeGen Solutions

There exist a few OSS C# interop code-gen solutions today that we've been recommending in various capacities. This document takes a bit of a deeper dive into each of the tools and explores if or how we should be recommending these tools to our users.

## SWIG

SWIG is a general purpose multi-language C/C++ interop code generator. It has code-generation backends for a wide variety of languages, including C#. It's general design philosophy is to do as much work in native code as possible so as to basically eliminate the amount of ABI knowledge that the tool must have. For each member that it is mapping to the target language, it generates a small native function that wraps the underlying C/C++ operation. For C#, this means that every field access, method call, object construction, etc has the overhead of a P/Invoke (with an IL stub for `HandleRef`s for `this` pointers). SWIG uses its own C/C++ parser, so it lags behind in supporting language features. Additionally, it has it's own DSL for generating the mappings that varies slightly for each target language. Their documentation for C# in particular is spotty and directs you to the (mostly applicable) Java documentation where it is not filled in.

They technically do not say whether or not they officially support .NET Core and their C# samples haven't been updated in 4-5 years, but it seems other than the extremely outdated project files, the samples themselves would work on .NET Core.

In terms of build system integration, CMake ships with a SWIG module, but their documentation is also lacking. I've gotten a proof of concept working with the generation using the CMake integration. Outside of CMake, they have no integration with any other build tools. SWIG's design is more aimed at developers of native libraries who want to provides wrappers for various languages than at developers of the consuming languages that want to wrap a native library.

## CppSharp

CppSharp is a project mantained by the Mono community aimed at generating extremely accurate C# to wrap nearly any C++ construct with minimal generated native code. It uses the Clang parser and the LLVM engine to parse the C++ code and generate ABI-specific C#. As a result, the user will need to build a separate managed DLL for each OS/architecture combination. Also, from my investigation into it, it seems that the CppSharp tool does not support cross-compilation. As a result, the user must run their generator on each combination that they want to have interop code. The generator itself is written by the user in any .NET language using the CppSharp library with a very simple and easy to use API. From my experience, CppSharp generates small native wrappers for constructors (regular, copy, and move), destructors, and (copy/move) assignment operators. As far as I can tell, this generated native code may or may not be used. It is primarily generated so that users can compile and link it against the native library to ensure that all symbols are present. CppSharp also generates native code that instantiates and exports any template instantiations that it processes during generation to ensure that all of the members are available. This native code must be compiled and linked into a shared native library because it is used by any generated code for templates.

CppSharp-generated code works on .NET Core 3.0 (its heavy usage of explicit layout causes it to fail on pre-3.0 runtimes off-Windows); however, the generator projects are still .NET Framework/Mono only. There is an issue open for moving the generators to support running on .NET Core.

CppSharp has no recommended or built-in build integration. In fact, the NuGet package for CppSharp is only for generating code for interoperating with Windows/x64. To build with any other project, you must have a local clone of CppSharp to reference. Additionally, CppSharp uses Premake as its build orchestrator, which makes it the only project I know that uses it, other than projects that consume CppSharp. Additionally, the lack of built-in support in the .NET Core SDK for architecture-specific managed libraries makes it even more difficult to easily hook CppSharp into an existing build system for generating nuget packages. However, since the generator is a regular C# console application, customers could link it into a Nuke-based build script.

Additionally, the released version CppSharp fails with a StackOverflowException on a system that only has Visual Studio 2019 (fixed in master).

## SharpGenTools

SharpGenTools is a purpose-built code generator initially designed to support the SharpDX project. Like CppSharp, it tries to keep as much computation in the managed space as possible. It primarily supports C-style and COM-style APIs in the vein of Windows APIs, including quite a few convenience features to help make the interop code feel similar to what similar interop code written just using built-in .NET features (like P/Invoke or COM) would look like without SharpGenTools. Additionally, SharpGenTools generates all of its own interop marshalling code and uses only blittable types when calling the native code. Currently it has quite a few workarounds for Windows ABI-specific quirks. SharpGenTools generates no native code at any point in the build; all code it generates is plain C#. However, SharpGenTools has a post-processing patching step to patch in `unmanaged calli` instructions to actually do native calls on vtables. SharpGenTools mappings are configured through XML files that are effectively like scripts. All of the script options are documented in SharpGenTools' documentation, but the documentation is not currently set up to show up in any IDE environments, making it difficult for users to discover the various options without knowing where the documentation is located.

SharpGenTools officially supports all versions of .NET Core. It has partial support for generating code on or for non-Windows platforms (available in CI builds).

SharpGenTools has built-in support for hooking directly into the MSBuild process. The generation and patching run during the build, allowing users to use all of the features of the .NET SDK as they would expect. There also exist some CLI tools for SharpGenTools, but they are not officially supported and have so far been kept only for legacy reasons.

## Unexplored tools

There are a variety of other tools for cross-language interop such as WinRT and XLang. This document does not cover them since it exclusively focuses on tools that allow you to use a native library as-is and not have to manually write any native code to enable your interop story.

## Honorable Mention - CppAst

CppAst is a brand new library that uses libclang to parse C++ headers into an AST (via ClangSharp). It is intended to be used as the parsing frontend for custom, domain-specific interop code generation. It enables users to build their code generation however fits their scenario best. Unlike the other tools mentioned here, it does not actually generate any C# code on its own.

## Summary

Once you get started with SWIG, it is a reasonable option when you own the native library and want to mantain the language bindings for your library yourself, especially if you want to mantain bindings for many languages. However, it is not the most performant wrapper.

If you want to wrap a library that uses a very large number of standard C++ features and want to surface all of those features up to C#, then CppSharp is your only option. However, the process of getting a CppSharp build up and running is difficult at best.

If you want to wrap a library that has a C-style or COM-style public interface, SharpGenTools is the best option. It has the simplest setup and the least amount of customization required to insert into a build process. Additionally, it allows you to use the .NET SDK as-is and do a simple `dotnet build` command to get all of the interop code into your project correctly.

If you want full control over the code that is emitted, you can create your own generator with CppAst as your parser frontend.

The hello-world style examples are located at <https://github.com/jkoritzinsky/interop-codegen-examples>

## Customer Scenarios

- I have a large COM codebase and I want to go cross-plat. I don't want to fork CoreCLR to try to enable the COM feature flags. I want a tool that allows me to use my code-base with minimal alterations.

For this scenario, SharpGenTools is the best tool. It has a variety of features in its mappings specifically tooled towards COM semantics and patterns and has support libraries for COM code. By default it requires users to use `IDisposable` to dispose their references, but there is a runtime configuration field to allow users to use finalization-like semantics instead if they so desire (to help minimize changes needed from their Windows code).

- I have a large C++ codebase that I would like to integrate into my current .NET project. I don't use COM and don't want to manually wrap the library with a C API. This library uses a wide variety of C++ features.

For this scenario, CppSharp is the best tool. It has support for accurately mapping nearly every C++ feature in C#.

- I mantain a C/C++ native library and I want to enable users in C# to consume my library

For this scenario, SWIG is the best tool. It integrates into the native CMake build system and will automatically build the wrapper library with the same flags as the managed library. Additionally, users could also add support for various other languages with SWIG, helping them optimize the amount of work they need to do to add various language bindings.

## Examples

For the following header, here's a snippet of the code generated by the various tools:

```c++
NATIVE_EXPORT std::string TestString(std::string byVal, std::string& byRef);

class Base {
    public:
    NATIVE_EXPORT virtual void Test() = 0;
};

class Derived : public Base {
    public:
    NATIVE_EXPORT void Test() override;
};
```

### SWIG

```csharp

public class Base : global::System.IDisposable {
  private global::System.Runtime.InteropServices.HandleRef swigCPtr;
  protected bool swigCMemOwn;

  internal Base(global::System.IntPtr cPtr, bool cMemoryOwn) {
    swigCMemOwn = cMemoryOwn;
    swigCPtr = new global::System.Runtime.InteropServices.HandleRef(this, cPtr);
  }

  internal static global::System.Runtime.InteropServices.HandleRef getCPtr(Base obj) {
    return (obj == null) ? new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero) : obj.swigCPtr;
  }

  ~Base() {
    Dispose();
  }

  public virtual void Dispose() {
    lock(this) {
      if (swigCPtr.Handle != global::System.IntPtr.Zero) {
        if (swigCMemOwn) {
          swigCMemOwn = false;
          NativePINVOKE.delete_Base(swigCPtr);
        }
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero);
      }
      global::System.GC.SuppressFinalize(this);
    }
  }

  public virtual void Test() {
    NativePINVOKE.Base_Test(swigCPtr);
  }

}


public class Derived : Base {
  private global::System.Runtime.InteropServices.HandleRef swigCPtr;

  internal Derived(global::System.IntPtr cPtr, bool cMemoryOwn) : base(NativePINVOKE.Derived_SWIGUpcast(cPtr), cMemoryOwn) {
    swigCPtr = new global::System.Runtime.InteropServices.HandleRef(this, cPtr);
  }

  internal static global::System.Runtime.InteropServices.HandleRef getCPtr(Derived obj) {
    return (obj == null) ? new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero) : obj.swigCPtr;
  }

  ~Derived() {
    Dispose();
  }

  public override void Dispose() {
    lock(this) {
      if (swigCPtr.Handle != global::System.IntPtr.Zero) {
        if (swigCMemOwn) {
          swigCMemOwn = false;
          NativePINVOKE.delete_Derived(swigCPtr);
        }
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero);
      }
      global::System.GC.SuppressFinalize(this);
      base.Dispose();
    }
  }

  public override void Test() {
    NativePINVOKE.Derived_Test(swigCPtr);
  }

  public Derived() : this(NativePINVOKE.new_Derived(), true) {
  }

}

public class Native {
  public static string TestString(string byVal, SWIGTYPE_p_std__string byRef) {
    string ret = NativePINVOKE.TestString(byVal, SWIGTYPE_p_std__string.getCPtr(byRef));
    if (NativePINVOKE.SWIGPendingException.Pending) throw NativePINVOKE.SWIGPendingException.Retrieve();
    return ret;
  }

}

public class SWIGTYPE_p_std__string {
  private global::System.Runtime.InteropServices.HandleRef swigCPtr;

  internal SWIGTYPE_p_std__string(global::System.IntPtr cPtr, bool futureUse) {
    swigCPtr = new global::System.Runtime.InteropServices.HandleRef(this, cPtr);
  }

  protected SWIGTYPE_p_std__string() {
    swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero);
  }

  internal static global::System.Runtime.InteropServices.HandleRef getCPtr(SWIGTYPE_p_std__string obj) {
    return (obj == null) ? new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero) : obj.swigCPtr;
  }
}

```

```c++

SWIGEXPORT char * SWIGSTDCALL CSharp_TestString(char * jarg1, void * jarg2) {
  char * jresult ;
  std::string arg1 ;
  std::string *arg2 = 0 ;
  std::string result;
  
  if (!jarg1) {
    SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentNullException, "null string", 0);
    return 0;
  }
  (&arg1)->assign(jarg1); 
  arg2 = (std::string *)jarg2;
  if (!arg2) {
    SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentNullException, "std::string & type is null", 0);
    return 0;
  } 
  result = TestString(arg1,*arg2);
  jresult = SWIG_csharp_string_callback((&result)->c_str()); 
  return jresult;
}


SWIGEXPORT void SWIGSTDCALL CSharp_Base_Test(void * jarg1) {
  Base *arg1 = (Base *) 0 ;
  
  arg1 = (Base *)jarg1; 
  (arg1)->Test();
}


SWIGEXPORT void SWIGSTDCALL CSharp_delete_Base(void * jarg1) {
  Base *arg1 = (Base *) 0 ;
  
  arg1 = (Base *)jarg1; 
  delete arg1;
}


SWIGEXPORT void SWIGSTDCALL CSharp_Derived_Test(void * jarg1) {
  Derived *arg1 = (Derived *) 0 ;
  
  arg1 = (Derived *)jarg1; 
  (arg1)->Test();
}


SWIGEXPORT void * SWIGSTDCALL CSharp_new_Derived() {
  void * jresult ;
  Derived *result = 0 ;
  
  result = (Derived *)new Derived();
  jresult = (void *)result; 
  return jresult;
}


SWIGEXPORT void SWIGSTDCALL CSharp_delete_Derived(void * jarg1) {
  Derived *arg1 = (Derived *) 0 ;
  
  arg1 = (Derived *)jarg1; 
  delete arg1;
}


SWIGEXPORT Base * SWIGSTDCALL CSharp_Derived_SWIGUpcast(Derived *jarg1) {
    return (Base *)jarg1;
}
```

### CppSharp

```csharp
    public unsafe abstract partial class Base : IDisposable
    {
        [StructLayout(LayoutKind.Explicit, Size = 4)]
        public partial struct __Internal
        {
            [FieldOffset(0)]
            internal global::System.IntPtr vfptr_Base;

            [SuppressUnmanagedCodeSecurity]
            [DllImport("Native", CallingConvention = global::System.Runtime.InteropServices.CallingConvention.ThisCall,
                EntryPoint="??0Base@@QAE@XZ")]
            internal static extern global::System.IntPtr ctor(global::System.IntPtr __instance);

            [SuppressUnmanagedCodeSecurity]
            [DllImport("Native", CallingConvention = global::System.Runtime.InteropServices.CallingConvention.ThisCall,
                EntryPoint="??0Base@@QAE@ABV0@@Z")]
            internal static extern global::System.IntPtr cctor(global::System.IntPtr __instance, global::System.IntPtr _0);
        }

        public global::System.IntPtr __Instance { get; protected set; }

        protected int __PointerAdjustment;
        internal static readonly global::System.Collections.Concurrent.ConcurrentDictionary<IntPtr, global::Native.Base> NativeToManagedMap = new global::System.Collections.Concurrent.ConcurrentDictionary<IntPtr, global::Native.Base>();
        protected internal void*[] __OriginalVTables;

        protected bool __ownsNativeInstance;

        internal static global::Native.Base __CreateInstance(global::System.IntPtr native, bool skipVTables = false)
        {
            return new global::Native.BaseInternal(native.ToPointer(), skipVTables);
        }

        internal static global::Native.Base __CreateInstance(global::Native.Base.__Internal native, bool skipVTables = false)
        {
            return new global::Native.BaseInternal(native, skipVTables);
        }

        protected Base(void* native, bool skipVTables = false)
        {
            if (native == null)
                return;
            __Instance = new global::System.IntPtr(native);
            __OriginalVTables = new void*[] { *(void**) (__Instance + 0) };
        }

        protected Base()
        {
            __Instance = Marshal.AllocHGlobal(sizeof(global::Native.Base.__Internal));
            __ownsNativeInstance = true;
            NativeToManagedMap[__Instance] = this;
            __Internal.ctor((__Instance + __PointerAdjustment));
            SetupVTables(GetType().FullName == "Native.Base");
        }

        protected Base(global::Native.Base _0)
        {
            __Instance = Marshal.AllocHGlobal(sizeof(global::Native.Base.__Internal));
            __ownsNativeInstance = true;
            NativeToManagedMap[__Instance] = this;
            if (ReferenceEquals(_0, null))
                throw new global::System.ArgumentNullException("_0", "Cannot be null because it is a C++ reference (&).");
            var __arg0 = _0.__Instance;
            __Internal.cctor((__Instance + __PointerAdjustment), __arg0);
            SetupVTables(GetType().FullName == "Native.Base");
        }

        public void Dispose()
        {
            Dispose(disposing: true);
        }

        public virtual void Dispose(bool disposing)
        {
            if (__Instance == IntPtr.Zero)
                return;
            global::Native.Base __dummy;
            NativeToManagedMap.TryRemove(__Instance, out __dummy);
            ((global::Native.Base.__Internal*) __Instance)->vfptr_Base = new global::System.IntPtr(__OriginalVTables[0]);
            if (__ownsNativeInstance)
                Marshal.FreeHGlobal(__Instance);
            __Instance = IntPtr.Zero;
        }

        public abstract void Test();

        #region Virtual table interop

        // void Test() = 0
        private static global::Native.Delegates.Action_IntPtr _TestDelegateInstance;

        private static void _TestDelegateHook(global::System.IntPtr __instance)
        {
            if (!NativeToManagedMap.ContainsKey(__instance))
                throw new global::System.Exception("No managed instance was found");

            var __target = (global::Native.Base) NativeToManagedMap[__instance];
            if (__target.__ownsNativeInstance)
                __target.SetupVTables();
            __target.Test();
        }

        private static void*[] __ManagedVTables;
        private static void*[] _Thunks;

        private void SetupVTables(bool destructorOnly = false)
        {
            if (__OriginalVTables != null)
                return;
            __OriginalVTables = new void*[] { *(void**) (__Instance + 0) };

            if (destructorOnly)
                return;
            if (_Thunks == null)
            {
                _Thunks = new void*[1];
                _TestDelegateInstance += _TestDelegateHook;
                _Thunks[0] = Marshal.GetFunctionPointerForDelegate(_TestDelegateInstance).ToPointer();
            }

            if (__ManagedVTables == null)
            {
                __ManagedVTables = new void*[1];
                var vfptr0 = Marshal.AllocHGlobal(1 * 4);
                __ManagedVTables[0] = vfptr0.ToPointer();
                *(void**) (vfptr0 + 0) = _Thunks[0];
            }

            *(void**) (__Instance + 0) = __ManagedVTables[0];
        }

        #endregion
    }


    public unsafe partial class Derived : global::Native.Base, IDisposable
    {
        [StructLayout(LayoutKind.Explicit, Size = 4)]
        public new partial struct __Internal
        {
            [FieldOffset(0)]
            internal global::System.IntPtr vfptr_Base;

            [SuppressUnmanagedCodeSecurity]
            [DllImport("Native", CallingConvention = global::System.Runtime.InteropServices.CallingConvention.ThisCall,
                EntryPoint="??0Derived@@QAE@XZ")]
            internal static extern global::System.IntPtr ctor(global::System.IntPtr __instance);

            [SuppressUnmanagedCodeSecurity]
            [DllImport("Native", CallingConvention = global::System.Runtime.InteropServices.CallingConvention.ThisCall,
                EntryPoint="??0Derived@@QAE@ABV0@@Z")]
            internal static extern global::System.IntPtr cctor(global::System.IntPtr __instance, global::System.IntPtr _0);
        }

        internal static new global::Native.Derived __CreateInstance(global::System.IntPtr native, bool skipVTables = false)
        {
            return new global::Native.Derived(native.ToPointer(), skipVTables);
        }

        internal static global::Native.Derived __CreateInstance(global::Native.Derived.__Internal native, bool skipVTables = false)
        {
            return new global::Native.Derived(native, skipVTables);
        }

        private static void* __CopyValue(global::Native.Derived.__Internal native)
        {
            var ret = Marshal.AllocHGlobal(sizeof(global::Native.Derived.__Internal));
            global::Native.Derived.__Internal.cctor(ret, new global::System.IntPtr(&native));
            return ret.ToPointer();
        }

        private Derived(global::Native.Derived.__Internal native, bool skipVTables = false)
            : this(__CopyValue(native), skipVTables)
        {
            __ownsNativeInstance = true;
            NativeToManagedMap[__Instance] = this;
        }

        protected Derived(void* native, bool skipVTables = false)
            : base((void*) null)
        {
            __PointerAdjustment = 0;
            if (native == null)
                return;
            __Instance = new global::System.IntPtr(native);
            __OriginalVTables = new void*[] { *(void**) (__Instance + 0) };
        }

        public Derived()
            : this((void*) null)
        {
            __Instance = Marshal.AllocHGlobal(sizeof(global::Native.Derived.__Internal));
            __ownsNativeInstance = true;
            NativeToManagedMap[__Instance] = this;
            __Internal.ctor((__Instance + __PointerAdjustment));
            SetupVTables(GetType().FullName == "Native.Derived");
        }

        public Derived(global::Native.Derived _0)
            : this((void*) null)
        {
            __Instance = Marshal.AllocHGlobal(sizeof(global::Native.Derived.__Internal));
            __ownsNativeInstance = true;
            NativeToManagedMap[__Instance] = this;
            if (ReferenceEquals(_0, null))
                throw new global::System.ArgumentNullException("_0", "Cannot be null because it is a C++ reference (&).");
            var __arg0 = _0.__Instance;
            __Internal.cctor((__Instance + __PointerAdjustment), __arg0);
            SetupVTables(GetType().FullName == "Native.Derived");
        }

        public override void Test()
        {
            var __slot = *(void**) ((IntPtr) __OriginalVTables[0] + 0 * 4);
            var ___TestDelegate = (global::Native.Delegates.Action_IntPtr) Marshal.GetDelegateForFunctionPointer(new IntPtr(__slot), typeof(global::Native.Delegates.Action_IntPtr));
            ___TestDelegate((__Instance + __PointerAdjustment));
        }

        #region Virtual table interop

        // void Test() override
        private static global::Native.Delegates.Action_IntPtr _TestDelegateInstance;

        private static void _TestDelegateHook(global::System.IntPtr __instance)
        {
            if (!NativeToManagedMap.ContainsKey(__instance))
                throw new global::System.Exception("No managed instance was found");

            var __target = (global::Native.Derived) NativeToManagedMap[__instance];
            if (__target.__ownsNativeInstance)
                __target.SetupVTables();
            __target.Test();
        }

        private static void*[] __ManagedVTables;
        private static void*[] _Thunks;

        private void SetupVTables(bool destructorOnly = false)
        {
            if (__OriginalVTables != null)
                return;
            __OriginalVTables = new void*[] { *(void**) (__Instance + 0) };

            if (destructorOnly)
                return;
            if (_Thunks == null)
            {
                _Thunks = new void*[1];
                _TestDelegateInstance += _TestDelegateHook;
                _Thunks[0] = Marshal.GetFunctionPointerForDelegate(_TestDelegateInstance).ToPointer();
            }

            if (__ManagedVTables == null)
            {
                __ManagedVTables = new void*[1];
                var vfptr0 = Marshal.AllocHGlobal(1 * 4);
                __ManagedVTables[0] = vfptr0.ToPointer();
                *(void**) (vfptr0 + 0) = _Thunks[0];
            }

            *(void**) (__Instance + 0) = __ManagedVTables[0];
        }

        #endregion
    }

```

### SharpGenTools

Note: SharpGenTools does not support mapping templated types, so it cannot generate interop code for the `TestString` function. SharpGen also doesn't map constructors/destructors.

```csharp
    public partial class Base : SharpGen.Runtime.CppObject
    {
        public Base(System.IntPtr nativePtr): base (nativePtr)
        {
        }

        public static explicit operator Base(System.IntPtr nativePtr) => nativePtr == System.IntPtr.Zero ? null : new Base(nativePtr);
        /// <summary>
        /// No documentation.
        /// </summary>
        /// <unmanaged>void Base::Test()</unmanaged>
        /// <unmanaged-short>Base::Test</unmanaged-short>
        public unsafe void Test()
        {
            SharpGen.LocalInterop.CalliThisCallvoid(this._nativePointer, (*(void ***)this._nativePointer)[0]);
        }
    }

    public partial class Base2 : SharpGen.Runtime.CppObject
    {
        public Base2(System.IntPtr nativePtr): base (nativePtr)
        {
        }

        public static explicit operator Base2(System.IntPtr nativePtr) => nativePtr == System.IntPtr.Zero ? null : new Base2(nativePtr);
        /// <summary>
        /// No documentation.
        /// </summary>
        /// <unmanaged>void Base2::Test2()</unmanaged>
        /// <unmanaged-short>Base2::Test2</unmanaged-short>
        public unsafe void Test2()
        {
            SharpGen.LocalInterop.CalliThisCallvoid(this._nativePointer, (*(void ***)this._nativePointer)[0]);
        }
    }
```
