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
#include <stdio.h>

// Host hook for wasm spec tests: `spectest.print_char(i32)`.
// We treat the input as a byte and print it without newline.
void mgstudio_spectest_print_char(int64_t ch) {
  unsigned char c = (unsigned char)(ch & 0xFF);
  fputc((int)c, stdout);
  fflush(stdout);
}

