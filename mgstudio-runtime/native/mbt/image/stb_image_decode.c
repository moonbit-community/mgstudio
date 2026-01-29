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

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// stb_image is public domain / MIT licensed. We vendor it here to avoid
// additional runtime dependencies.
#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_STDIO
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
#define STBI_ONLY_BMP
#define STBI_ONLY_GIF
#define STBI_ONLY_TGA
#define STBI_ONLY_HDR
#define STBI_ONLY_PSD
#define STBI_ONLY_PIC
#define STBI_ONLY_PNM
#include "stb_image.h"

typedef struct {
  int32_t width;
  int32_t height;
  uint8_t *pixels;
  int32_t len;
} mgimg_image_t;

static inline int32_t mgimg_safe_len(moonbit_bytes_t bytes) {
  if (!bytes) {
    return 0;
  }
  return (int32_t)Moonbit_array_length(bytes);
}

MOONBIT_FFI_EXPORT void *mgimg_decode_rgba8(moonbit_bytes_t bytes) {
  int32_t len = mgimg_safe_len(bytes);
  if (!bytes || len <= 0) {
    return NULL;
  }

  int w = 0;
  int h = 0;
  int channels = 0;
  stbi_uc *pixels = stbi_load_from_memory((const stbi_uc *)bytes, len, &w, &h, &channels, 4);
  if (!pixels || w <= 0 || h <= 0) {
    if (pixels) {
      stbi_image_free(pixels);
    }
    return NULL;
  }

  mgimg_image_t *img = (mgimg_image_t *)malloc(sizeof(mgimg_image_t));
  if (!img) {
    stbi_image_free(pixels);
    return NULL;
  }
  int64_t byte_len = (int64_t)w * (int64_t)h * 4;
  if (byte_len > INT32_MAX) {
    free(img);
    stbi_image_free(pixels);
    return NULL;
  }
  img->width = (int32_t)w;
  img->height = (int32_t)h;
  img->pixels = (uint8_t *)pixels;
  img->len = (int32_t)byte_len;
  return (void *)img;
}

MOONBIT_FFI_EXPORT bool mgimg_image_is_null(void *img) { return img == NULL; }

MOONBIT_FFI_EXPORT int32_t mgimg_image_width(void *img) {
  if (!img) {
    return 0;
  }
  return ((mgimg_image_t *)img)->width;
}

MOONBIT_FFI_EXPORT int32_t mgimg_image_height(void *img) {
  if (!img) {
    return 0;
  }
  return ((mgimg_image_t *)img)->height;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t mgimg_image_pixels_rgba8(void *img) {
  if (!img) {
    return moonbit_make_bytes_raw(0);
  }
  mgimg_image_t *p = (mgimg_image_t *)img;
  if (!p->pixels || p->len <= 0) {
    return moonbit_make_bytes_raw(0);
  }
  moonbit_bytes_t out = moonbit_make_bytes_raw(p->len);
  memcpy(out, p->pixels, (size_t)p->len);
  return out;
}

MOONBIT_FFI_EXPORT void mgimg_image_destroy(void *img) {
  if (!img) {
    return;
  }
  mgimg_image_t *p = (mgimg_image_t *)img;
  if (p->pixels) {
    stbi_image_free(p->pixels);
  }
  free(p);
}
