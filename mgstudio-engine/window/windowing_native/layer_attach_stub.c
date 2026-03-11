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
#endif

uint64_t mbw_window_handle(int window_id);

void mgstudio_window_attach_metal_layer_from_mbw(int window_id, void *layer) {
#if defined(__APPLE__)
  if (!layer) {
    return;
  }

  uint64_t raw_window = mbw_window_handle(window_id);
  if (raw_window == 0) {
    return;
  }

  id ns_window = (id)(uintptr_t)raw_window;
  SEL content_view_sel = sel_registerName("contentView");
  id content_view = ((id(*)(id, SEL))objc_msgSend)(ns_window, content_view_sel);
  if (!content_view) {
    return;
  }

  ((void(*)(id, SEL, BOOL))objc_msgSend)(
    content_view,
    sel_registerName("setWantsLayer:"),
    (BOOL)1);
  ((void(*)(id, SEL, id))objc_msgSend)(
    content_view,
    sel_registerName("setLayer:"),
    (id)layer);
#else
  (void)window_id;
  (void)layer;
#endif
}
