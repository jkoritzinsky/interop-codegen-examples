#include "Native.h"

void Derived::Test() {}

NATIVE_EXPORT std::string TestString(std::string byVal, std::string& byRef){return byVal;}