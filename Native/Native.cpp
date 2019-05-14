#include "Native.h"

void Derived::Test() {}
void Derived::Test2() {}

NATIVE_EXPORT std::string TestString(std::string byVal, std::string& byRef){return byVal;}