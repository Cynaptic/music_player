// Minimal stubs for Verilator threading symbols in WASM
// These satisfy linker without pulling in pthread dependencies

#include "verilated_threads.h"

VlThreadPool::VlThreadPool(VerilatedContext*, unsigned) {}
VlThreadPool::~VlThreadPool() {}
