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
fn approx_eq(a : Float, b : Float) -> Bool {
  let delta = if a > b { a - b } else { b - a }
  delta <= 0.0001F
}

///|
test "render3d preupdate sync: writes previous view and global transform" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  let camera_transform = @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F)
  try! (world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d::Camera3d())
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity, @transform.ecs_key_transform, camera_transform,
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  |> ignore)

  let mesh_entity = world.spawn()
  let mesh_transform = @transform.Transform::from_xyz(4.0F, 5.0F, 6.0F)
  try! (world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(1)),
  )
  |> ignore)
  try! (world.set_by_key(
    mesh_entity, @transform.ecs_key_transform, mesh_transform,
  )
  |> ignore)
  try! (world.set_by_key(
    mesh_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(mesh_transform),
  )
  |> ignore)

  update_mesh_previous_global_transforms(world)
  update_previous_view_data(world)

  let previous_view_data : @pbr_prepass.PreviousViewData? = try! world.get_by_key(
    camera_entity, ecs_key_previous_view_data,
  )
  inspect(previous_view_data is Some(_), content="true")
  match previous_view_data {
    Some(value) => {
      let synced_transform = value.transform()
      inspect(
        approx_eq(
          synced_transform.translation.x,
          camera_transform.translation.x,
        ),
        content="true",
      )
      inspect(
        approx_eq(
          synced_transform.translation.y,
          camera_transform.translation.y,
        ),
        content="true",
      )
      inspect(
        approx_eq(
          synced_transform.translation.z,
          camera_transform.translation.z,
        ),
        content="true",
      )
    }
    None => ()
  }

  let previous_global_transform : @pbr_prepass.PreviousGlobalTransform? = try! world.get_by_key(
    mesh_entity, ecs_key_previous_global_transform,
  )
  inspect(previous_global_transform is Some(_), content="true")
  match previous_global_transform {
    Some(value) => {
      let synced_transform = value.transform()
      inspect(
        approx_eq(synced_transform.translation.x, mesh_transform.translation.x),
        content="true",
      )
      inspect(
        approx_eq(synced_transform.translation.y, mesh_transform.translation.y),
        content="true",
      )
      inspect(
        approx_eq(synced_transform.translation.z, mesh_transform.translation.z),
        content="true",
      )
    }
    None => ()
  }
}

///|
test "render3d preupdate sync: mesh sync is gated by active camera" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  try! (world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d::Camera3d())
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
    ),
  )
  |> ignore)

  let mesh_entity = world.spawn()
  try! (world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(2)),
  )
  |> ignore)
  try! (world.set_by_key(
    mesh_entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
  )
  |> ignore)
  try! (world.set_by_key(
    mesh_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(9.0F, 8.0F, 7.0F),
    ),
  )
  |> ignore)

  update_mesh_previous_global_transforms(world)
  update_previous_view_data(world)
  let not_synced : @pbr_prepass.PreviousGlobalTransform? = try! world.get_by_key(
    mesh_entity, ecs_key_previous_global_transform,
  )
  inspect(not_synced is None, content="true")

  try! (world.replace(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)

  update_mesh_previous_global_transforms(world)
  update_previous_view_data(world)
  let synced : @pbr_prepass.PreviousGlobalTransform? = try! world.get_by_key(
    mesh_entity, ecs_key_previous_global_transform,
  )
  inspect(synced is Some(_), content="true")
}

///|
test "render3d preupdate sync: existing previous transform updates only after global transform changes" {
  let world = @ecs.World::new()
  defer world.close()
  let camera_entity = world.spawn()
  try! (world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d::Camera3d())
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
    ),
  )
  |> ignore)

  let mesh_entity = world.spawn()
  let initial_transform = @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F)
  try! (world.set_by_key(
    mesh_entity,
    ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(3)),
  )
  |> ignore)
  try! (world.set_by_key(
    mesh_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(initial_transform),
  )
  |> ignore)

  update_mesh_previous_global_transforms(world)
  let first_previous = match
    (try! world.get_mut(mesh_entity, key=ecs_key_previous_global_transform)) {
    Some(value) => value
    None => abort("expected inserted PreviousGlobalTransform")
  }
  let first_changed = first_previous.last_changed()

  update_mesh_previous_global_transforms(world)
  let second_previous = match
    (try! world.get_mut(mesh_entity, key=ecs_key_previous_global_transform)) {
    Some(value) => value
    None => abort("expected retained PreviousGlobalTransform")
  }
  let second_changed = second_previous.last_changed()
  inspect(first_changed == second_changed, content="true")

  let updated_transform = @transform.Transform::from_xyz(7.0F, 8.0F, 9.0F)
  ignore(world.increment_change_tick())
  ignore(world.increment_change_tick())
  try! (world.replace(
    mesh_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(updated_transform),
  )
  |> ignore)
  update_mesh_previous_global_transforms(world)
  let third_previous = match
    (try! world.get_mut(mesh_entity, key=ecs_key_previous_global_transform)) {
    Some(value) => value
    None => abort("expected updated PreviousGlobalTransform")
  }
  let third_changed = third_previous.last_changed()
  inspect(third_changed != second_changed, content="true")
  let third_transform = third_previous.value().transform()
  inspect(
    approx_eq(third_transform.translation.x, updated_transform.translation.x),
    content="true",
  )
  inspect(
    approx_eq(third_transform.translation.y, updated_transform.translation.y),
    content="true",
  )
  inspect(
    approx_eq(third_transform.translation.z, updated_transform.translation.z),
    content="true",
  )
}
