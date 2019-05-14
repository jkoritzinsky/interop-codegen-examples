
#include "native_export.h"

#ifndef SWIG
#include <string>

#endif
NATIVE_EXPORT std::string TestString(std::string byVal, std::string& byRef);

class Base {
    public:
    NATIVE_EXPORT virtual void Test() = 0;
};

class Derived : public Base {
    public:
    NATIVE_EXPORT void Test() override;
};

struct OperatorOverload
{
    OperatorOverload operator+(const OperatorOverload& rhs);
    OperatorOverload operator+(int test);
    OperatorOverload& operator+=(const OperatorOverload& rhs);
};

OperatorOverload operator+(int lhs, OperatorOverload& rhs);

struct BitField
{
    int a:1;
    int b:1;
    int c:29;
    int d:1;
};