#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#if defined(_WIN32)
#include <windows.h>
#else
#include <dlfcn.h>
#endif

enum {
  MGSTUDIO_MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE = 1u << 0,
  MGSTUDIO_MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE = 1u << 1,
};

static void *mgstudio_meshlet_native_bridge_optional_sym(const char *name) {
#if defined(_WIN32)
  HMODULE module = GetModuleHandleA(NULL);
  if (module) {
    void *symbol = (void *)GetProcAddress(module, name);
    if (symbol) {
      return symbol;
    }
  }
  const char *lib = getenv("MBT_WGPU_NATIVE_LIB");
  if (lib && lib[0]) {
    module = LoadLibraryA(lib);
    if (module) {
      return (void *)GetProcAddress(module, name);
    }
  }
  const char *root = getenv("MBT_WGPU_NATIVE_ROOT");
  if (root && root[0]) {
    char path[4096];
    snprintf(path, sizeof(path), "%s\\lib\\wgpu_native.dll", root);
    module = LoadLibraryA(path);
    if (module) {
      return (void *)GetProcAddress(module, name);
    }
  }
  return 0;
#else
  void *symbol = dlsym(RTLD_DEFAULT, name);
  if (symbol) {
    return symbol;
  }
  const char *lib = getenv("MBT_WGPU_NATIVE_LIB");
  if (lib && lib[0]) {
    void *handle = dlopen(lib, RTLD_LAZY);
    if (handle) {
      return dlsym(handle, name);
    }
  }
  const char *root = getenv("MBT_WGPU_NATIVE_ROOT");
  if (root && root[0]) {
    char path[4096];
#if defined(__APPLE__)
    snprintf(path, sizeof(path), "%s/lib/libwgpu_native.dylib", root);
#else
    snprintf(path, sizeof(path), "%s/lib/libwgpu_native.so", root);
#endif
    void *handle = dlopen(path, RTLD_LAZY);
    if (handle) {
      return dlsym(handle, name);
    }
  }
  return 0;
#endif
}

uint32_t mgstudio_meshlet_native_extension_bridge_symbol_mask_u32(void) {
  uint32_t mask = 0u;

  if (mgstudio_meshlet_native_bridge_optional_sym(
          "mgstudioWGPUDeviceCreateMeshletVisibilityTexture")) {
    mask |= MGSTUDIO_MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE;
  }
  if (mgstudio_meshlet_native_bridge_optional_sym(
          "mgstudioWGPUBindGroupLayoutBuilderAddMeshletVisibilityStorageTexture")) {
    mask |= MGSTUDIO_MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE;
  }

  return mask;
}

uint32_t mgstudio_meshlet_native_extension_bridge_available_u32(void) {
  uint32_t required =
      MGSTUDIO_MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE |
      MGSTUDIO_MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE;
  return mgstudio_meshlet_native_extension_bridge_symbol_mask_u32() == required;
}
