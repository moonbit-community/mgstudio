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
#include <stdlib.h>

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
  int32_t width;
  int32_t height;
  int32_t should_close;
} mgw_window_t;

static void *mgw_objc_dylib = NULL;
static void *mgw_cocoa = NULL;
static void *mgw_objc_get_class_sym = NULL;
static void *mgw_sel_register_name_sym = NULL;
static void *mgw_objc_msg_send_sym = NULL;

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

  return (mgw_objc_get_class_sym && mgw_sel_register_name_sym && mgw_objc_msg_send_sym);
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
  // NSWindowStyleMaskTitled | Closable | Miniaturizable (no resize for bring-up).
  uint64_t style = 1ull | 2ull | 4ull;
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
  mgw_msg_void(win, mgw_sel("center"));
  mgw_msg_void_id(win, mgw_sel("makeKeyAndOrderFront:"), NULL);

  mgw_objc_id content_view = mgw_msg_id(win, mgw_sel("contentView"));

  mgw_window_t *out = (mgw_window_t *)calloc(1, sizeof(mgw_window_t));
  out->ns_window = win;
  out->content_view = content_view;
  out->width = width;
  out->height = height;
  out->should_close = 0;

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
      ((void (*)(mgw_objc_id, mgw_objc_sel, mgw_objc_id))mgw_objc_msg_send_sym)(app, send_event_sel, ev);
    }
    mgw_msg_void(app, update_sel);
  }

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

  mgw_autorelease_pool_drain(pool);
#else
  (void)win;
  (void)layer;
#endif
}
