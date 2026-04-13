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
// Bevy source: `bevy/crates/bevy_scene/src/scene_spawner.rs`.

///|
pub fn scene_reload_modified_roots_system(world : @ecs.World) -> Unit {
  let modified_scene_ids : Array[Int] = []
  if scene_modified_event_cursor_world_id_ref.val != world.world_id() {
    scene_modified_event_cursor_world_id_ref.val = world.world_id()
    scene_modified_event_cursor_ref.val = 0
  }
  let message_key : @ecs.MessageKey[@asset.AssetEvent[Scene]] = @ecs.Message::message()
  let reader = world.message_reader(
    message_key, scene_modified_event_cursor_ref,
  )
  for event in (try! reader.read()) {
    match event {
      Modified(handle) => modified_scene_ids.push(handle.id())
      _ => ()
    }
  }
  if modified_scene_ids.length() == 0 {
    return
  }

  let roots : Array[(@core.Entity, SceneRoot)] = []
  let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
    world,
  )
  try! scene_root_query.view(fn(entity, root) {
    roots.push((entity, root.value()))
  })

  for entry in roots {
    let root_entity = entry.0
    let root = entry.1
    let mut should_reload = false
    for scene_id in modified_scene_ids {
      if scene_id == root.scene.id() {
        should_reload = true
        break
      }
    }
    if !should_reload {
      continue
    }
    if scene_instance_component(world, root_entity) is Some(instance) {
      scene_despawn_instance(world, instance.instance_id)
    }
    scene_attach_pending_instance(world, root_entity, root) |> ignore
  }
}

///|
pub fn scene_spawn_roots_system(world : @ecs.World) -> Unit {
  let roots : Array[(@core.Entity, SceneRoot)] = []
  let scene_root_query : @ecs.Query[@ecs.Comp[SceneRoot], @ecs.All] = @ecs.query(
    world,
  )
  try! scene_root_query.view(fn(entity, root) {
    roots.push((entity, root.value()))
  })

  for entry in roots {
    let root_entity = entry.0
    let root = entry.1
    let instance_id = match scene_instance_component(world, root_entity) {
      Some(instance) =>
        match scene_runtime_get_instance(world, instance.instance_id) {
          Some(current) =>
            if current.scene_id == root.scene.id() {
              instance.instance_id
            } else {
              scene_despawn_instance(world, instance.instance_id)
              scene_attach_pending_instance(world, root_entity, root)
            }
          None => scene_attach_pending_instance(world, root_entity, root)
        }
      None => scene_attach_pending_instance(world, root_entity, root)
    }
    scene_spawn_instance_when_ready(world, root_entity, root, instance_id)
  }
}

///|
fn scene_runtime_plugin_base(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { SceneRuntimeState::default() })
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_reload_modified_roots_system)
  .add_pre_update_system(scene_spawn_roots_system)
}

///|
pub(all) struct ScenePlugin {}

///|
const SCENE_PLUGIN_NAME : String = "mgstudio.scene.ScenePlugin"

///|
pub fn ScenePlugin::default() -> ScenePlugin {
  ScenePlugin::{  }
}

///|
pub impl @app.PluginReplacement for ScenePlugin with plugin_name(_self) {
  SCENE_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for ScenePlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    scene_plugin_with(app, self)
  }
}

///|
pub fn scene_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  scene_plugin_with(app, ScenePlugin::default())
}

///|
pub fn scene_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : ScenePlugin,
) -> @app.App[@ecs.World] {
  scene_runtime_plugin_base(
    scene_init_gltf_assets(app)
    .init_resource(fn() {
      let assets : @asset.Assets[Scene] = @asset.Assets::new()
      assets
    })
    .init_resource(fn() {
      SceneAssetRegistryState::{
        scene_registry: [],
        animation_registry: [],
        mesh_registry: [],
        lod_visibility_policy: scene_gltf_lod_visibility_policy_ref.val,
      }
    }),
  )
}
