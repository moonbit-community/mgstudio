// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "moonbit.h"

#include <dlfcn.h>
#include <limits.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>

typedef size_t (*mgimg_zstd_decompress_fn)(
    void *dst,
    size_t dst_capacity,
    const void *src,
    size_t compressed_size);
typedef unsigned int (*mgimg_zstd_is_error_fn)(size_t code);
typedef unsigned long long (*mgimg_zstd_frame_size_fn)(const void *src, size_t src_size);

static mgimg_zstd_decompress_fn mgimg_zstd_decompress_ptr = NULL;
static mgimg_zstd_is_error_fn mgimg_zstd_is_error_ptr = NULL;
static mgimg_zstd_frame_size_fn mgimg_zstd_frame_size_ptr = NULL;
static int mgimg_zstd_resolved = 0;

#ifndef ZSTD_CONTENTSIZE_UNKNOWN
#define ZSTD_CONTENTSIZE_UNKNOWN (0ULL - 1ULL)
#endif
#ifndef ZSTD_CONTENTSIZE_ERROR
#define ZSTD_CONTENTSIZE_ERROR (0ULL - 2ULL)
#endif

static inline int32_t mgimg_safe_len(moonbit_bytes_t bytes) {
  if (!bytes) {
    return 0;
  }
  return (int32_t)Moonbit_array_length(bytes);
}

static int mgimg_try_load_zstd(void) {
  if (mgimg_zstd_resolved) {
    return mgimg_zstd_decompress_ptr != NULL &&
           mgimg_zstd_is_error_ptr != NULL &&
           mgimg_zstd_frame_size_ptr != NULL;
  }
  mgimg_zstd_resolved = 1;

  void *handle = dlopen("libzstd.dylib", RTLD_LAZY);
  if (!handle) {
    handle = dlopen("libzstd.so.1", RTLD_LAZY);
  }
  if (!handle) {
    handle = dlopen("libzstd.so", RTLD_LAZY);
  }
  if (!handle) {
    return 0;
  }

  mgimg_zstd_decompress_ptr =
      (mgimg_zstd_decompress_fn)dlsym(handle, "ZSTD_decompress");
  mgimg_zstd_is_error_ptr =
      (mgimg_zstd_is_error_fn)dlsym(handle, "ZSTD_isError");
  mgimg_zstd_frame_size_ptr =
      (mgimg_zstd_frame_size_fn)dlsym(handle, "ZSTD_getFrameContentSize");
  if (!mgimg_zstd_decompress_ptr || !mgimg_zstd_is_error_ptr ||
      !mgimg_zstd_frame_size_ptr) {
    mgimg_zstd_decompress_ptr = NULL;
    mgimg_zstd_is_error_ptr = NULL;
    mgimg_zstd_frame_size_ptr = NULL;
    return 0;
  }
  return 1;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mgimg_zstd_decompress(
    moonbit_bytes_t bytes,
    int32_t expected_len) {
  int32_t src_len = mgimg_safe_len(bytes);
  if (!bytes || src_len <= 0) {
    return moonbit_make_bytes_raw(0);
  }
  if (!mgimg_try_load_zstd()) {
    return moonbit_make_bytes_raw(0);
  }

  size_t out_len = 0;
  if (expected_len > 0) {
    out_len = (size_t)expected_len;
  } else {
    unsigned long long frame_len =
        mgimg_zstd_frame_size_ptr((const void *)bytes, (size_t)src_len);
    if (frame_len == ZSTD_CONTENTSIZE_UNKNOWN ||
        frame_len == ZSTD_CONTENTSIZE_ERROR ||
        frame_len > (unsigned long long)INT32_MAX) {
      return moonbit_make_bytes_raw(0);
    }
    out_len = (size_t)frame_len;
  }
  if (out_len == 0 || out_len > (size_t)INT32_MAX) {
    return moonbit_make_bytes_raw(0);
  }

  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)out_len);
  size_t written = mgimg_zstd_decompress_ptr(
      (void *)out, out_len, (const void *)bytes, (size_t)src_len);
  if (mgimg_zstd_is_error_ptr(written)) {
    return moonbit_make_bytes_raw(0);
  }
  if (expected_len > 0 && written != out_len) {
    return moonbit_make_bytes_raw(0);
  }
  if (written == out_len) {
    return out;
  }
  if (written == 0 || written > (size_t)INT32_MAX) {
    return moonbit_make_bytes_raw(0);
  }
  moonbit_bytes_t shrink = moonbit_make_bytes_raw((int32_t)written);
  memcpy(shrink, out, written);
  return shrink;
}
