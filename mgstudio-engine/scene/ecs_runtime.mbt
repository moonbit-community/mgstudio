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
pub let ecs_key_scene_root : @ecs.ComponentKey[SceneRoot] = @ecs.register_component(
  debug_name="scene.scene_root",
)

///|
pub let ecs_key_scene_instance_ready : @ecs.ComponentKey[SceneInstanceReady] = @ecs.register_component(
  debug_name="scene.scene_instance_ready",
)

///|
pub impl @ecs.Component for SceneRoot with component() {
  ecs_key_scene_root
}

///|
pub impl @ecs.Component for SceneInstanceReady with component() {
  ecs_key_scene_instance_ready
}

///|
pub fn scene_spawn_roots_system_ecs(world : @ecs.World) -> Unit {
  let pending_roots : Array[(@core.Entity, SceneRoot)] = []
  try! world
  .query1(ecs_key_scene_root)
  .view(fn(entity, root) {
    if (try! world.get(entity, ecs_key_scene_instance_ready)) is None {
      pending_roots.push((entity, root))
    }
  })

  for pending in pending_roots {
    let root_entity = pending.0
    let root = pending.1
    guard scene_assets_from_world_or_abort(world).get(root.scene) is Some(scene) else {
      continue
    }
    if !scene.ready {
      continue
    }

    let mut spawned_entities = 0
    // TODO: re-enable root AnimationPlayer insertion after AnimationPlayer
    // gets stable ToJson/FromJson support in the ECS Json storage path.
    for node in scene.nodes3d {
      let child = world.spawn_empty()
      try! world.set(child, @render3d.ecs_key_mesh3d, node.mesh)
      try! world.set(child, @render3d.ecs_key_mesh_material3d, node.material)
      try! world.set(child, @math.ecs_key_transform, node.transform)
      try! world.set(
        child,
        @hierarchy.ecs_key_parent,
        @hierarchy.Parent::new(root_entity),
      )
      if node.visibility_range is Some(range) {
        try! world.set(child, @visibility.ecs_key_visibility_range, range)
      }
      if node.animation_target is Some(target_id) {
        try! world.set(child, @animation.ecs_key_animation_target_id, target_id)
        try! world.set(
          child,
          @animation.ecs_key_animated_by,
          @animation.AnimatedBy::new(root_entity),
        )
      }
      spawned_entities = spawned_entities + 1
    }

    try! world.set(
      root_entity,
      ecs_key_scene_instance_ready,
      SceneInstanceReady::new(spawned_entities),
    )
  }
}

///|
pub fn scene_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system(scene_load_pending_system)
  .add_pre_update_system(scene_spawn_roots_system_ecs)
}
