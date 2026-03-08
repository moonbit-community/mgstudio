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

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if defined(__APPLE__)
#include <objc/message.h>
#include <objc/runtime.h>
#endif

typedef struct mgw_window {
  int id;
  int width;
  int height;
  float scale_factor;
  int focused;
  int should_close;
  int x;
  int y;
#if defined(__APPLE__)
  void *window;
  void *content_view;
#endif
} mgw_window_t;

static mgw_window_t **g_windows = NULL;
static size_t g_windows_len = 0;
static size_t g_windows_cap = 0;
static int g_next_id = 1;

#define MGW_KEY_COUNT 62
#define MGW_MOUSE_BUTTON_COUNT 3
#define MGW_MAX_TEXT_EVENTS 256
#define MGW_MAX_TOUCH_EVENTS 64
#define MGW_MAX_DRAG_EVENTS 64

typedef struct mgw_touch_event {
  int id;
  int phase;
  float x;
  float y;
} mgw_touch_event_t;

typedef struct mgw_drag_event {
  int kind;
  char *text;
} mgw_drag_event_t;

static bool g_key_down[MGW_KEY_COUNT];
static bool g_key_just_pressed[MGW_KEY_COUNT];
static bool g_key_just_released[MGW_KEY_COUNT];
static bool g_key_repeated[MGW_KEY_COUNT];

static bool g_mouse_down[MGW_MOUSE_BUTTON_COUNT];
static bool g_mouse_just_pressed[MGW_MOUSE_BUTTON_COUNT];
static bool g_mouse_just_released[MGW_MOUSE_BUTTON_COUNT];

static bool g_has_cursor = false;
static float g_mouse_x = 0.0f;
static float g_mouse_y = 0.0f;
static float g_wheel_x = 0.0f;
static float g_wheel_y = 0.0f;

static char *g_text_events[MGW_MAX_TEXT_EVENTS];
static int g_text_event_count = 0;

static mgw_touch_event_t g_touch_events[MGW_MAX_TOUCH_EVENTS];
static int g_touch_event_count = 0;

static mgw_drag_event_t g_drag_events[MGW_MAX_DRAG_EVENTS];
static int g_drag_event_count = 0;

static int mgw_clamp_size(int value) {
  return value <= 0 ? 1 : value;
}

static char *mgw_dup_cstr(const char *src) {
  if (!src) {
    char *out = (char *)malloc(1);
    if (out) {
      out[0] = '\0';
    }
    return out;
  }
  size_t n = strlen(src);
  char *out = (char *)malloc(n + 1);
  if (!out) {
    return NULL;
  }
  memcpy(out, src, n);
  out[n] = '\0';
  return out;
}

static void mgw_clear_text_events(void) {
  for (int i = 0; i < g_text_event_count; ++i) {
    if (g_text_events[i]) {
      free(g_text_events[i]);
      g_text_events[i] = NULL;
    }
  }
  g_text_event_count = 0;
}

static void mgw_clear_drag_events(void) {
  for (int i = 0; i < g_drag_event_count; ++i) {
    if (g_drag_events[i].text) {
      free(g_drag_events[i].text);
      g_drag_events[i].text = NULL;
    }
    g_drag_events[i].kind = 0;
  }
  g_drag_event_count = 0;
}

static mgw_window_t *mgw_find_window(int id) {
  for (size_t i = 0; i < g_windows_len; ++i) {
    if (g_windows[i] && g_windows[i]->id == id) {
      return g_windows[i];
    }
  }
  return NULL;
}

static void mgw_push_window(mgw_window_t *window) {
  if (g_windows_len + 1 > g_windows_cap) {
    size_t next_cap = g_windows_cap == 0 ? 8 : g_windows_cap * 2;
    mgw_window_t **next = (mgw_window_t **)realloc(
      g_windows, next_cap * sizeof(mgw_window_t *));
    if (!next) {
      return;
    }
    g_windows = next;
    g_windows_cap = next_cap;
  }
  g_windows[g_windows_len++] = window;
}

static char *mgw_copy_utf8(const uint8_t *bytes, uint64_t len) {
  if (!bytes) {
    char *fallback = (char *)malloc(1);
    if (fallback) {
      fallback[0] = '\0';
    }
    return fallback;
  }
  size_t n = (size_t)len;
  char *out = (char *)malloc(n + 1);
  if (!out) {
    return NULL;
  }
  if (n > 0) {
    memcpy(out, bytes, n);
  }
  out[n] = '\0';
  return out;
}

#if defined(__APPLE__)
typedef signed char mgw_bool_t;
typedef double mgw_cgfloat_t;
typedef unsigned long mgw_nsuint_t;

typedef struct {
  mgw_cgfloat_t x;
  mgw_cgfloat_t y;
} mgw_point_t;

typedef struct {
  mgw_cgfloat_t width;
  mgw_cgfloat_t height;
} mgw_size_t;

typedef struct {
  mgw_point_t origin;
  mgw_size_t size;
} mgw_rect_t;

#ifndef YES
#define YES ((mgw_bool_t)1)
#endif
#ifndef NO
#define NO ((mgw_bool_t)0)
#endif

static bool g_bootstrap_done = false;
static bool g_bootstrap_ok = false;
static id g_ns_app = nil;

static SEL mgw_sel(const char *name) {
  return sel_registerName(name);
}

static id mgw_msg_id(id obj, const char *sel_name) {
  return ((id(*)(id, SEL))objc_msgSend)(obj, mgw_sel(sel_name));
}

static void mgw_msg_void(id obj, const char *sel_name) {
  ((void(*)(id, SEL))objc_msgSend)(obj, mgw_sel(sel_name));
}

static double mgw_scale_to_points(int physical, float scale_factor) {
  float safe_scale = scale_factor <= 0.0f ? 1.0f : scale_factor;
  return (double)physical / (double)safe_scale;
}

static id mgw_make_nsstring(const char *utf8) {
  if (!utf8) {
    utf8 = "";
  }
  Class ns_string_class = objc_getClass("NSString");
  if (!ns_string_class) {
    return nil;
  }
  return ((id(*)(id, SEL, const char *))objc_msgSend)(
    (id)ns_string_class, mgw_sel("stringWithUTF8String:"), utf8);
}

static bool mgw_bootstrap_app(void) {
  if (g_bootstrap_done) {
    return g_bootstrap_ok;
  }
  g_bootstrap_done = true;

  Class app_class = objc_getClass("NSApplication");
  if (!app_class) {
    return false;
  }

  id app = ((id(*)(id, SEL))objc_msgSend)(
    (id)app_class, mgw_sel("sharedApplication"));
  if (!app) {
    return false;
  }

  ((void(*)(id, SEL, long))objc_msgSend)(
    app, mgw_sel("setActivationPolicy:"), 0L);
  mgw_msg_void(app, "finishLaunching");
  ((void(*)(id, SEL, mgw_bool_t))objc_msgSend)(
    app, mgw_sel("activateIgnoringOtherApps:"), YES);

  g_ns_app = app;
  g_bootstrap_ok = true;
  return true;
}

static void mgw_update_window_state(mgw_window_t *window) {
  if (!window || !window->window) {
    return;
  }

  mgw_bool_t visible = ((mgw_bool_t(*)(id, SEL))objc_msgSend)(
    (id)window->window, mgw_sel("isVisible"));
  if (!visible) {
    window->should_close = 1;
  }

  window->scale_factor = (float)((double(*)(id, SEL))objc_msgSend)(
    (id)window->window, mgw_sel("backingScaleFactor"));
  {
    mgw_bool_t is_key_window = ((mgw_bool_t(*)(id, SEL))objc_msgSend)(
      (id)window->window, mgw_sel("isKeyWindow"));
    mgw_bool_t is_main_window = ((mgw_bool_t(*)(id, SEL))objc_msgSend)(
      (id)window->window, mgw_sel("isMainWindow"));
    window->focused = (is_key_window || is_main_window) ? 1 : 0;
  }

  id content_view = window->content_view
    ? (id)window->content_view
    : mgw_msg_id((id)window->window, "contentView");
  if (content_view) {
    window->content_view = (void *)content_view;
    mgw_rect_t bounds = ((mgw_rect_t(*)(id, SEL))objc_msgSend)(
      content_view, mgw_sel("bounds"));
    int backing_width = (int)(bounds.size.width * window->scale_factor + 0.5f);
    int backing_height = (int)(bounds.size.height * window->scale_factor + 0.5f);
    window->width = mgw_clamp_size(backing_width);
    window->height = mgw_clamp_size(backing_height);
  }

  mgw_rect_t frame = ((mgw_rect_t(*)(id, SEL))objc_msgSend)(
    (id)window->window, mgw_sel("frame"));
  window->x = (int)frame.origin.x;
  window->y = (int)frame.origin.y;
}

static int mgw_mouse_button_from_type(id event, mgw_nsuint_t type) {
  if (type == 1UL || type == 2UL) { // left down/up
    return 0;
  }
  if (type == 3UL || type == 4UL) { // right down/up
    return 1;
  }
  if (type == 25UL || type == 26UL) { // other mouse down/up
    mgw_nsuint_t number = ((mgw_nsuint_t(*)(id, SEL))objc_msgSend)(
      event, mgw_sel("buttonNumber"));
    if (number == 2UL) {
      return 2;
    }
  }
  return -1;
}

static int mgw_key_id_from_mac(mgw_nsuint_t key_code) {
  switch (key_code) {
  case 0: return 0;   // KeyA
  case 11: return 1;  // KeyB
  case 8: return 2;   // KeyC
  case 2: return 3;   // KeyD
  case 14: return 4;  // KeyE
  case 3: return 5;   // KeyF
  case 5: return 6;   // KeyG
  case 4: return 7;   // KeyH
  case 34: return 8;  // KeyI
  case 38: return 9;  // KeyJ
  case 40: return 10; // KeyK
  case 37: return 11; // KeyL
  case 46: return 12; // KeyM
  case 45: return 13; // KeyN
  case 31: return 14; // KeyO
  case 35: return 15; // KeyP
  case 12: return 16; // KeyQ
  case 15: return 17; // KeyR
  case 1: return 18;  // KeyS
  case 17: return 19; // KeyT
  case 32: return 20; // KeyU
  case 9: return 21;  // KeyV
  case 13: return 22; // KeyW
  case 7: return 23;  // KeyX
  case 16: return 24; // KeyY
  case 6: return 25;  // KeyZ
  case 18: return 26; // Digit1
  case 19: return 27; // Digit2
  case 20: return 28; // Digit3
  case 21: return 29; // Digit4
  case 23: return 30; // Digit5
  case 22: return 31; // Digit6
  case 26: return 32; // Digit7
  case 28: return 33; // Digit8
  case 25: return 34; // Digit9
  case 29: return 35; // Digit0
  case 48: return 36; // Tab
  case 36: return 37; // Enter
  case 51: return 38; // Backspace
  case 56: return 39; // ShiftLeft
  case 60: return 40; // ShiftRight
  case 59: return 41; // ControlLeft
  case 62: return 42; // ControlRight
  case 126: return 43; // ArrowUp
  case 125: return 44; // ArrowDown
  case 123: return 45; // ArrowLeft
  case 124: return 46; // ArrowRight
  case 116: return 47; // PageUp
  case 121: return 48; // PageDown
  case 49: return 49;  // Space
  case 53: return 50;  // Escape
  case 41: return 51;  // Semicolon
  case 43: return 52;  // Comma
  case 47: return 53;  // Period
  case 44: return 54;  // Slash
  case 27: return 55;  // Minus
  case 24: return 56;  // Equal
  case 33: return 57;  // BracketLeft
  case 30: return 58;  // BracketRight
  case 39: return 59;  // Quote
  case 50: return 60;  // Backquote
  case 42: return 61;  // Backslash
  default:
    return -1;
  }
}

static void mgw_push_text_event(id event) {
  if (g_text_event_count >= MGW_MAX_TEXT_EVENTS) {
    return;
  }
  id chars = ((id(*)(id, SEL))objc_msgSend)(event, mgw_sel("characters"));
  if (!chars) {
    return;
  }
  const char *utf8 = ((const char *(*)(id, SEL))objc_msgSend)(
    chars, mgw_sel("UTF8String"));
  if (!utf8 || utf8[0] == '\0') {
    return;
  }
  /* Skip pure control events. */
  bool has_non_control = false;
  for (const unsigned char *p = (const unsigned char *)utf8; *p; ++p) {
    if (*p >= 0x20U) {
      has_non_control = true;
      break;
    }
  }
  if (!has_non_control) {
    return;
  }
  g_text_events[g_text_event_count] = mgw_dup_cstr(utf8);
  if (!g_text_events[g_text_event_count]) {
    return;
  }
  g_text_event_count += 1;
}

static void mgw_set_cursor_from_event(mgw_window_t *window, id event) {
  if (!window || !event) {
    return;
  }
  mgw_point_t loc = ((mgw_point_t(*)(id, SEL))objc_msgSend)(
    event, mgw_sel("locationInWindow"));
  g_mouse_x = (float)loc.x;
  g_mouse_y = (float)window->height - (float)loc.y;
  if (g_mouse_y < 0.0f) {
    g_mouse_y = 0.0f;
  }
}

static void mgw_process_event(mgw_window_t *window, id event) {
  if (!event) {
    return;
  }
  mgw_nsuint_t type = ((mgw_nsuint_t(*)(id, SEL))objc_msgSend)(
    event, mgw_sel("type"));

  if (type == 8UL) { // cursor entered
    g_has_cursor = true;
  } else if (type == 9UL) { // cursor left
    g_has_cursor = false;
  }

  if (type == 5UL || type == 6UL || type == 7UL || type == 27UL ||
      type == 1UL || type == 2UL || type == 3UL || type == 4UL ||
      type == 25UL || type == 26UL) {
    g_has_cursor = true;
    mgw_set_cursor_from_event(window, event);
  }

  if (type == 22UL) { // scroll wheel
    double dx = ((double(*)(id, SEL))objc_msgSend)(
      event, mgw_sel("scrollingDeltaX"));
    double dy = ((double(*)(id, SEL))objc_msgSend)(
      event, mgw_sel("scrollingDeltaY"));
    g_wheel_x += (float)dx;
    g_wheel_y += (float)dy;
  }

  if (type == 10UL || type == 11UL || type == 12UL) { // key down/up/flags changed
    mgw_nsuint_t key_code = ((mgw_nsuint_t(*)(id, SEL))objc_msgSend)(
      event, mgw_sel("keyCode"));
    int key_id = mgw_key_id_from_mac(key_code);
    if (key_id >= 0 && key_id < MGW_KEY_COUNT) {
      if (type == 10UL) {
        mgw_bool_t repeat = ((mgw_bool_t(*)(id, SEL))objc_msgSend)(
          event, mgw_sel("isARepeat"));
        if (repeat) {
          g_key_repeated[key_id] = true;
        }
        if (!g_key_down[key_id]) {
          g_key_just_pressed[key_id] = true;
        }
        g_key_down[key_id] = true;
        mgw_push_text_event(event);
      } else if (type == 11UL) {
        if (g_key_down[key_id]) {
          g_key_just_released[key_id] = true;
        }
        g_key_down[key_id] = false;
      } else {
        /* flags changed for modifiers: infer toggle from current state */
        if (g_key_down[key_id]) {
          g_key_down[key_id] = false;
          g_key_just_released[key_id] = true;
        } else {
          g_key_down[key_id] = true;
          g_key_just_pressed[key_id] = true;
        }
      }
    }
  }

  if (type == 1UL || type == 2UL || type == 3UL || type == 4UL ||
      type == 25UL || type == 26UL) {
    int button = mgw_mouse_button_from_type(event, type);
    if (button >= 0 && button < MGW_MOUSE_BUTTON_COUNT) {
      bool pressed = (type == 1UL || type == 3UL || type == 25UL);
      if (pressed) {
        if (!g_mouse_down[button]) {
          g_mouse_just_pressed[button] = true;
        }
        g_mouse_down[button] = true;
      } else {
        if (g_mouse_down[button]) {
          g_mouse_just_released[button] = true;
        }
        g_mouse_down[button] = false;
      }
    }
  }
}
#endif

int mgw_window_create_utf8(
  int logical_width,
  int logical_height,
  int physical_width,
  int physical_height,
  bool use_physical_size_on_create,
  const uint8_t *title,
  uint64_t title_len
) {
  mgw_window_t *window = (mgw_window_t *)calloc(1, sizeof(mgw_window_t));
  if (!window) {
    return 0;
  }

  window->id = g_next_id++;
  window->width = mgw_clamp_size(physical_width);
  window->height = mgw_clamp_size(physical_height);
  window->scale_factor = 1.0f;
  window->focused = 1;
  window->should_close = 0;
  window->x = 0;
  window->y = 0;

#if defined(__APPLE__)
  if (mgw_bootstrap_app()) {
    Class window_class = objc_getClass("NSWindow");
    if (window_class) {
      id allocated = mgw_msg_id((id)window_class, "alloc");
      mgw_rect_t rect = {
        .origin = {0.0, 0.0},
        .size = {
          (double)mgw_clamp_size(logical_width),
          (double)mgw_clamp_size(logical_height),
        },
      };
      const mgw_nsuint_t style_mask =
        (1UL << 0) | (1UL << 1) | (1UL << 2) | (1UL << 3);
      id ns_window = ((id(*)(id, SEL, mgw_rect_t, mgw_nsuint_t, mgw_nsuint_t, mgw_bool_t))objc_msgSend)(
        allocated,
        mgw_sel("initWithContentRect:styleMask:backing:defer:"),
        rect,
        style_mask,
        2UL,
        NO
      );
      if (ns_window) {
        ((void(*)(id, SEL, mgw_bool_t))objc_msgSend)(
          ns_window, mgw_sel("setReleasedWhenClosed:"), NO);

        char *title_utf8 = mgw_copy_utf8(title, title_len);
        id ns_title = mgw_make_nsstring(
          title_utf8 && title_utf8[0] != '\0' ? title_utf8 : "Moon Game Studio");
        if (ns_title) {
          ((void(*)(id, SEL, id))objc_msgSend)(
            ns_window, mgw_sel("setTitle:"), ns_title);
        }
        if (title_utf8) {
          free(title_utf8);
        }

        window->window = (void *)ns_window;
        window->content_view = (void *)mgw_msg_id(ns_window, "contentView");
        window->scale_factor = (float)((double(*)(id, SEL))objc_msgSend)(
          ns_window, mgw_sel("backingScaleFactor"));
        if (use_physical_size_on_create) {
          mgw_size_t content_size = {
            .width = mgw_scale_to_points(window->width, window->scale_factor),
            .height = mgw_scale_to_points(window->height, window->scale_factor),
          };
          ((void(*)(id, SEL, mgw_size_t))objc_msgSend)(
            ns_window, mgw_sel("setContentSize:"), content_size);
        }
        mgw_msg_void(ns_window, "center");
        ((void(*)(id, SEL, id))objc_msgSend)(
          ns_window, mgw_sel("makeKeyAndOrderFront:"), nil);
      }
    }
  }
#else
  (void)logical_width;
  (void)logical_height;
  (void)physical_width;
  (void)physical_height;
  (void)use_physical_size_on_create;
  (void)title;
  (void)title_len;
#endif

  mgw_push_window(window);
  return window->id;
}

void mgw_window_poll_events(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window) {
    return;
  }
#if defined(__APPLE__)
  if (!mgw_bootstrap_app() || !g_ns_app) {
    return;
  }
  id date_class = (id)objc_getClass("NSDate");
  id distant_past = date_class
    ? mgw_msg_id(date_class, "distantPast")
    : nil;
  id runloop_mode = mgw_make_nsstring("kCFRunLoopDefaultMode");
  while (true) {
    id event = ((id(*)(id, SEL, mgw_nsuint_t, id, id, mgw_bool_t))objc_msgSend)(
      g_ns_app,
      mgw_sel("nextEventMatchingMask:untilDate:inMode:dequeue:"),
      (mgw_nsuint_t)~(mgw_nsuint_t)0,
      distant_past,
      runloop_mode,
      YES
    );
    if (!event) {
      break;
    }
    mgw_process_event(window, event);
    ((void(*)(id, SEL, id))objc_msgSend)(g_ns_app, mgw_sel("sendEvent:"), event);
  }
  mgw_msg_void(g_ns_app, "updateWindows");
  mgw_update_window_state(window);
#endif
}

int mgw_window_width(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->width : 1280;
}

int mgw_window_height(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->height : 720;
}

float mgw_window_scale_factor(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->scale_factor : 1.0f;
}

bool mgw_window_focused(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->focused != 0 : false;
}

bool mgw_window_should_close(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->should_close != 0 : true;
}

void mgw_window_request_close(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window) {
    return;
  }
  window->should_close = 1;
#if defined(__APPLE__)
  if (window->window) {
    ((void(*)(id, SEL, id))objc_msgSend)(
      (id)window->window, mgw_sel("performClose:"), nil);
  }
#endif
}

bool mgw_window_any_open(void) {
  for (size_t i = 0; i < g_windows_len; ++i) {
    if (g_windows[i] && g_windows[i]->should_close == 0) {
      return true;
    }
  }
  return false;
}

void mgw_window_set_title_utf8(
  int window_id,
  const uint8_t *title,
  uint64_t title_len
) {
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window) {
    return;
  }
#if defined(__APPLE__)
  if (window->window) {
    char *title_utf8 = mgw_copy_utf8(title, title_len);
    id ns_title = mgw_make_nsstring(title_utf8 ? title_utf8 : "");
    if (ns_title) {
      ((void(*)(id, SEL, id))objc_msgSend)(
        (id)window->window, mgw_sel("setTitle:"), ns_title);
    }
    if (title_utf8) {
      free(title_utf8);
    }
  }
#else
  (void)title;
  (void)title_len;
#endif
}

void mgw_window_set_size(int window_id, int width, int height) {
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window) {
    return;
  }
  window->width = mgw_clamp_size(width);
  window->height = mgw_clamp_size(height);
#if defined(__APPLE__)
  if (window->window) {
    mgw_size_t size = {
      .width = mgw_scale_to_points(window->width, window->scale_factor),
      .height = mgw_scale_to_points(window->height, window->scale_factor),
    };
    ((void(*)(id, SEL, mgw_size_t))objc_msgSend)(
      (id)window->window, mgw_sel("setContentSize:"), size);
  }
#endif
}

void mgw_window_set_resizable(int window_id, bool resizable) {
  (void)window_id;
  (void)resizable;
}

void mgw_window_set_cursor_visible(int window_id, bool visible) {
  (void)window_id;
  (void)visible;
}

void mgw_window_set_cursor_grab_mode(int window_id, int mode) {
  (void)window_id;
  (void)mode;
}

void mgw_window_set_cursor_icon(int window_id, int icon) {
  (void)window_id;
  (void)icon;
}

void mgw_window_set_mode(int window_id, int mode) {
  (void)window_id;
  (void)mode;
}

void mgw_window_set_position(int window_id, int x, int y) {
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window) {
    return;
  }
  window->x = x;
  window->y = y;
#if defined(__APPLE__)
  if (window->window) {
    mgw_point_t point = {.x = (double)x, .y = (double)y};
    ((void(*)(id, SEL, mgw_point_t))objc_msgSend)(
      (id)window->window, mgw_sel("setFrameOrigin:"), point);
  }
#endif
}

int mgw_window_position_x(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->x : 0;
}

int mgw_window_position_y(int window_id) {
  mgw_window_t *window = mgw_find_window(window_id);
  return window ? window->y : 0;
}

void mgw_window_attach_metal_layer(int window_id, void *layer) {
#if defined(__APPLE__)
  mgw_window_t *window = mgw_find_window(window_id);
  if (!window || !window->content_view || !layer) {
    return;
  }
  ((void(*)(id, SEL, mgw_bool_t))objc_msgSend)(
    (id)window->content_view, mgw_sel("setWantsLayer:"), YES);
  ((void(*)(id, SEL, id))objc_msgSend)(
    (id)window->content_view, mgw_sel("setLayer:"), (id)layer);
#else
  (void)window_id;
  (void)layer;
#endif
}

bool mgw_window_native_backend_available(void) {
#if defined(__APPLE__)
  return mgw_bootstrap_app();
#else
  return false;
#endif
}

void mgw_input_finish_frame(void) {
  memset(g_key_just_pressed, 0, sizeof(g_key_just_pressed));
  memset(g_key_just_released, 0, sizeof(g_key_just_released));
  memset(g_key_repeated, 0, sizeof(g_key_repeated));
  memset(g_mouse_just_pressed, 0, sizeof(g_mouse_just_pressed));
  memset(g_mouse_just_released, 0, sizeof(g_mouse_just_released));
  g_wheel_x = 0.0f;
  g_wheel_y = 0.0f;
  mgw_clear_text_events();
  g_touch_event_count = 0;
  mgw_clear_drag_events();
}

bool mgw_input_has_cursor(void) {
  return g_has_cursor;
}

float mgw_input_mouse_x(void) {
  return g_mouse_x;
}

float mgw_input_mouse_y(void) {
  return g_mouse_y;
}

float mgw_input_wheel_x(void) {
  return g_wheel_x;
}

float mgw_input_wheel_y(void) {
  return g_wheel_y;
}

bool mgw_input_is_key_down(int key_id) {
  if (key_id < 0 || key_id >= MGW_KEY_COUNT) {
    return false;
  }
  return g_key_down[key_id];
}

bool mgw_input_is_key_just_pressed(int key_id) {
  if (key_id < 0 || key_id >= MGW_KEY_COUNT) {
    return false;
  }
  return g_key_just_pressed[key_id];
}

bool mgw_input_is_key_just_released(int key_id) {
  if (key_id < 0 || key_id >= MGW_KEY_COUNT) {
    return false;
  }
  return g_key_just_released[key_id];
}

bool mgw_input_is_key_repeated(int key_id) {
  if (key_id < 0 || key_id >= MGW_KEY_COUNT) {
    return false;
  }
  return g_key_repeated[key_id];
}

bool mgw_input_is_mouse_button_down(int button_id) {
  if (button_id < 0 || button_id >= MGW_MOUSE_BUTTON_COUNT) {
    return false;
  }
  return g_mouse_down[button_id];
}

bool mgw_input_is_mouse_button_just_pressed(int button_id) {
  if (button_id < 0 || button_id >= MGW_MOUSE_BUTTON_COUNT) {
    return false;
  }
  return g_mouse_just_pressed[button_id];
}

bool mgw_input_is_mouse_button_just_released(int button_id) {
  if (button_id < 0 || button_id >= MGW_MOUSE_BUTTON_COUNT) {
    return false;
  }
  return g_mouse_just_released[button_id];
}

int mgw_input_text_event_count(void) {
  return g_text_event_count;
}

int mgw_input_text_event_len(int index) {
  if (index < 0 || index >= g_text_event_count || !g_text_events[index]) {
    return 0;
  }
  return (int)strlen(g_text_events[index]);
}

int mgw_input_text_event_code_unit(int index, int offset) {
  if (index < 0 || index >= g_text_event_count || !g_text_events[index] ||
      offset < 0) {
    return 0;
  }
  size_t len = strlen(g_text_events[index]);
  if ((size_t)offset >= len) {
    return 0;
  }
  return (unsigned char)g_text_events[index][offset];
}

int mgw_input_touch_event_count(void) {
  return g_touch_event_count;
}

int mgw_input_touch_event_id(int index) {
  if (index < 0 || index >= g_touch_event_count) {
    return -1;
  }
  return g_touch_events[index].id;
}

int mgw_input_touch_event_phase(int index) {
  if (index < 0 || index >= g_touch_event_count) {
    return 0;
  }
  return g_touch_events[index].phase;
}

float mgw_input_touch_event_x(int index) {
  if (index < 0 || index >= g_touch_event_count) {
    return 0.0f;
  }
  return g_touch_events[index].x;
}

float mgw_input_touch_event_y(int index) {
  if (index < 0 || index >= g_touch_event_count) {
    return 0.0f;
  }
  return g_touch_events[index].y;
}

int mgw_input_drag_and_drop_event_count(void) {
  return g_drag_event_count;
}

int mgw_input_drag_and_drop_event_kind(int index) {
  if (index < 0 || index >= g_drag_event_count) {
    return 0;
  }
  return g_drag_events[index].kind;
}

int mgw_input_drag_and_drop_event_len(int index) {
  if (index < 0 || index >= g_drag_event_count || !g_drag_events[index].text) {
    return 0;
  }
  return (int)strlen(g_drag_events[index].text);
}

int mgw_input_drag_and_drop_event_code_unit(int index, int offset) {
  if (index < 0 || index >= g_drag_event_count || !g_drag_events[index].text ||
      offset < 0) {
    return 0;
  }
  size_t len = strlen(g_drag_events[index].text);
  if ((size_t)offset >= len) {
    return 0;
  }
  return (unsigned char)g_drag_events[index].text[offset];
}
