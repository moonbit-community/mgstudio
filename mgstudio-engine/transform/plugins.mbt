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
pub let transform_set_propagate : @app.SystemSet = @app.system_set(
  "mgstudio.transform.propagate",
)

///|
fn transform_mark_dirty_trees_system_config() -> @app.SystemConfig[@ecs.World] {
  @app.system(@app.system_param4(mark_dirty_trees_system)).named(
    "mgstudio.transform.mark_dirty_trees_system",
  )
}

///|
fn transform_propagate_parent_transforms_system_config() -> @app.SystemConfig[
  @ecs.World,
] {
  @app.system(propagate_parent_transforms_system).named(
    "mgstudio.transform.propagate_parent_transforms_system",
  )
}

///|
fn transform_sync_simple_transforms_system_config() -> @app.SystemConfig[
  @ecs.World,
] {
  @app.system(@app.system_param2(sync_simple_transforms)).named(
    "mgstudio.transform.sync_simple_transforms",
  )
}

///|
pub fn transform_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @hierarchy.hierarchy_install_component_metadata()
  transform_install_component_metadata()
  ensure_transform_runtime_resources(app.world())
  let validate_parent_plugin : @app.ValidateParentHasComponentPlugin[
    GlobalTransform,
  ] = @app.ValidateParentHasComponentPlugin::default()
  app
  .add_plugins(validate_parent_plugin)
  .add_systems(
    @app.PostStartup,
    (
      transform_mark_dirty_trees_system_config(),
      transform_propagate_parent_transforms_system_config(),
      transform_sync_simple_transforms_system_config(),
    )
    |> @app.chain()
    |> @app.SystemConfig::in_set(transform_set_propagate),
  )
  .add_systems(
    @app.PostUpdate,
    (
      transform_mark_dirty_trees_system_config(),
      transform_propagate_parent_transforms_system_config(),
      transform_sync_simple_transforms_system_config(),
    )
    |> @app.chain()
    |> @app.SystemConfig::in_set(transform_set_propagate),
  )
}
