// Copyright 2026 International Digital Economy Academy
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
fn ui_render_wgsl_registered(path : String) -> Bool {
  @wgsl.registered_wgsl_source(path) is Some(_)
}

///|
fn ui_render_wgsl_source(path : String) -> String {
  match @wgsl.registered_wgsl_source(path) {
    Some(source) => source
    None => ""
  }
}

///|
test "ui_render: embedded wgsl sources are registered by ui owner" {
  register_embedded_wgsl_sources()
  debug_inspect(ui_render_wgsl_registered("ui_render/ui.wgsl"), content="true")
  debug_inspect(
    ui_render_wgsl_registered("ui_render/ui_texture_slice.wgsl"),
    content="true",
  )
  debug_inspect(
    ui_render_wgsl_registered("ui_render/box_shadow.wgsl"),
    content="true",
  )
  debug_inspect(
    ui_render_wgsl_registered("ui_render/color_space.wgsl"),
    content="true",
  )
  debug_inspect(
    ui_render_wgsl_registered("ui_render/ui_vertex_output.wgsl"),
    content="true",
  )
  let ui = ui_render_wgsl_source("ui_render/ui.wgsl")
  debug_inspect(
    ui.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  debug_inspect(ui.contains("#ifdef ANTI_ALIAS"), content="true")
  debug_inspect(ui.contains("antialias(border_distance)"), content="true")
  let texture_slice = ui_render_wgsl_source("ui_render/ui_texture_slice.wgsl")
  debug_inspect(
    texture_slice.contains("var<uniform> globals: Globals;"),
    content="true",
  )
  debug_inspect(
    texture_slice.contains(
      "@group(1) @binding(0) var sprite_texture: texture_2d<f32>;",
    ),
    content="true",
  )
  let box_shadow = ui_render_wgsl_source("ui_render/box_shadow.wgsl")
  debug_inspect(
    box_shadow.contains("const SAMPLES: i32 = #SHADOW_SAMPLES;"),
    content="true",
  )
  debug_inspect(
    box_shadow.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
}
