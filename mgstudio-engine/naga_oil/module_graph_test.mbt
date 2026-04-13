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
test "naga_oil: import target parser preserves nested group and alias shapes" {
  let targets : Array[@naga_oil.WgslImportTarget] = []
  @naga_oil.collect_wgsl_import_targets(
    "bevy_render::{view::View, globals::Globals, maths as maths}", "", targets,
  )
  debug_inspect(targets.length(), content="3")
  debug_inspect(targets[0].raw_path, content="bevy_render::view::View")
  debug_inspect(targets[0].alias_name, content="")
  debug_inspect(targets[1].raw_path, content="bevy_render::globals::Globals")
  debug_inspect(targets[2].raw_path, content="bevy_render::maths")
  debug_inspect(targets[2].alias_name, content="maths")
}

///|
test "naga_oil: registered source registry tracks define_import_path" {
  @naga_oil.clear_registered_wgsl_source_registry()
  @naga_oil.register_wgsl_source(
    "shaders/demo/module.wgsl", "#define_import_path demo::module\nfn shade() -> f32 { return 1.0; }\n",
  )
  debug_inspect(
    @naga_oil.registered_wgsl_source("shaders/demo/module.wgsl"),
    content="Some(\"#define_import_path demo::module\\nfn shade() -> f32 { return 1.0; }\\n\")",
  )
  let modules = @naga_oil.build_wgsl_import_module_paths("")
  debug_inspect(
    modules.get("demo::module"),
    content="Some(\"shaders/demo/module.wgsl\")",
  )
  @naga_oil.clear_registered_wgsl_source_registry()
}

///|
test "naga_oil: resolve import module prefers registered map entries" {
  @naga_oil.clear_registered_wgsl_source_registry()
  @naga_oil.register_wgsl_source(
    "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl", "#define_import_path bevy_sprite_render::render::sprite_view_bindings\nfn shade() -> f32 { return 1.0; }\n",
  )
  let modules = @naga_oil.build_wgsl_import_module_paths("")
  let resolved = @naga_oil.resolve_wgsl_import_module(
    "", "bevy_sprite_render::render::sprite_view_bindings::View", modules,
  )
  debug_inspect(
    resolved,
    content="Some({module_path: \"bevy_sprite_render::render::sprite_view_bindings\", rel_path: \"shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl\"})",
  )
  @naga_oil.clear_registered_wgsl_source_registry()
}
