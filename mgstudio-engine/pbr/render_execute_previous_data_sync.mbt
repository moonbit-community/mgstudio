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
priv struct Render3dPreviousGlobalTransformSyncState {
  verified_missing_scan_generation : Int
}

///|
let render3d_previous_global_transform_sync_state_key : @ecs.ResourceKey[
  Render3dPreviousGlobalTransformSyncState
] = @ecs.register_resource(
  debug_name="mgstudio.render3d.previous_global_transform_sync_state",
)

///|
fn render3d_previous_global_transform_sync_state_mut(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dPreviousGlobalTransformSyncState] {
  match (try! world.get_resource_mut(
    render3d_previous_global_transform_sync_state_key,
  )) {
    Some(state) => state
    None => {
      world.insert_resource(
        render3d_previous_global_transform_sync_state_key,
        Render3dPreviousGlobalTransformSyncState::{
          verified_missing_scan_generation: -1,
        },
      )
      match (try! world.get_resource_mut(
        render3d_previous_global_transform_sync_state_key,
      )) {
        Some(state) => state
        None =>
          abort("Missing Render3dPreviousGlobalTransformSyncState resource")
      }
    }
  }
}

///|
fn render3d_entity_global_transform_from_main_world(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.GlobalTransform? {
  try! world.get_by_key(entity, @transform.ecs_key_global_transform)
}

///|
fn update_previous_view_data(world : @ecs.World) -> Unit {
  guard standard_material_prepass_enabled(world) else { return }
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let world_transform = match
      render3d_entity_global_transform_from_main_world(world, entity) {
      Some(value) => value
      None => return
    }
    let projection = match (try! world.get_by_key(entity, ecs_key_projection)) {
      Some(value) => value
      None => Projection::default()
    }
    let view_from_world = @pbr_render.render3d_view_from_world_matrix(
      world_transform.compute_transform(),
    )
    let clip_from_world = projection.get_clip_from_view().mul(view_from_world)
    try! world.set_by_key(
      entity,
      ecs_key_previous_view_data,
      @pbr_prepass.PreviousViewData::new(
        world_transform.compute_transform(), clip_from_world,
      ),
    )
  })
}

///|
fn render3d_has_active_camera(world : @ecs.World) -> Bool {
  let mut active = false
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let camera = match (try! world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(value) => value
      None => @sprite.Camera::default()
    }
    if camera.is_active {
      active = true
    }
  })
  active
}

///|
fn update_mesh_previous_global_transforms(world : @ecs.World) -> Unit {
  guard standard_material_prepass_enabled(world) else { return }
  guard render3d_has_active_camera(world) else { return }
  let existing_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Comp[@transform.GlobalTransform],
        @ecs.Mut[@pbr_prepass.PreviousGlobalTransform],
      ),
    ),
    (@ecs.With[Mesh3d], @ecs.Allow[@ecs.Disabled]),
  ] = @ecs.query_filtered(
    world,
    (
      @ecs.With::new(ecs_key_mesh3d),
      @ecs.Allow::new(@ecs.ecs_key_disabled),
    ),
  )
  try! existing_query.view(fn(_query_entity, data) {
    let (_entity, (global_transform, previous_global_transform)) = data
    previous_global_transform.set(
      @pbr_prepass.PreviousGlobalTransform::from_global_transform(
        global_transform.value(),
      ),
    )
  })

  let sync_state = render3d_previous_global_transform_sync_state_mut(world)
  let current_generation = world.structural_generation()
  guard sync_state.peek().verified_missing_scan_generation !=
        current_generation else {
    return
  }

  let missing : Array[
    (@core.Entity, @pbr_prepass.PreviousGlobalTransform)
  ] = []
  let missing_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Comp[Mesh3d],
        @ecs.Comp[@transform.GlobalTransform],
      ),
    ),
    (
      @ecs.With[Mesh3d],
      @ecs.Without[@pbr_prepass.PreviousGlobalTransform],
      @ecs.Allow[@ecs.Disabled],
    ),
  ] = @ecs.query_filtered(
    world,
    (
      @ecs.With::new(ecs_key_mesh3d),
      @ecs.Without::new(ecs_key_previous_global_transform),
      @ecs.Allow::new(@ecs.ecs_key_disabled),
    ),
  )
  try! missing_query.view(fn(_query_entity, data) {
    let (entity, (_mesh3d, global_transform)) = data
    missing.push((
      entity,
      @pbr_prepass.PreviousGlobalTransform::from_global_transform(
        global_transform.value(),
      ),
    ))
  })
  for entry in missing {
    let (entity, previous_global_transform) = entry
    try! world.set_by_key(
      entity,
      ecs_key_previous_global_transform,
      previous_global_transform,
    )
  }
  sync_state.set(
    Render3dPreviousGlobalTransformSyncState::{
      verified_missing_scan_generation: world.structural_generation(),
    },
  )
}
