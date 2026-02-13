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
/// First-pass 3D debug-render plugin aligned with Bevy Rapier's plugin purpose:
/// visualize physics colliders directly from the physics world.
///
/// Notes:
/// - Current mgstudio implementation renders unlit translucent meshes.
/// - Collider shape coverage matches current `ColliderShape3d` support
///   (`Ball` and `Cuboid`).

///|
pub struct Physics3dDebugRenderContext {
  mut enabled : Bool
}

///|
pub fn Physics3dDebugRenderContext::default() -> Physics3dDebugRenderContext {
  { enabled: true }
}

///|
priv struct Physics3dDebugRenderState {
  mut unit_cuboid_mesh : @render3d.Mesh3d?
  mut dynamic_material : @render3d.MeshMaterial3d?
  mut fixed_material : @render3d.MeshMaterial3d?
  mut kinematic_material : @render3d.MeshMaterial3d?
  mut parentless_material : @render3d.MeshMaterial3d?
  mut sensor_material : @render3d.MeshMaterial3d?
  collider_to_debug_entity : @hashmap.HashMap[(Int, Int), @core.Entity]
}

///|
let physics3d_debug_render_context : Ref[Physics3dDebugRenderContext] = Ref::new(
  Physics3dDebugRenderContext::default(),
)

///|
let physics3d_debug_render_state : Ref[Physics3dDebugRenderState] = Ref::new({
  unit_cuboid_mesh: None,
  dynamic_material: None,
  fixed_material: None,
  kinematic_material: None,
  parentless_material: None,
  sensor_material: None,
  collider_to_debug_entity: @hashmap.HashMap::new(),
})

///|
fn physics3d_debug_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
fn physics3d_debug_make_material(
  color : @render2d.Color,
) -> @render3d.MeshMaterial3d {
  let standard = @render3d.StandardMaterial::from_color(color)
    .with_unlit(true)
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
  @render3d.MeshMaterial3d::new(@render3d.standard_material_add(standard))
}

///|
fn physics3d_debug_min_extent(value : Float) -> Float {
  if value > 0.01F {
    value
  } else {
    0.01F
  }
}

///|
fn physics3d_debug_shape_scale(shape : ColliderShape3d) -> @math.Vec3 {
  match shape {
    Ball(radius) => {
      let diameter = physics3d_debug_min_extent(radius * 2.0F)
      @math.Vec3::new(diameter, diameter, diameter)
    }
    Cuboid(hx, hy, hz) =>
      @math.Vec3::new(
        physics3d_debug_min_extent(hx * 2.0F),
        physics3d_debug_min_extent(hy * 2.0F),
        physics3d_debug_min_extent(hz * 2.0F),
      )
  }
}

///|
fn physics3d_debug_material_for(
  rb3d : RigidBody3d?,
  sensor : Bool,
) -> @render3d.MeshMaterial3d? {
  let state = physics3d_debug_render_state.val
  if sensor {
    return state.sensor_material
  }
  match rb3d {
    Some(rb) =>
      match rb.body_type {
        @dynamics.RigidBodyType::Dynamic => state.dynamic_material
        @dynamics.RigidBodyType::Fixed => state.fixed_material
        @dynamics.RigidBodyType::KinematicPositionBased =>
          state.kinematic_material
        @dynamics.RigidBodyType::KinematicVelocityBased =>
          state.kinematic_material
      }
    None => state.parentless_material
  }
}

///|
fn physics3d_debug_ensure_assets() -> Unit {
  let state = physics3d_debug_render_state.val
  if state.unit_cuboid_mesh is Some(_) {
    return
  }
  state.unit_cuboid_mesh = Some(@render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F))
  state.dynamic_material = Some(
    physics3d_debug_make_material(
      @render2d.Color::new(0.94F, 0.22F, 0.34F, 0.24F),
    ),
  )
  state.fixed_material = Some(
    physics3d_debug_make_material(
      @render2d.Color::new(0.98F, 0.56F, 0.18F, 0.20F),
    ),
  )
  state.kinematic_material = Some(
    physics3d_debug_make_material(
      @render2d.Color::new(0.98F, 0.34F, 0.20F, 0.22F),
    ),
  )
  state.parentless_material = Some(
    physics3d_debug_make_material(
      @render2d.Color::new(0.82F, 0.82F, 0.84F, 0.18F),
    ),
  )
  state.sensor_material = Some(
    physics3d_debug_make_material(
      @render2d.Color::new(0.22F, 0.82F, 0.98F, 0.22F),
    ),
  )
}

///|
pub fn physics3d_debug_render_set_enabled(enabled : Bool) -> Unit {
  physics3d_debug_render_context.val.enabled = enabled
}

///|
pub fn physics3d_debug_render_enabled() -> Bool {
  physics3d_debug_render_context.val.enabled
}

///|
pub(open) trait Physics3dDebugRenderPluginWorld: @render3d.MeshMaterial3dBundleSpawnWorld + Has_Collider3d + Has_RigidBody3d {
}

///|
fn[W : Physics3dDebugRenderPluginWorld] physics3d_debug_clear_entities(
  world : W,
) -> Unit {
  let state = physics3d_debug_render_state.val
  let transform_store = world.get_transform_store()
  let keys_to_remove : Array[(Int, Int)] = []
  state.collider_to_debug_entity.each(fn(key, debug_entity) {
    if transform_store.contains(debug_entity) {
      try! (world.despawn(debug_entity) |> ignore)
    }
    keys_to_remove.push(key)
  })
  for key in keys_to_remove {
    state.collider_to_debug_entity.remove(key)
  }
}

///|
fn[W : Physics3dDebugRenderPluginWorld] physics3d_debug_ensure_entity(
  world : W,
  source_entity : @core.Entity,
  material : @render3d.MeshMaterial3d,
) -> @core.Entity? {
  let state = physics3d_debug_render_state.val
  let transform_store = world.get_transform_store()
  let key = physics3d_debug_entity_key(source_entity)
  if state.collider_to_debug_entity.get(key) is Some(debug_entity) {
    if transform_store.contains(debug_entity) {
      return Some(debug_entity)
    }
    state.collider_to_debug_entity.remove(key)
  }
  guard state.unit_cuboid_mesh is Some(mesh) else { return None }
  let debug_entity = @render3d.MeshMaterial3dBundle::new(
    mesh,
    material,
    @math.Transform::identity(),
  ).spawn(world)
  state.collider_to_debug_entity.set(key, debug_entity)
  Some(debug_entity)
}

///|
pub fn[W : Physics3dDebugRenderPluginWorld] physics3d_debug_render_sync_system(
  world : W,
) -> Unit {
  physics3d_debug_ensure_assets()
  let state = physics3d_debug_render_state.val
  if !physics3d_debug_render_context.val.enabled {
    if !state.collider_to_debug_entity.is_empty() {
      physics3d_debug_clear_entities(world)
    }
    return
  }

  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  let collider_store = world.get_collider3d_store()
  let rigid_body_store = world.get_rigid_body3d_store()
  let mesh_material_store = world.get_mesh_material3d_store()

  let stale_keys : Array[(Int, Int)] = []
  state.collider_to_debug_entity.each(fn(key, debug_entity) {
    let source_entity = @core.Entity::new(key.0, key.1)
    if !collider_store.contains(source_entity) ||
      !transform_store.contains(debug_entity) {
      if transform_store.contains(debug_entity) {
        try! (world.despawn(debug_entity) |> ignore)
      }
      stale_keys.push(key)
    }
  })
  for key in stale_keys {
    state.collider_to_debug_entity.remove(key)
  }

  collider_store.for_each(fn(entity, collider) {
    guard physics3d_debug_material_for(
        rigid_body_store.get(entity),
        collider.sensor,
      )
      is Some(material) else {
      return
    }
    guard physics3d_debug_ensure_entity(world, entity, material)
      is Some(debug_entity) else {
      return
    }

    let source_transform = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    let next_transform = @math.Transform::new(
      source_transform.translation,
      source_transform.rotation,
      physics3d_debug_shape_scale(collider.shape),
    )
    transform_store.set(debug_entity, next_transform, tick) |> ignore
    mesh_material_store.set(debug_entity, material, tick) |> ignore
  })
}

///|
pub let physics3d_set_debug_render_sync : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.debug_render.sync",
)

///|
pub fn[W : Physics3dDebugRenderPluginWorld] physics3d_debug_render_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_fixed_update_system_config(
    @app.system(physics3d_debug_render_sync_system).in_set(
      physics3d_set_debug_render_sync,
    ),
  )
  .configure_set(@app.FixedUpdate, physics3d_set_debug_render_sync, after=[
    physics3d_set_writeback,
  ])
}
