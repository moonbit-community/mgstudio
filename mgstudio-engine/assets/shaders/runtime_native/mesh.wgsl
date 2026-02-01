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

// Native runtime solid-color mesh shader.

struct VSOut { @builtin(position) pos: vec4<f32> };

@group(0) @binding(0) var<uniform> color : vec4<f32>;

@vertex
fn vs_main(@location(0) pos: vec2<f32>) -> VSOut {
  var out: VSOut;
  out.pos = vec4<f32>(pos, 0.0, 1.0);
  return out;
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
  return color;
}

