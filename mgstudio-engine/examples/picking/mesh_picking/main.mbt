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
struct PickableMesh {
  normal : @asset.Handle[@pbr.StandardMaterial]
  hover : @asset.Handle[@pbr.StandardMaterial]
  pressed : @asset.Handle[@pbr.StandardMaterial]
}

///|
let ecs_key_pickable_mesh : @ecs.ComponentKey[PickableMesh] = @ecs.register_component(
  debug_name="examples.picking.mesh.pickable_mesh",
)

///|
impl @ecs.Component for PickableMesh with component() {
  ecs_key_pickable_mesh
}

///|
let dragging_entity : Ref[@core.Entity?] = Ref::new(None)

///|
let last_drag_position : Ref[@math.Vec2?] = Ref::new(None)

///|
fn spawn_pickable_shape(
  commands : @app.Commands,
  mesh : @asset.Handle[@mesh.Mesh],
  position : @math.Vec3,
  normal : @asset.Handle[@pbr.StandardMaterial],
  hover : @asset.Handle[@pbr.StandardMaterial],
  pressed : @asset.Handle[@pbr.StandardMaterial],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(normal),
        @transform.Transform::from_xyz(position.x, position.y, position.z),
        PickableMesh::{ normal, hover, pressed },
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  let normal = material_assets |> @pbr.add_material(@sprite.Color::white())
  let hover = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.45F, 0.92F, 0.95F))
  let pressed = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.98F, 0.85F, 0.25F))
  let ground = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.8F, 0.8F, 0.8F))

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets |> @pbr.add_mesh(@mesh.Mesh3dGeometry::circle(8.0F, 64)),
        ),
        @pbr.MeshMaterial3d::new(ground),
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_rotation_x(-@math.pi_half()),
        ),
      ),
    ),
  )

  spawn_pickable_shape(
    commands,
    mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(1.1F, 1.1F, 1.1F)),
    @math.Vec3::new(-2.0F, 0.8F, 0.0F),
    normal,
    hover,
    pressed,
  )
  spawn_pickable_shape(
    commands,
    mesh_assets |> @pbr.add_mesh(@math.Sphere::new(0.75F)),
    @math.Vec3::new(0.0F, 0.8F, 0.0F),
    normal,
    hover,
    pressed,
  )
  spawn_pickable_shape(
    commands,
    mesh_assets |> @pbr.add_mesh(@math.Capsule3d::new(0.45F, 1.1F)),
    @math.Vec3::new(2.0F, 0.9F, 0.0F),
    normal,
    hover,
    pressed,
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default()
        .with_shadow_maps_enabled(true)
        .with_intensity(10_000_000.0F),
        @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn set_target_material(
  target : @core.Entity?,
  material_handle : (PickableMesh) -> @asset.Handle[@pbr.StandardMaterial],
  query : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[PickableMesh]),
    @ecs.All,
  ],
) -> Unit {
  guard target is Some(entity) else { return }
  guard (try! query.get(entity)) is Some((mesh_material, pickable)) else {
    return
  }
  mesh_material.get_ref().val = @pbr.MeshMaterial3d::new(
    material_handle(pickable.value()),
  )
}

///|
fn on_pointer_enter(
  pointer : @app.OnPointer[@app.PointerEnter],
  query : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[PickableMesh]),
    @ecs.All,
  ],
) -> Unit {
  set_target_material(pointer.target(), fn(state) { state.hover }, query)
}

///|
fn on_pointer_leave(
  pointer : @app.OnPointer[@app.PointerLeave],
  query : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[PickableMesh]),
    @ecs.All,
  ],
) -> Unit {
  set_target_material(pointer.target(), fn(state) { state.normal }, query)
}

///|
fn on_pointer_down(
  pointer : @app.OnPointer[@app.PointerDown],
  query : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[PickableMesh]),
    @ecs.All,
  ],
) -> Unit {
  guard pointer.target() is Some(entity) else {
    dragging_entity.val = None
    last_drag_position.val = None
    return
  }
  if (try! query.get(entity)) is Some((mesh_material, pickable)) {
    mesh_material.get_ref().val = @pbr.MeshMaterial3d::new(
      pickable.value().pressed,
    )
    dragging_entity.val = Some(entity)
    last_drag_position.val = Some(pointer.position())
  } else {
    dragging_entity.val = None
    last_drag_position.val = None
  }
}

///|
fn on_pointer_up(
  pointer : @app.OnPointer[@app.PointerUp],
  query : @ecs.Query[
    (@ecs.Mut[@pbr.MeshMaterial3d], @ecs.Comp[PickableMesh]),
    @ecs.All,
  ],
) -> Unit {
  set_target_material(pointer.target(), fn(state) { state.hover }, query)
  dragging_entity.val = None
  last_drag_position.val = None
}

///|
fn on_pointer_move_drag(
  pointer : @app.OnPointer[@app.PointerMove],
  transforms : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.All],
) -> Unit {
  guard dragging_entity.val is Some(entity) else { return }
  guard (try! transforms.get(entity)) is Some(transform) else { return }
  let delta = match last_drag_position.val {
    Some(previous) =>
      @math.Vec2::new(
        pointer.position().x - previous.x,
        pointer.position().y - previous.y,
      )
    None => @math.Vec2::new(0.0F, 0.0F)
  }
  transform.get_ref().val.rotate_y(delta.x * 0.02F)
  transform.get_ref().val.rotate(@math.Quat::from_rotation_x(delta.y * 0.02F))
  last_drag_position.val = Some(pointer.position())
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param3(setup)
  .add_pointer_observer2(fn(pointer, query) { on_pointer_enter(pointer, query) })
  .add_pointer_observer2(fn(pointer, query) { on_pointer_leave(pointer, query) })
  .add_pointer_observer2(fn(pointer, query) { on_pointer_down(pointer, query) })
  .add_pointer_observer2(fn(pointer, query) { on_pointer_up(pointer, query) })
  .add_pointer_observer2(fn(pointer, transforms) {
    on_pointer_move_drag(pointer, transforms)
  })
  .run()
}
