// Emscripten/WASM compatibility for Verilator
// Force-included before all sources via -include flag

#define VL_IGNORE_UNKNOWN_ARCH 1
#define VL_THREADED 0
#define VL_MT_DISABLED_CODE_UNIT 1
