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
// Bevy source: `bevy/crates/bevy_ui_render/src/debug_overlay.rs`.
const UI_STACK_Z_BASE : Float = 10000.0F

///|
const UI_STACK_Z_STEP : Float = 10.0F

///|
const UI_STACK_Z_BACKGROUND : Float = 0.0F

///|
const UI_STACK_Z_SHADOW : Float = -1.0F

///|
const UI_STACK_Z_CONTENT : Float = 1.0F

///|
const UI_STACK_Z_BORDER : Float = 2.0F

///|
const UI_STACK_Z_OUTLINE : Float = 4.0F

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn safe_scale_factor(scale : Float) -> Float {
  if scale <= 0.0F {
    1.0F
  } else {
    scale
  }
}
