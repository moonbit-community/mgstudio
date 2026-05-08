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

#include <stdint.h>
#if defined(__APPLE__)
#include <objc/message.h>
#include <objc/runtime.h>

typedef unsigned long mgstudio_ns_uint;

typedef struct {
  double x;
  double y;
} mgstudio_cg_point;

typedef struct {
  double width;
  double height;
} mgstudio_cg_size;

typedef struct {
  mgstudio_cg_point origin;
  mgstudio_cg_size size;
} mgstudio_cg_rect;

static id mgstudio_find_content_view_by_raw_id(int32_t target_raw_id) {
  if (target_raw_id <= 0) {
    return (id)0;
  }

  Class app_class = (Class)objc_getClass("NSApplication");
  if (!app_class) {
    return (id)0;
  }

  id app = ((id(*)(id, SEL))objc_msgSend)(
    (id)app_class,
    sel_registerName("sharedApplication"));
  if (!app) {
    return (id)0;
  }

  id windows = ((id(*)(id, SEL))objc_msgSend)(
    app,
    sel_registerName("windows"));
  if (!windows) {
    return (id)0;
  }

  mgstudio_ns_uint count = ((mgstudio_ns_uint(*)(id, SEL))objc_msgSend)(
    windows,
    sel_registerName("count"));
  for (mgstudio_ns_uint i = 0; i < count; i++) {
    id window = ((id(*)(id, SEL, mgstudio_ns_uint))objc_msgSend)(
      windows,
      sel_registerName("objectAtIndex:"),
      i);
    if (!window) {
      continue;
    }

    id content_view = ((id(*)(id, SEL))objc_msgSend)(
      window,
      sel_registerName("contentView"));
    if (!content_view) {
      continue;
    }

    BOOL has_raw_id = ((BOOL(*)(id, SEL, SEL))objc_msgSend)(
      content_view,
      sel_registerName("respondsToSelector:"),
      sel_registerName("rawId"));
    if (!has_raw_id) {
      continue;
    }

    int32_t raw_id = ((int32_t(*)(id, SEL))objc_msgSend)(
      content_view,
      sel_registerName("rawId"));
    if (raw_id == target_raw_id) {
      return content_view;
    }
  }

  return (id)0;
}
#endif

void mgstudio_window_attach_metal_layer(int32_t raw_window_id, void *layer) {
#if defined(__APPLE__)
  if (!layer) {
    return;
  }

  if (raw_window_id <= 0) {
    return;
  }

  id content_view = mgstudio_find_content_view_by_raw_id(raw_window_id);
  if (!content_view) {
    return;
  }

  double scale = 1.0;
  id window = ((id(*)(id, SEL))objc_msgSend)(
    content_view,
    sel_registerName("window"));
  if (window) {
    scale = ((double(*)(id, SEL))objc_msgSend)(
      window,
      sel_registerName("backingScaleFactor"));
  }
  if (scale <= 0.0) {
    Class screen_class = (Class)objc_getClass("NSScreen");
    if (screen_class) {
      id screen = ((id(*)(id, SEL))objc_msgSend)(
        (id)screen_class,
        sel_registerName("mainScreen"));
      if (screen) {
        scale = ((double(*)(id, SEL))objc_msgSend)(
          screen,
          sel_registerName("backingScaleFactor"));
      }
    }
  }
  if (scale <= 0.0) {
    scale = 1.0;
  }

  mgstudio_cg_rect bounds = ((mgstudio_cg_rect(*)(id, SEL))objc_msgSend)(
    content_view,
    sel_registerName("bounds"));

  ((void(*)(id, SEL, double))objc_msgSend)(
    (id)layer,
    sel_registerName("setContentsScale:"),
    scale);
  ((void(*)(id, SEL, mgstudio_cg_rect))objc_msgSend)(
    (id)layer,
    sel_registerName("setFrame:"),
    bounds);
  mgstudio_cg_size drawable_size = {
    bounds.size.width * scale,
    bounds.size.height * scale,
  };
  ((void(*)(id, SEL, mgstudio_cg_size))objc_msgSend)(
    (id)layer,
    sel_registerName("setDrawableSize:"),
    drawable_size);
  ((void(*)(id, SEL, mgstudio_ns_uint))objc_msgSend)(
    (id)layer,
    sel_registerName("setAutoresizingMask:"),
    (mgstudio_ns_uint)((1u << 1) | (1u << 4)));

  ((void(*)(id, SEL, BOOL))objc_msgSend)(
    content_view,
    sel_registerName("setWantsLayer:"),
    (BOOL)1);
  ((void(*)(id, SEL, id))objc_msgSend)(
    content_view,
    sel_registerName("setLayer:"),
    (id)layer);
  window = ((id(*)(id, SEL))objc_msgSend)(
    content_view,
    sel_registerName("window"));
  if (window) {
    double attached_scale = ((double(*)(id, SEL))objc_msgSend)(
      window,
      sel_registerName("backingScaleFactor"));
    if (attached_scale > 0.0) {
      scale = attached_scale;
    }
  }
  bounds = ((mgstudio_cg_rect(*)(id, SEL))objc_msgSend)(
    content_view,
    sel_registerName("bounds"));
  drawable_size.width = bounds.size.width * scale;
  drawable_size.height = bounds.size.height * scale;
  ((void(*)(id, SEL, double))objc_msgSend)(
    (id)layer,
    sel_registerName("setContentsScale:"),
    scale);
  ((void(*)(id, SEL, mgstudio_cg_rect))objc_msgSend)(
    (id)layer,
    sel_registerName("setFrame:"),
    bounds);
  ((void(*)(id, SEL, mgstudio_cg_size))objc_msgSend)(
    (id)layer,
    sel_registerName("setDrawableSize:"),
    drawable_size);
#else
  (void)raw_window_id;
  (void)layer;
#endif
}
