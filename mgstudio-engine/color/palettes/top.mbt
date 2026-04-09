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

///|
pub fn basic_palette() -> Array[@color.Color] {
  [
    basic_black(),
    basic_white(),
    basic_red(),
    basic_yellow(),
    basic_lime(),
    basic_aqua(),
    basic_blue(),
    basic_fuchsia(),
  ]
}

///|
pub fn css_palette() -> Array[@color.Color] {
  [
    css_alice_blue(),
    css_cornflower_blue(),
    css_gold(),
    css_coral(),
    css_crimson(),
    css_hot_pink(),
    css_rebecca_purple(),
  ]
}

///|
pub fn tailwind_palette() -> Array[@color.Color] {
  [
    tailwind_slate_50(),
    tailwind_blue_500(),
    tailwind_emerald_500(),
    tailwind_amber_500(),
    tailwind_rose_500(),
    tailwind_slate_950(),
  ]
}
