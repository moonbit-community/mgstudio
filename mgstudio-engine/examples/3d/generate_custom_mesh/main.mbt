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
/// Port of `bevy/examples/3d/generate_custom_mesh.rs`.

///|
priv struct CustomMeshState {
  mut mesh_entity : @core.Entity?
  mut upper_uv : Bool
}

///|
let custom_mesh_state : Ref[CustomMeshState] = Ref::new({
  mesh_entity: None,
  upper_uv: true,
})

///|
fn create_cube_positions() -> Array[@math.Vec3] {
  [
    // Top (+y)
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    // Bottom (-y)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    // Right (+x)
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    // Left (-x)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    // Back (+z)
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    // Forward (-z)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
  ]
}

///|
fn create_cube_uvs(upper_uv : Bool) -> Array[@math.Vec2] {
  let y_offset = if upper_uv { 0.0F } else { 0.5F }
  [
    // Top (+y)
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(0.0F, 0.0F + y_offset),
    @math.Vec2::new(1.0F, 0.0F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Bottom (-y)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.25F + y_offset),
    @math.Vec2::new(1.0F, 0.25F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    // Right (+x)
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Left (-x)
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Back (+z)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    // Forward (-z)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
  ]
}

///|
fn create_cube_indices() -> Array[Int] {
  [
    0, 3, 1, 1, 3, 2, 4, 5, 7, 5, 6, 7, 8, 11, 9, 9, 11, 10, 12, 13, 15, 13, 14,
    15, 16, 19, 17, 17, 19, 18, 20, 21, 23, 21, 22, 23,
  ]
}

///|
fn create_cube_mesh(upper_uv : Bool) -> @pbr.Mesh3d {
  @pbr.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(
      create_cube_positions(),
      create_cube_uvs(upper_uv),
      Some(create_cube_indices()),
    ),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  custom_mesh_state.val.mesh_entity = None
  custom_mesh_state.val.upper_uv = true

  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()

  let custom_texture = asset_server.load("textures/array_texture.png")
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default().with_base_color_texture(
      Some(custom_texture),
    ),
  )

  let mesh_entity = @pbr.MeshMaterial3dBundle::new(
    create_cube_mesh(true),
    @pbr.MeshMaterial3d::new(material),
    @math.Transform::identity(),
  ).spawn(world)
  custom_mesh_state.val.mesh_entity = Some(mesh_entity)

  let camera_and_light_transform = @math.Transform::from_xyz(1.8F, 1.8F, 1.8F).looking_at(
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    camera_and_light_transform,
  ).spawn(world)
  |> ignore

  let light_entity = world.spawn_empty()
  world
  .component(@pbr.ecs_key_point_light)
  .insert(light_entity, @pbr.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light_entity, camera_and_light_transform, tick)

  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  @text.Text2dBundle::new(
    @text.Text2d::new(
      "Controls:\nSpace: Change UVs\nX/Y/Z: Rotate\nR: Reset orientation",
    ),
    @text.TextFont::default().with_font(overlay_font).with_font_size(20.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-390.0F, 300.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@sprite.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(780.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
}

///|
fn input_handler(world : @ecs.World) -> Unit {
  guard custom_mesh_state.val.mesh_entity is Some(mesh_entity) else { return }

  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)

  if @input.key_just_pressed(@window.KeyCode::Space) {
    let next_upper_uv = !custom_mesh_state.val.upper_uv
    custom_mesh_state.val.upper_uv = next_upper_uv
    let next_mesh = create_cube_mesh(next_upper_uv)
    let next_mesh_id = @sprite.render2d_upload_mesh_handle(next_mesh.mesh)
    world.component(@pbr.ecs_key_mesh3d).set(mesh_entity, next_mesh, tick)
    |> ignore
    world
    .component(@sprite.ecs_key_gpu_mesh2d)
    .set(mesh_entity, @sprite.GpuMesh2d::new(next_mesh_id), tick)
    |> ignore
  }

  if transform_store.get(mesh_entity) is Some(transform) {
    if @input.key_pressed(@window.KeyCode::KeyR) {
      transform_store.set(
        mesh_entity,
        transform.with_rotation(@math.Quat::identity()),
        tick,
      )
      |> ignore
      return
    }

    let delta = @time.time_delta_seconds() / 1.2F
    let mut rotation = transform.rotation
    let mut changed = false

    if @input.key_pressed(@window.KeyCode::KeyX) {
      rotation = rotation.mul(@math.Quat::from_rotation_x(delta)).normalize()
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyY) {
      rotation = rotation.mul(@math.Quat::from_rotation_y(delta)).normalize()
      changed = true
    }
    if @input.key_pressed(@window.KeyCode::KeyZ) {
      rotation = rotation.mul(@math.Quat::from_rotation_z(delta)).normalize()
      changed = true
    }

    if changed {
      transform_store.set(mesh_entity, transform.with_rotation(rotation), tick)
      |> ignore
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(input_handler))
  .run()
}
