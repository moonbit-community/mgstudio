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

#include <stdint.h>
#include <time.h>

// Monotonic time in milliseconds (f32) for `mgstudio_host.time_now`.
//
// Engine time code expects Web-like semantics where `time_now` is in ms
// (matching `performance.now()`), then divides by 1000 to compute seconds.
MOONBIT_FFI_EXPORT float mgstudio_time_now(void) {
  struct timespec ts;
#if defined(CLOCK_MONOTONIC)
  if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0) {
    double ms = (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec * 1e-6;
    return (float)ms;
  }
#endif
  return 0.0f;
}
