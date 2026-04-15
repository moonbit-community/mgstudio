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
const PI : Float = 3.141592653589793F

///|
struct ShowAxes {
  length_scale : Float
}

///|
struct TransformTracking {
  center : @math.Vec3
  orbit_radius : Float
  height_amplitude : Float
  speed : Float
  phase : Float
  base_scale : @math.Vec3
}

///|
let show_axes_key : @ecs.ComponentKey[ShowAxes] = @ecs.register_component(
  debug_name="examples.gizmos.axes.ShowAxes",
)

///|
let transform_tracking_key : @ecs.ComponentKey[TransformTracking] = @ecs.register_component(
  debug_name="examples.gizmos.axes.TransformTracking",
)

///|
pub impl @ecs.Component for ShowAxes with component() {
  show_axes_key
}

///|
pub impl @ecs.Component for TransformTracking with component() {
  transform_tracking_key
}

///|
fn spawn_axes_cube(
  world : @ecs.World,
  mesh : @asset.Handle[@mesh.Mesh],
  color : @sprite.Color,
  tracking : TransformTracking,
) -> Unit {
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(color),
  )
  let entity = world.spawn_empty()
  let initial_transform = @transform.Transform::from_translation(
    tracking.center,
  ).with_scale(tracking.base_scale)
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        initial_transform,
        ShowAxes::{ length_scale: 0.8F },
        tracking,
      ),
    ),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1200.0F),
  )

  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 1.5F, -8.0F).looking_at(
        @math.Vec3::new(0.0F, -0.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )

  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -PI / 4.0F),
        ),
        @pbr.DirectionalLight::new(@sprite.Color::white(), 7000.0F, true),
      ),
    ),
  )

  let plane = world.spawn_empty()
  let plane_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(20.0F, 0.1F, 20.0F),
  )
  let plane_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.1F, 0.1F, 0.1F)),
  )
  ignore(
    try! world
    .entity_mut(plane)
    .insert(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::from_xyz(0.0F, -2.0F, 0.0F),
      ),
    ),
  )

  let cube_mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(1.0F, 1.0F, 1.0F),
  )
  spawn_axes_cube(world, cube_mesh, @sprite.Color::srgb(0.8F, 0.7F, 0.6F), TransformTracking::{
    center: @math.Vec3::new(-1.2F, -0.6F, 0.0F),
    orbit_radius: 1.4F,
    height_amplitude: 0.7F,
    speed: 0.8F,
    phase: 0.0F,
    base_scale: @math.Vec3::new(1.0F, 1.0F, 1.0F),
  })
  spawn_axes_cube(world, cube_mesh, @sprite.Color::srgb(0.6F, 0.7F, 0.8F), TransformTracking::{
    center: @math.Vec3::new(1.5F, -0.9F, 0.8F),
    orbit_radius: 1.1F,
    height_amplitude: 0.5F,
    speed: 1.15F,
    phase: 1.6F,
    base_scale: @math.Vec3::new(0.5F, 0.5F, 0.5F),
  })
}

///|
fn move_cubes(
  query : @ecs.Query[
    (@ecs.Mut[@transform.Transform], @ecs.Comp[TransformTracking]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  query.for_each(fn(_entity, item) {
    let (transform_mut, tracking_comp) = item
    let tracking = tracking_comp.value()
    let orbit = seconds * tracking.speed + tracking.phase
    let translation = @math.Vec3::new(
      tracking.center.x + @math.cos(orbit) * tracking.orbit_radius,
      tracking.center.y + @math.sin(orbit * 1.3F) * tracking.height_amplitude,
      tracking.center.z + @math.sin(orbit) * tracking.orbit_radius,
    )
    let scale_factor = 1.0F + @math.sin(orbit * 0.8F) * 0.35F
    let scale = @math.Vec3::new(
      tracking.base_scale.x * scale_factor,
      tracking.base_scale.y * (1.0F + @math.cos(orbit * 0.6F) * 0.2F),
      tracking.base_scale.z * (1.0F + @math.sin(orbit * 0.9F) * 0.25F),
    )
    transform_mut.set(
      @transform.Transform::from_translation(translation)
      .with_rotation(@math.Quat::from_rotation_y(orbit))
      .with_scale(scale),
    )
  }) catch {
    _ => ()
  }
}

///|
fn draw_axes(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  query : @ecs.Query[
    (@ecs.Comp[@transform.Transform], @ecs.Comp[ShowAxes]),
    @ecs.All,
  ],
) -> Unit {
  query.for_each(fn(_entity, item) {
    let (transform_comp, show_axes_comp) = item
    let transform = transform_comp.value()
    let show_axes = show_axes_comp.value()
    let length = transform.scale.length() * show_axes.length_scale
    gizmos.axes_3d(transform, length)
  }) catch {
    _ => ()
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_cubes)))
  .add_systems(@app.Update, @app.system(@app.system_param2(draw_axes)))
  .run()
}
