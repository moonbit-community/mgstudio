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
pub let ecs_key_transform : @ecs.ComponentKey[Transform] = @ecs.register_component(
  debug_name="transform.transform",
)

///|
pub impl @ecs.Component for Transform with component() {
  transform_install_component_metadata()
  ecs_key_transform
}

///|
pub let ecs_key_global_transform : @ecs.ComponentKey[GlobalTransform] = @ecs.register_component(
  debug_name="transform.global_transform",
)

///|
pub impl @ecs.Component for GlobalTransform with component() {
  ecs_key_global_transform
}

///|
pub let ecs_key_transform_tree_changed : @ecs.ComponentKey[TransformTreeChanged] = @ecs.register_component(
  debug_name="transform.tree_changed",
)

///|
pub impl @ecs.Component for TransformTreeChanged with component() {
  ecs_key_transform_tree_changed
}

///|
let transform_component_metadata_installed : Ref[Bool] = Ref::new(false)

///|
pub fn transform_install_component_metadata() -> Unit {
  if transform_component_metadata_installed.val {
    return
  }
  ignore(
    @ecs.component_metadata_builder(ecs_key_transform)
    .require_default(ecs_key_global_transform)
    .require_default(ecs_key_transform_tree_changed),
  )
  transform_component_metadata_installed.val = true
}

///|
pub fn mark_dirty_trees_ecs(world : @ecs.World) -> Unit {
  mark_dirty_trees(world)
}

///|
pub fn propagate_parent_transforms_ecs(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}

///|
pub fn propagate_transforms_system_ecs(world : @ecs.World) -> Unit {
  propagate_parent_transforms(world)
}

///|
pub fn transform_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  transform_plugin(app)
}
