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
fn sprite_wgsl_registered(path : String) -> Bool {
  @wgsl.registered_wgsl_source(path) is Some(_)
}

///|
fn sprite_wgsl_source(path : String) -> String {
  match @wgsl.registered_wgsl_source(path) {
    Some(source) => source
    None => ""
  }
}

///|
test "sprite: embedded wgsl sources are registered by sprite owner" {
  register_embedded_wgsl_sources()
  debug_inspect(
    sprite_wgsl_registered("sprite_render/render/sprite.wgsl"),
    content="true",
  )
  debug_inspect(
    sprite_wgsl_registered("sprite_render/render/sprite_view_bindings.wgsl"),
    content="true",
  )
  debug_inspect(
    sprite_wgsl_registered("sprite_render/mesh2d/mesh2d.wgsl"),
    content="true",
  )
  debug_inspect(
    sprite_wgsl_registered("sprite_render/mesh2d/wireframe2d.wgsl"),
    content="true",
  )
  let wireframe = sprite_wgsl_source("sprite_render/mesh2d/wireframe2d.wgsl")
  debug_inspect(wireframe.contains("struct PushConstants {"), content="true")
  debug_inspect(
    wireframe.contains("return push_constants.color;"),
    content="true",
  )
}
