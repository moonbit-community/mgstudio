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

  // mbw_window_handle returns MBWContentView handle (not NSWindow handle).
  uint64_t raw_content_view = mbw_window_handle(window_id);
  if (raw_content_view == 0) {
    return;
  }

  id content_view = (id)(uintptr_t)raw_content_view;

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
