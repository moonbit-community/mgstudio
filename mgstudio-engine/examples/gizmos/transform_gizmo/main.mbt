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
// Bevy source: `bevy/examples/gizmos/transform_gizmo.rs`.
//
// Interactive transform gizmo example.
// - Click an object to select it (primary mouse button)
// - 1 = Translate, 2 = Rotate, 3 = Scale
// - X = Toggle World/Local space

///|
fn cuboid_mesh_handle(x : Float, y : Float, z : Float) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.cuboid_mesh(@math.Cuboid::new(x, y, z)),
        ),
      )
    }),
  )
}

///|
fn solid_material(
  color : @color.Color,
) -> @pbr.MeshMaterial3dTyped[@pbr.StandardMaterial] {
  @pbr.MeshMaterial3dTyped::new(
    @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color)),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  // Ground plane (not pickable). Bevy uses `Plane3d::default().mesh().size(10, 10)`.
  let ground = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets.add(
          @mesh.Mesh::from_3d_geometry(
            @mesh_primitives_dim3.plane3d_mesh_from_size(10.0F, 10.0F, 0),
          ),
        )
      }),
    ),
    solid_material(@color.Color::srgb(0.3F, 0.3F, 0.3F)),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    ground,
    @picking.ecs_key_pickable,
    @picking.Pickable::new(false, false),
  )

  // Table: a parent body with child legs, demonstrating local versus world
  // space. The parent cube is selected by default.
  let table = @pbr.MeshMaterial3dBundle::new(
    cuboid_mesh_handle(1.5F, 0.15F, 1.0F),
    solid_material(@color.Color::srgb(0.8F, 0.3F, 0.3F)),
    @transform.Transform::from_xyz(-2.0F, 1.0F, 0.0F),
  ).spawn(world)
  try! world.set_by_key(
    table,
    @gizmos.ecs_key_transform_gizmo_focus,
    @gizmos.TransformGizmoFocus::TransformGizmoFocus(),
  )
  let leg_offsets = [(-0.6F, 0.4F), (0.6F, 0.4F), (-0.6F, -0.4F), (0.6F, -0.4F)]
  for offset in leg_offsets {
    let leg = @pbr.MeshMaterial3dBundle::new(
      cuboid_mesh_handle(0.1F, 0.85F, 0.1F),
      solid_material(@color.Color::srgb(0.6F, 0.2F, 0.2F)),
      @transform.Transform::from_xyz(offset.0, -0.5F, offset.1),
    ).spawn(world)
    try! world.set_by_key(
      leg,
      @picking.ecs_key_pickable,
      @picking.Pickable::new(false, false),
    )
    try! world.set_by_key(
      leg,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(table),
    )
  }

  // Standalone cube.
  ignore(
    @pbr.MeshMaterial3dBundle::new(
      cuboid_mesh_handle(1.0F, 1.0F, 1.0F),
      solid_material(@color.Color::srgb(0.3F, 0.8F, 0.3F)),
      @transform.Transform::from_xyz(2.0F, 0.5F, 0.0F),
    ).spawn(world),
  )

  // Light.
  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::DirectionalLight(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_rotation(
      @math.Quat::from_euler(XYZ, -0.8F, 0.4F, 0.0F),
    ),
  )

  // Camera.
  let camera = @camera.Camera3dBundle::new(
    @camera_camera.Camera::Camera(),
    @transform.Transform::from_xyz(0.0F, 4.0F, 8.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    camera,
    @gizmos.ecs_key_transform_gizmo_camera,
    @gizmos.TransformGizmoCamera::TransformGizmoCamera(),
  )
}

///|
// Note: 1/2/3 instead of Blender's G/R/S because S conflicts with the free
// camera's WASD movement controls.
fn gizmo_mode_keys(world : @ecs.World) -> Unit {
  guard world.get_resource(@gizmos.ecs_res_key_transform_gizmo_settings)
    is Some(settings) else {
    return
  }
  let mut next = settings
  if @input.key_just_pressed(Digit1) {
    next = { ..next, mode: Translate }
  }
  if @input.key_just_pressed(Digit2) {
    next = { ..next, mode: Rotate }
  }
  if @input.key_just_pressed(Digit3) {
    next = { ..next, mode: Scale }
  }
  if @input.key_just_pressed(KeyX) {
    let flipped : @gizmos.TransformGizmoSpace = match next.space {
      World => Local
      Local => World
    }
    next = { ..next, space: flipped }
  }
  world.insert_resource(@gizmos.ecs_res_key_transform_gizmo_settings, next)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@mesh_picking_plugin.MeshPickingPlugin::MeshPickingPlugin())
  .add_plugins(@gizmos.TransformGizmoPlugin::TransformGizmoPlugin())
  .add_systems_world(Startup, setup)
  .add_systems_world(Update, gizmo_mode_keys)
  .run()
}
