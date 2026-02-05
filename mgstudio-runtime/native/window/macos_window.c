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
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void *mgw_objc_id;
typedef void *mgw_objc_sel;
typedef void *mgw_objc_class;

typedef struct {
  double x;
  double y;
} mgw_point;

typedef struct {
  double w;
  double h;
} mgw_size;

typedef struct {
  mgw_point origin;
  mgw_size size;
} mgw_rect;

typedef struct mgw_window {
  mgw_objc_id ns_window;
  mgw_objc_id content_view;
  mgw_objc_id metal_layer;
  // Physical size in pixels (used for surface configuration).
  int32_t width;
  int32_t height;
  // Logical size in points (used for input coordinate conversion).
  int32_t logical_width;
  int32_t logical_height;
  int32_t should_close;
  int32_t has_cursor;
  float mouse_x;
  float mouse_y;
  float wheel_x;
  float wheel_y;
  uint8_t key_down[256];
  uint8_t key_pressed[256];
  uint8_t key_released[256];
  uint8_t mouse_down[8];
  uint8_t mouse_pressed[8];
  uint8_t mouse_released[8];
} mgw_window_t;

// -----------------------------------------------------------------------------
// A11y (NSAccessibility) bridge
// -----------------------------------------------------------------------------

typedef struct mgw_a11y_node {
  int32_t node_id;
  int32_t parent_id;
  int32_t role_id;
  float x;
  float y;
  float w;
  float h;
  int32_t actions_mask;
  mgw_objc_id element;
} mgw_a11y_node_t;

static mgw_a11y_node_t *mgw_a11y_nodes = NULL;
static int32_t mgw_a11y_nodes_len = 0;
static int32_t mgw_a11y_nodes_cap = 0;
static int32_t mgw_a11y_root_id = -1;
static mgw_objc_id mgw_a11y_pool = NULL;

typedef struct mgw_a11y_action {
  int32_t target;
  int32_t kind;
} mgw_a11y_action_t;

static mgw_a11y_action_t *mgw_a11y_actions = NULL;
static int32_t mgw_a11y_actions_count = 0;
static int32_t mgw_a11y_actions_cap = 0;
static mgw_objc_id mgw_a11y_retained_tree = NULL;

static void *mgw_objc_dylib = NULL;
static void *mgw_cocoa = NULL;
static void *mgw_objc_get_class_sym = NULL;
static void *mgw_sel_register_name_sym = NULL;
static void *mgw_objc_msg_send_sym = NULL;
static void *mgw_objc_allocate_class_pair_sym = NULL;
static void *mgw_objc_register_class_pair_sym = NULL;
static void *mgw_class_add_method_sym = NULL;

static bool mgw_objc_init(void) {
  if (mgw_objc_get_class_sym && mgw_sel_register_name_sym && mgw_objc_msg_send_sym &&
      mgw_cocoa) {
    return true;
  }

#ifdef __APPLE__
  if (!mgw_cocoa) {
    mgw_cocoa = dlopen("/System/Library/Frameworks/Cocoa.framework/Cocoa", RTLD_LAZY | RTLD_LOCAL);
  }

  if (!mgw_objc_dylib) {
    mgw_objc_dylib = dlopen("/usr/lib/libobjc.A.dylib", RTLD_LAZY | RTLD_LOCAL);
    if (!mgw_objc_dylib) {
      mgw_objc_dylib = dlopen("libobjc.A.dylib", RTLD_LAZY | RTLD_LOCAL);
    }
  }
  if (!mgw_objc_dylib || !mgw_cocoa) {
    return false;
  }

  mgw_objc_get_class_sym = dlsym(mgw_objc_dylib, "objc_getClass");
  mgw_sel_register_name_sym = dlsym(mgw_objc_dylib, "sel_registerName");
  mgw_objc_msg_send_sym = dlsym(mgw_objc_dylib, "objc_msgSend");
  mgw_objc_allocate_class_pair_sym = dlsym(mgw_objc_dylib, "objc_allocateClassPair");
  mgw_objc_register_class_pair_sym = dlsym(mgw_objc_dylib, "objc_registerClassPair");
  mgw_class_add_method_sym = dlsym(mgw_objc_dylib, "class_addMethod");

  return (mgw_objc_get_class_sym && mgw_sel_register_name_sym && mgw_objc_msg_send_sym &&
          mgw_objc_allocate_class_pair_sym && mgw_objc_register_class_pair_sym &&
          mgw_class_add_method_sym);
#else
  return false;
#endif
}

static inline mgw_objc_class mgw_cls(const char *name) {
  return ((mgw_objc_class(*)(const char *))mgw_objc_get_class_sym)(name);
}

static inline mgw_objc_sel mgw_sel(const char *name) {
  return ((mgw_objc_sel(*)(const char *))mgw_sel_register_name_sym)(name);
}

static inline mgw_objc_id mgw_msg_id(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((mgw_objc_id(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline const char *mgw_msg_cstr(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((const char *(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline bool mgw_msg_bool_id(mgw_objc_id obj, mgw_objc_sel sel, mgw_objc_id arg0) {
  return ((bool (*)(mgw_objc_id, mgw_objc_sel, mgw_objc_id))mgw_objc_msg_send_sym)(obj, sel, arg0);
}

static inline void mgw_msg_void(mgw_objc_id obj, mgw_objc_sel sel) {
  ((void (*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline void mgw_msg_void_id(mgw_objc_id obj, mgw_objc_sel sel, mgw_objc_id arg0) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, mgw_objc_id))mgw_objc_msg_send_sym)(obj, sel, arg0);
}

static inline void mgw_msg_void_bool(mgw_objc_id obj, mgw_objc_sel sel, bool b) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, bool))mgw_objc_msg_send_sym)(obj, sel, b);
}

static inline void mgw_msg_void_i64(mgw_objc_id obj, mgw_objc_sel sel, int64_t v) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, int64_t))mgw_objc_msg_send_sym)(obj, sel, v);
}

static inline void mgw_msg_void_f64(mgw_objc_id obj, mgw_objc_sel sel, double v) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, double))mgw_objc_msg_send_sym)(obj, sel, v);
}

static inline mgw_rect mgw_msg_rect(mgw_objc_id obj, mgw_objc_sel sel) {
  // NOTE: This assumes the platform ABI can return `NSRect` (4x f64) via
  // `objc_msgSend` when cast to the appropriate function pointer type.
  // If this becomes unreliable, we should switch to an Objective-C stub or a
  // dedicated C helper that avoids struct returns.
  return ((mgw_rect(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline mgw_rect mgw_msg_rect_rect(mgw_objc_id obj, mgw_objc_sel sel, mgw_rect rect) {
  return ((mgw_rect(*)(mgw_objc_id, mgw_objc_sel, mgw_rect))mgw_objc_msg_send_sym)(obj, sel, rect);
}

static inline mgw_rect mgw_msg_rect_rect_id(mgw_objc_id obj, mgw_objc_sel sel, mgw_rect rect, mgw_objc_id arg0) {
  return ((mgw_rect(*)(mgw_objc_id, mgw_objc_sel, mgw_rect, mgw_objc_id))mgw_objc_msg_send_sym)(obj, sel, rect,
                                                                                                  arg0);
}

static inline void mgw_msg_void_rect(mgw_objc_id obj, mgw_objc_sel sel, mgw_rect rect) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, mgw_rect))mgw_objc_msg_send_sym)(obj, sel, rect);
}

static inline void mgw_msg_void_size(mgw_objc_id obj, mgw_objc_sel sel, mgw_size sz) {
  ((void (*)(mgw_objc_id, mgw_objc_sel, mgw_size))mgw_objc_msg_send_sym)(obj, sel, sz);
}

static inline int64_t mgw_msg_i64(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((int64_t(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline uint64_t mgw_msg_u64(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((uint64_t(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline mgw_point mgw_msg_point(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((mgw_point(*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline double mgw_msg_f64(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((double (*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static inline bool mgw_msg_bool(mgw_objc_id obj, mgw_objc_sel sel) {
  return ((bool (*)(mgw_objc_id, mgw_objc_sel))mgw_objc_msg_send_sym)(obj, sel);
}

static mgw_objc_id mgw_nsstring_utf8(const char *cstr) {
  mgw_objc_class nsstring = mgw_cls("NSString");
  if (!nsstring) {
    return NULL;
  }
  mgw_objc_sel s = mgw_sel("stringWithUTF8String:");
  return ((mgw_objc_id(*)(mgw_objc_id, mgw_objc_sel, const char *))mgw_objc_msg_send_sym)(
      (mgw_objc_id)nsstring, s, cstr);
}

static void mgw_a11y_actions_push(int32_t target, int32_t kind) {
  if (mgw_a11y_actions_count + 1 > mgw_a11y_actions_cap) {
    int32_t next = mgw_a11y_actions_cap ? mgw_a11y_actions_cap * 2 : 64;
    mgw_a11y_action_t *next_buf =
        (mgw_a11y_action_t *)realloc(mgw_a11y_actions, (size_t)next * sizeof(mgw_a11y_action_t));
    if (!next_buf) {
      return;
    }
    mgw_a11y_actions = next_buf;
    mgw_a11y_actions_cap = next;
  }
  mgw_a11y_actions[mgw_a11y_actions_count].target = target;
  mgw_a11y_actions[mgw_a11y_actions_count].kind = kind;
  mgw_a11y_actions_count += 1;
}

static mgw_objc_id mgw_a11y_element_class(void);

static bool mgw_a11y_perform_press(mgw_objc_id self, mgw_objc_sel _cmd) {
  (void)_cmd;
#ifdef __APPLE__
  if (!mgw_objc_init()) {
    return false;
  }
  mgw_objc_id ident = mgw_msg_id(self, mgw_sel("accessibilityIdentifier"));
  if (!ident) {
    return false;
  }
  const char *cstr = mgw_msg_cstr(ident, mgw_sel("UTF8String"));
  if (!cstr) {
    return false;
  }
  int32_t node_id = (int32_t)atoi(cstr);
  if (node_id == 0) {
    return false;
  }
  mgw_a11y_actions_push(node_id, 2 /* Default */);
  return true;
#else
  (void)self;
  return false;
#endif
}

static mgw_objc_id mgw_a11y_action_names(mgw_objc_id self, mgw_objc_sel _cmd) {
  (void)_cmd;
#ifdef __APPLE__
  if (!mgw_objc_init()) {
    return NULL;
  }
  mgw_objc_id role = mgw_msg_id(self, mgw_sel("accessibilityRole"));
  mgw_objc_id ax_button = mgw_nsstring_utf8("AXButton");
  bool is_button = false;
  if (role && ax_button) {
    is_button = mgw_msg_bool_id(role, mgw_sel("isEqualToString:" /* NSString */), ax_button);
  }
  mgw_objc_class nsarray_cls = mgw_cls("NSArray");
  if (!nsarray_cls) {
    return NULL;
  }
  if (!is_button) {
    return mgw_msg_id((mgw_objc_id)nsarray_cls, mgw_sel("array"));
  }
  mgw_objc_id press = mgw_nsstring_utf8("AXPress");
  if (!press) {
    return mgw_msg_id((mgw_objc_id)nsarray_cls, mgw_sel("array"));
  }
  mgw_objc_sel arr_sel = mgw_sel("arrayWithObject:");
  return ((mgw_objc_id(*)(mgw_objc_id, mgw_objc_sel, mgw_objc_id))mgw_objc_msg_send_sym)(
      (mgw_objc_id)nsarray_cls, arr_sel, press);
#else
  (void)self;
  return NULL;
#endif
}

static mgw_objc_id mgw_a11y_element_class(void) {
#ifndef __APPLE__
  return NULL;
#else
  static mgw_objc_id cached = NULL;
  if (cached) {
    return cached;
  }
  if (!mgw_objc_init()) {
    return NULL;
  }
  // Try to look up the class first (in case it was already registered).
  mgw_objc_id existing = (mgw_objc_id)mgw_cls("MGWA11yElement");
  if (existing) {
    cached = existing;
    return cached;
  }

  mgw_objc_class base = mgw_cls("NSAccessibilityElement");
  if (!base) {
    return NULL;
  }
  mgw_objc_class (*alloc_pair)(mgw_objc_class, const char *, size_t) =
      (mgw_objc_class(*)(mgw_objc_class, const char *, size_t))mgw_objc_allocate_class_pair_sym;
  void (*register_pair)(mgw_objc_class) =
      (void (*)(mgw_objc_class))mgw_objc_register_class_pair_sym;
  bool (*class_add_method)(mgw_objc_class, mgw_objc_sel, void *, const char *) =
      (bool (*)(mgw_objc_class, mgw_objc_sel, void *, const char *))mgw_class_add_method_sym;

  mgw_objc_class cls = alloc_pair(base, "MGWA11yElement", 0);
  if (!cls) {
    return NULL;
  }
  // BOOL accessibilityPerformPress()
  class_add_method(cls, mgw_sel("accessibilityPerformPress"), (void *)&mgw_a11y_perform_press, "B@:");
  // NSArray* accessibilityActionNames()
  class_add_method(cls, mgw_sel("accessibilityActionNames"), (void *)&mgw_a11y_action_names, "@@:");

  register_pair(cls);
  cached = (mgw_objc_id)cls;
  return cached;
#endif
}

static void mgw_app_ensure_started(void) {
  static bool started = false;
  if (started) {
    return;
  }
  started = true;

  mgw_objc_class nsapp_cls = mgw_cls("NSApplication");
  if (!nsapp_cls) {
    return;
  }
  mgw_objc_id app = mgw_msg_id((mgw_objc_id)nsapp_cls, mgw_sel("sharedApplication"));
  if (!app) {
    return;
  }

  // NSApplicationActivationPolicyRegular == 0
  mgw_msg_void_i64(app, mgw_sel("setActivationPolicy:"), 0);

  // Finish launching if not already.
  mgw_msg_void(app, mgw_sel("finishLaunching"));

  // Bring to foreground.
  mgw_msg_void_bool(app, mgw_sel("activateIgnoringOtherApps:"), true);
}

static mgw_objc_id mgw_autorelease_pool_new(void) {
  mgw_objc_class pool_cls = mgw_cls("NSAutoreleasePool");
  if (!pool_cls) {
    return NULL;
  }
  return mgw_msg_id((mgw_objc_id)pool_cls, mgw_sel("new"));
}

static void mgw_autorelease_pool_drain(mgw_objc_id pool) {
  if (!pool) {
    return;
  }
  mgw_msg_void(pool, mgw_sel("drain"));
}

static void mgw_window_sync_metrics(mgw_window_t *w) {
#ifdef __APPLE__
  if (!w || !w->ns_window || !w->content_view || !mgw_objc_init()) {
    return;
  }
  // Update logical size from the content view bounds.
  mgw_rect bounds = mgw_msg_rect(w->content_view, mgw_sel("bounds"));
  if (!(bounds.size.w > 0.0) || !(bounds.size.h > 0.0)) {
    return;
  }
  int32_t logical_w = (int32_t)(bounds.size.w + 0.5);
  int32_t logical_h = (int32_t)(bounds.size.h + 0.5);
  if (logical_w < 1) {
    logical_w = 1;
  }
  if (logical_h < 1) {
    logical_h = 1;
  }
  w->logical_width = logical_w;
  w->logical_height = logical_h;

  // Convert to physical pixels using backing scale factor.
  double scale = mgw_msg_f64(w->ns_window, mgw_sel("backingScaleFactor"));
  if (!(scale > 0.0)) {
    scale = 1.0;
  }
  int32_t physical_w = (int32_t)(bounds.size.w * scale + 0.5);
  int32_t physical_h = (int32_t)(bounds.size.h * scale + 0.5);
  if (physical_w < 1) {
    physical_w = 1;
  }
  if (physical_h < 1) {
    physical_h = 1;
  }
  w->width = physical_w;
  w->height = physical_h;

  // Keep CAMetalLayer in sync with backing scale and drawable size (in pixels).
  if (w->metal_layer) {
    mgw_msg_void_f64(w->metal_layer, mgw_sel("setContentsScale:"), scale);
    mgw_size drawable = {.w = bounds.size.w * scale, .h = bounds.size.h * scale};
    mgw_msg_void_size(w->metal_layer, mgw_sel("setDrawableSize:"), drawable);
  }
#else
  (void)w;
#endif
}

static void mgw_input_handle_key(mgw_window_t *w, int32_t down, uint32_t keycode) {
  if (!w) {
    return;
  }
  if (keycode >= 256u) {
    return;
  }
  uint8_t *kd = w->key_down;
  uint8_t *kp = w->key_pressed;
  uint8_t *kr = w->key_released;
  if (down) {
    if (!kd[keycode]) {
      kp[keycode] = 1;
    }
    kd[keycode] = 1;
  } else {
    if (kd[keycode]) {
      kr[keycode] = 1;
    }
    kd[keycode] = 0;
  }
}

static void mgw_input_handle_mouse_button(mgw_window_t *w, int32_t down, uint32_t btn) {
  if (!w) {
    return;
  }
  if (btn >= 8u) {
    return;
  }
  uint8_t *bd = w->mouse_down;
  uint8_t *bp = w->mouse_pressed;
  uint8_t *br = w->mouse_released;
  if (down) {
    if (!bd[btn]) {
      bp[btn] = 1;
    }
    bd[btn] = 1;
  } else {
    if (bd[btn]) {
      br[btn] = 1;
    }
    bd[btn] = 0;
  }
}

static void mgw_input_update_mouse_location(mgw_window_t *w, mgw_objc_id ev) {
#ifdef __APPLE__
  if (!w || !ev || !mgw_objc_init()) {
    return;
  }
  mgw_point loc = mgw_msg_point(ev, mgw_sel("locationInWindow"));
  // Convert to top-left origin logical coordinates.
  float x = (float)loc.x;
  float y = (float)((double)w->logical_height - loc.y);
  w->mouse_x = x;
  w->mouse_y = y;
  // Best-effort cursor presence.
  w->has_cursor = 1;
#else
  (void)w;
  (void)ev;
#endif
}

static void mgw_input_handle_event(mgw_window_t *w, mgw_objc_id ev) {
#ifdef __APPLE__
  if (!w || !ev || !mgw_objc_init()) {
    return;
  }
  // NSEventType values (stable across modern macOS).
  // https://developer.apple.com/documentation/appkit/nseventtype
  const int64_t ty = mgw_msg_i64(ev, mgw_sel("type"));
  switch (ty) {
  case 10: { // KeyDown
    uint32_t keycode = (uint32_t)mgw_msg_u64(ev, mgw_sel("keyCode"));
    mgw_input_handle_key(w, 1, keycode);
    break;
  }
  case 11: { // KeyUp
    uint32_t keycode = (uint32_t)mgw_msg_u64(ev, mgw_sel("keyCode"));
    mgw_input_handle_key(w, 0, keycode);
    break;
  }
  case 1: // LeftMouseDown
    mgw_input_handle_mouse_button(w, 1, 0);
    mgw_input_update_mouse_location(w, ev);
    break;
  case 2: // LeftMouseUp
    mgw_input_handle_mouse_button(w, 0, 0);
    mgw_input_update_mouse_location(w, ev);
    break;
  case 3: // RightMouseDown
    mgw_input_handle_mouse_button(w, 1, 1);
    mgw_input_update_mouse_location(w, ev);
    break;
  case 4: // RightMouseUp
    mgw_input_handle_mouse_button(w, 0, 1);
    mgw_input_update_mouse_location(w, ev);
    break;
  case 25: { // OtherMouseDown
    uint32_t btn = (uint32_t)mgw_msg_u64(ev, mgw_sel("buttonNumber"));
    uint32_t mapped = btn > 7u ? 7u : btn;
    mgw_input_handle_mouse_button(w, 1, mapped);
    mgw_input_update_mouse_location(w, ev);
    break;
  }
  case 26: { // OtherMouseUp
    uint32_t btn = (uint32_t)mgw_msg_u64(ev, mgw_sel("buttonNumber"));
    uint32_t mapped = btn > 7u ? 7u : btn;
    mgw_input_handle_mouse_button(w, 0, mapped);
    mgw_input_update_mouse_location(w, ev);
    break;
  }
  case 5:  // MouseMoved
  case 6:  // LeftMouseDragged
  case 7:  // RightMouseDragged
  case 27: // OtherMouseDragged
    mgw_input_update_mouse_location(w, ev);
    break;
  case 8: // MouseEntered
    w->has_cursor = 1;
    break;
  case 9: // MouseExited
    w->has_cursor = 0;
    break;
  case 22: { // ScrollWheel
    // `scrollingDelta*` are in points; we keep them as logical units.
    double dx = mgw_msg_f64(ev, mgw_sel("scrollingDeltaX"));
    double dy = mgw_msg_f64(ev, mgw_sel("scrollingDeltaY"));
    w->wheel_x += (float)dx;
    w->wheel_y += (float)dy;
    mgw_input_update_mouse_location(w, ev);
    break;
  }
  default:
    break;
  }
#else
  (void)w;
  (void)ev;
#endif
}

MOONBIT_FFI_EXPORT void *mgw_window_create(int32_t width, int32_t height, moonbit_bytes_t title) {
#ifndef __APPLE__
  (void)width;
  (void)height;
  (void)title;
  return NULL;
#else
  if (!mgw_objc_init()) {
    return NULL;
  }
  mgw_app_ensure_started();

  mgw_objc_id pool = mgw_autorelease_pool_new();

  mgw_objc_class nswindow_cls = mgw_cls("NSWindow");
  if (!nswindow_cls) {
    mgw_autorelease_pool_drain(pool);
    return NULL;
  }

  mgw_objc_id win_alloc = mgw_msg_id((mgw_objc_id)nswindow_cls, mgw_sel("alloc"));
  if (!win_alloc) {
    mgw_autorelease_pool_drain(pool);
    return NULL;
  }

  mgw_rect rect = {.origin = {.x = 0.0, .y = 0.0}, .size = {.w = (double)width, .h = (double)height}};
  // NSWindowStyleMaskTitled | Closable | Miniaturizable | Resizable.
  uint64_t style = 1ull | 2ull | 4ull | 8ull;
  // NSBackingStoreBuffered == 2
  uint64_t backing = 2ull;
  bool defer = false;

  mgw_objc_sel init_sel = mgw_sel("initWithContentRect:styleMask:backing:defer:");
  mgw_objc_id win = ((mgw_objc_id(*)(mgw_objc_id, mgw_objc_sel, mgw_rect, uint64_t, uint64_t, bool))
                        mgw_objc_msg_send_sym)(win_alloc, init_sel, rect, style, backing, defer);
  if (!win) {
    mgw_autorelease_pool_drain(pool);
    return NULL;
  }

  // Title.
  if (title) {
    mgw_objc_id ns_title = mgw_nsstring_utf8((const char *)title);
    if (ns_title) {
      mgw_msg_void_id(win, mgw_sel("setTitle:"), ns_title);
    }
  }

  mgw_msg_void_bool(win, mgw_sel("setReleasedWhenClosed:"), false);
  // Ensure we receive mouse move events.
  mgw_msg_void_bool(win, mgw_sel("setAcceptsMouseMovedEvents:"), true);
  mgw_msg_void(win, mgw_sel("center"));
  mgw_msg_void_id(win, mgw_sel("makeKeyAndOrderFront:"), NULL);

  mgw_objc_id content_view = mgw_msg_id(win, mgw_sel("contentView"));

  mgw_window_t *out = (mgw_window_t *)calloc(1, sizeof(mgw_window_t));
  out->ns_window = win;
  out->content_view = content_view;
  out->metal_layer = NULL;
  // Initialize with caller-provided logical size; sync will overwrite with actual values.
  out->width = width;
  out->height = height;
  out->logical_width = width;
  out->logical_height = height;
  out->should_close = 0;
  out->has_cursor = 0;
  out->mouse_x = 0.0f;
  out->mouse_y = 0.0f;
  out->wheel_x = 0.0f;
  out->wheel_y = 0.0f;
  memset(out->key_down, 0, sizeof(out->key_down));
  memset(out->key_pressed, 0, sizeof(out->key_pressed));
  memset(out->key_released, 0, sizeof(out->key_released));
  memset(out->mouse_down, 0, sizeof(out->mouse_down));
  memset(out->mouse_pressed, 0, sizeof(out->mouse_pressed));
  memset(out->mouse_released, 0, sizeof(out->mouse_released));

  // Sync actual content view size (and later Metal layer) to avoid drift.
  mgw_window_sync_metrics(out);

  mgw_autorelease_pool_drain(pool);
  return (void *)out;
#endif
}

MOONBIT_FFI_EXPORT int32_t mgw_window_is_null(void *win) { return win == NULL; }

MOONBIT_FFI_EXPORT void mgw_window_destroy(void *win) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  mgw_objc_id pool = mgw_autorelease_pool_new();
  if (mgw_a11y_retained_tree) {
    mgw_msg_void(mgw_a11y_retained_tree, mgw_sel("release"));
    mgw_a11y_retained_tree = NULL;
  }
  if (mgw_a11y_pool) {
    mgw_autorelease_pool_drain(mgw_a11y_pool);
    mgw_a11y_pool = NULL;
  }
  if (w->ns_window) {
    mgw_msg_void(w->ns_window, mgw_sel("close"));
    mgw_msg_void(w->ns_window, mgw_sel("release"));
    w->ns_window = NULL;
  }
  free(w);
  mgw_autorelease_pool_drain(pool);
#else
  (void)win;
#endif
}

static mgw_objc_id mgw_date_distant_past(void) {
  mgw_objc_class date_cls = mgw_cls("NSDate");
  if (!date_cls) {
    return NULL;
  }
  return mgw_msg_id((mgw_objc_id)date_cls, mgw_sel("distantPast"));
}

MOONBIT_FFI_EXPORT void mgw_window_poll_events(void *win) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->ns_window) {
    w->should_close = 1;
    return;
  }

  mgw_app_ensure_started();

  mgw_objc_id pool = mgw_autorelease_pool_new();

  mgw_objc_id app = mgw_msg_id((mgw_objc_id)mgw_cls("NSApplication"), mgw_sel("sharedApplication"));
  if (app) {
    mgw_objc_id until = mgw_date_distant_past();
    mgw_objc_id mode = mgw_nsstring_utf8("kCFRunLoopDefaultMode");

    mgw_objc_sel next_event_sel =
        mgw_sel("nextEventMatchingMask:untilDate:inMode:dequeue:");
    mgw_objc_sel send_event_sel = mgw_sel("sendEvent:");
    mgw_objc_sel update_sel = mgw_sel("updateWindows");

    // NSEventMaskAny is effectively all bits.
    uint64_t mask_any = UINT64_MAX;
    while (true) {
      mgw_objc_id ev = ((mgw_objc_id(*)(mgw_objc_id, mgw_objc_sel, uint64_t, mgw_objc_id,
                                       mgw_objc_id, bool))mgw_objc_msg_send_sym)(
          app, next_event_sel, mask_any, until, mode, true);
      if (!ev) {
        break;
      }
      mgw_input_handle_event(w, ev);
      ((void (*)(mgw_objc_id, mgw_objc_sel, mgw_objc_id))mgw_objc_msg_send_sym)(app, send_event_sel, ev);
    }
    mgw_msg_void(app, update_sel);
  }

  mgw_window_sync_metrics(w);

  // Mark closed when the window is no longer visible.
  w->should_close = mgw_msg_bool(w->ns_window, mgw_sel("isVisible")) ? 0 : 1;

  mgw_autorelease_pool_drain(pool);
#else
  (void)win;
#endif
}

MOONBIT_FFI_EXPORT int32_t mgw_window_width(void *win) {
  if (!win) {
    return 0;
  }
  return ((mgw_window_t *)win)->width;
}

MOONBIT_FFI_EXPORT int32_t mgw_window_height(void *win) {
  if (!win) {
    return 0;
  }
  return ((mgw_window_t *)win)->height;
}

MOONBIT_FFI_EXPORT float mgw_window_scale_factor(void *win) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return 1.0f;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->ns_window) {
    return 1.0f;
  }
  return (float)mgw_msg_f64(w->ns_window, mgw_sel("backingScaleFactor"));
#else
  (void)win;
  return 1.0f;
#endif
}

MOONBIT_FFI_EXPORT int32_t mgw_window_should_close(void *win) {
  if (!win) {
    return 1;
  }
  return ((mgw_window_t *)win)->should_close != 0;
}

MOONBIT_FFI_EXPORT void mgw_window_request_close(void *win) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->ns_window) {
    w->should_close = 1;
    return;
  }
  mgw_objc_id pool = mgw_autorelease_pool_new();
  mgw_msg_void_id(w->ns_window, mgw_sel("performClose:"), NULL);
  w->should_close = 1;
  mgw_autorelease_pool_drain(pool);
#else
  (void)win;
#endif
}

MOONBIT_FFI_EXPORT void mgw_window_attach_metal_layer(void *win, void *layer) {
#ifdef __APPLE__
  if (!win || !layer || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->content_view) {
    return;
  }
  mgw_objc_id pool = mgw_autorelease_pool_new();

  // [contentView setWantsLayer:YES]; [contentView setLayer:layer];
  mgw_msg_void_bool(w->content_view, mgw_sel("setWantsLayer:"), true);
  mgw_msg_void_id(w->content_view, mgw_sel("setLayer:"), (mgw_objc_id)layer);
  w->metal_layer = (mgw_objc_id)layer;
  mgw_window_sync_metrics(w);

  mgw_autorelease_pool_drain(pool);
#else
  (void)win;
  (void)layer;
#endif
}

// -----------------------------------------------------------------------------
// Input query API (stored on mgw_window_t)
// -----------------------------------------------------------------------------

MOONBIT_FFI_EXPORT void mgw_input_finish_frame(void *win) {
  if (!win) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  memset(w->key_pressed, 0, sizeof(w->key_pressed));
  memset(w->key_released, 0, sizeof(w->key_released));
  memset(w->mouse_pressed, 0, sizeof(w->mouse_pressed));
  memset(w->mouse_released, 0, sizeof(w->mouse_released));
  w->wheel_x = 0.0f;
  w->wheel_y = 0.0f;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_has_cursor(void *win) {
  if (!win) {
    return 0;
  }
  return ((mgw_window_t *)win)->has_cursor != 0;
}

MOONBIT_FFI_EXPORT float mgw_input_mouse_x(void *win) {
  if (!win) {
    return 0.0f;
  }
  return ((mgw_window_t *)win)->mouse_x;
}

MOONBIT_FFI_EXPORT float mgw_input_mouse_y(void *win) {
  if (!win) {
    return 0.0f;
  }
  return ((mgw_window_t *)win)->mouse_y;
}

MOONBIT_FFI_EXPORT float mgw_input_wheel_x(void *win) {
  if (!win) {
    return 0.0f;
  }
  return ((mgw_window_t *)win)->wheel_x;
}

MOONBIT_FFI_EXPORT float mgw_input_wheel_y(void *win) {
  if (!win) {
    return 0.0f;
  }
  return ((mgw_window_t *)win)->wheel_y;
}

static inline int32_t mgw_clamp_index_i32(int32_t v, int32_t max_exclusive) {
  if (v < 0) {
    return -1;
  }
  if (v >= max_exclusive) {
    return -1;
  }
  return v;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_key_down(void *win, int32_t code) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(code, 256);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->key_down[idx] != 0;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_key_just_pressed(void *win, int32_t code) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(code, 256);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->key_pressed[idx] != 0;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_key_just_released(void *win, int32_t code) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(code, 256);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->key_released[idx] != 0;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_mouse_button_down(void *win, int32_t button) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(button, 8);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->mouse_down[idx] != 0;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_mouse_button_just_pressed(void *win, int32_t button) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(button, 8);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->mouse_pressed[idx] != 0;
}

MOONBIT_FFI_EXPORT int32_t mgw_input_is_mouse_button_just_released(void *win, int32_t button) {
  if (!win) {
    return 0;
  }
  int32_t idx = mgw_clamp_index_i32(button, 8);
  if (idx < 0) {
    return 0;
  }
  return ((mgw_window_t *)win)->mouse_released[idx] != 0;
}

MOONBIT_FFI_EXPORT void mgw_a11y_begin_update(void *win, int32_t root_id) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->ns_window || !w->content_view) {
    return;
  }
  mgw_app_ensure_started();
  mgw_a11y_root_id = root_id;
  mgw_a11y_nodes_len = 0;
  if (mgw_a11y_pool) {
    mgw_autorelease_pool_drain(mgw_a11y_pool);
    mgw_a11y_pool = NULL;
  }
  mgw_a11y_pool = mgw_autorelease_pool_new();
#else
  (void)win;
  (void)root_id;
#endif
}

static mgw_a11y_node_t *mgw_a11y_node_find(int32_t node_id) {
  for (int32_t i = 0; i < mgw_a11y_nodes_len; i += 1) {
    if (mgw_a11y_nodes[i].node_id == node_id) {
      return &mgw_a11y_nodes[i];
    }
  }
  return NULL;
}

MOONBIT_FFI_EXPORT void mgw_a11y_push_node(void *win, int32_t node_id, int32_t parent_id, int32_t role_id,
                                          float x, float y, float width, float height, moonbit_bytes_t name,
                                          int32_t actions_mask) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->ns_window || !w->content_view) {
    return;
  }
  if (mgw_a11y_nodes_len + 1 > mgw_a11y_nodes_cap) {
    int32_t next = mgw_a11y_nodes_cap ? mgw_a11y_nodes_cap * 2 : 256;
    mgw_a11y_node_t *next_buf =
        (mgw_a11y_node_t *)realloc(mgw_a11y_nodes, (size_t)next * sizeof(mgw_a11y_node_t));
    if (!next_buf) {
      return;
    }
    mgw_a11y_nodes = next_buf;
    mgw_a11y_nodes_cap = next;
  }

  mgw_objc_id el_cls = mgw_a11y_element_class();
  if (!el_cls) {
    return;
  }
  mgw_objc_id element = mgw_msg_id(el_cls, mgw_sel("new"));
  if (!element) {
    return;
  }
  // Put the element under autorelease; the retained tree keeps it alive.
  element = mgw_msg_id(element, mgw_sel("autorelease"));

  // Identifier = node id, used for action callbacks.
  char id_buf[64];
  snprintf(id_buf, sizeof(id_buf), "%d", (int)node_id);
  mgw_objc_id ident = mgw_nsstring_utf8(id_buf);
  if (ident) {
    mgw_msg_void_id(element, mgw_sel("setAccessibilityIdentifier:"), ident);
  }

  // Role.
  const char *role_str = "AXGroup";
  if (role_id == 3) {
    role_str = "AXButton";
  } else if (role_id == 4) {
    role_str = "AXStaticText";
  } else if (role_id == 1) {
    role_str = "AXWindow";
  }
  mgw_objc_id ns_role = mgw_nsstring_utf8(role_str);
  if (ns_role) {
    mgw_msg_void_id(element, mgw_sel("setAccessibilityRole:"), ns_role);
  }

  // Label.
  if (name && ((const char *)name)[0] != 0) {
    mgw_objc_id label = mgw_nsstring_utf8((const char *)name);
    if (label) {
      mgw_msg_void_id(element, mgw_sel("setAccessibilityLabel:"), label);
    }
  }

  // Frame in parent space (content view coordinates).
  //
  // We intentionally avoid converting to screen coordinates here to reduce
  // reliance on struct-return objc_msgSend ABIs.
  mgw_rect bounds = mgw_msg_rect(w->content_view, mgw_sel("bounds"));
  bool flipped = mgw_msg_bool(w->content_view, mgw_sel("isFlipped"));
  double view_x = (double)x;
  double view_y = flipped ? (double)y : (bounds.size.h - (double)y - (double)height);
  mgw_rect view_rect = {.origin = {.x = view_x, .y = view_y}, .size = {.w = (double)width, .h = (double)height}};
  mgw_msg_void_rect(element, mgw_sel("setAccessibilityFrameInParentSpace:"), view_rect);

  mgw_a11y_node_t *slot = &mgw_a11y_nodes[mgw_a11y_nodes_len];
  slot->node_id = node_id;
  slot->parent_id = parent_id;
  slot->role_id = role_id;
  slot->x = x;
  slot->y = y;
  slot->w = width;
  slot->h = height;
  slot->actions_mask = actions_mask;
  slot->element = element;
  mgw_a11y_nodes_len += 1;
#else
  (void)win;
  (void)node_id;
  (void)parent_id;
  (void)role_id;
  (void)x;
  (void)y;
  (void)width;
  (void)height;
  (void)name;
  (void)actions_mask;
#endif
}

MOONBIT_FFI_EXPORT void mgw_a11y_end_update(void *win) {
#ifdef __APPLE__
  if (!win || !mgw_objc_init()) {
    return;
  }
  mgw_window_t *w = (mgw_window_t *)win;
  if (!w->content_view) {
    return;
  }
  mgw_objc_class mut_array_cls = mgw_cls("NSMutableArray");
  if (!mut_array_cls) {
    return;
  }
  mgw_objc_id roots = mgw_msg_id((mgw_objc_id)mut_array_cls, mgw_sel("array"));

  // Create a child list per node.
  mgw_objc_id *children_lists = NULL;
  if (mgw_a11y_nodes_len > 0) {
    children_lists = (mgw_objc_id *)calloc((size_t)mgw_a11y_nodes_len, sizeof(mgw_objc_id));
  }
  for (int32_t i = 0; i < mgw_a11y_nodes_len; i += 1) {
    children_lists[i] = mgw_msg_id((mgw_objc_id)mut_array_cls, mgw_sel("array"));
  }

  for (int32_t i = 0; i < mgw_a11y_nodes_len; i += 1) {
    mgw_a11y_node_t *node = &mgw_a11y_nodes[i];
    mgw_objc_id parent_el = NULL;
    if (node->parent_id != mgw_a11y_root_id) {
      mgw_a11y_node_t *parent = mgw_a11y_node_find(node->parent_id);
      if (parent) {
        parent_el = parent->element;
        // Append to parent's child list.
        for (int32_t p = 0; p < mgw_a11y_nodes_len; p += 1) {
          if (mgw_a11y_nodes[p].node_id == node->parent_id) {
            mgw_msg_void_id(children_lists[p], mgw_sel("addObject:"), node->element);
            break;
          }
        }
      }
    }
    if (!parent_el) {
      mgw_msg_void_id(roots, mgw_sel("addObject:"), node->element);
      parent_el = w->content_view;
    }
    mgw_msg_void_id(node->element, mgw_sel("setAccessibilityParent:"), parent_el);
    mgw_msg_void_id(node->element, mgw_sel("setAccessibilityWindow:"), w->ns_window);
  }

  for (int32_t i = 0; i < mgw_a11y_nodes_len; i += 1) {
    mgw_a11y_node_t *node = &mgw_a11y_nodes[i];
    mgw_msg_void_id(node->element, mgw_sel("setAccessibilityChildren:"), children_lists[i]);
  }

  mgw_msg_void_id(w->content_view, mgw_sel("setAccessibilityChildren:"), roots);

  // Retain the tree so nodes stay alive after draining the autorelease pool.
  if (mgw_a11y_retained_tree) {
    mgw_msg_void(mgw_a11y_retained_tree, mgw_sel("release"));
    mgw_a11y_retained_tree = NULL;
  }
  if (roots) {
    mgw_a11y_retained_tree = mgw_msg_id(roots, mgw_sel("retain"));
  }

  if (children_lists) {
    free(children_lists);
  }
  if (mgw_a11y_pool) {
    mgw_autorelease_pool_drain(mgw_a11y_pool);
    mgw_a11y_pool = NULL;
  }
#else
  (void)win;
#endif
}

MOONBIT_FFI_EXPORT int32_t mgw_a11y_actions_len(void) { return mgw_a11y_actions_count; }

MOONBIT_FFI_EXPORT int32_t mgw_a11y_action_target(int32_t index) {
  if (index < 0 || index >= mgw_a11y_actions_count) {
    return 0;
  }
  return mgw_a11y_actions[index].target;
}

MOONBIT_FFI_EXPORT int32_t mgw_a11y_action_kind(int32_t index) {
  if (index < 0 || index >= mgw_a11y_actions_count) {
    return 0;
  }
  return mgw_a11y_actions[index].kind;
}

MOONBIT_FFI_EXPORT void mgw_a11y_actions_clear(void) { mgw_a11y_actions_count = 0; }
