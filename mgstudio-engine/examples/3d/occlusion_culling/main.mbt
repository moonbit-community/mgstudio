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
/// Port of `bevy/examples/3d/occlusion_culling.rs`.
///
/// Baseline parity: Bevy reads indirect draw parameters back from GPU to
/// display exact culled counts. Current mgstudio runtime exposes an adapted
/// approximation based on scene-space heuristics while preserving Space toggle,
/// camera-side `DepthPrepass`/`OcclusionCulling` API surfaces, and scene motion.

///|
const PI : Float = 3.141592653589793F

///|
const TWO_PI : Float = 6.283185307179586F

///|
const OUTER_RADIUS : Float = 3.0F

///|
const OUTER_SUBDIVISION_COUNT : Int = 5

///|
const ROTATION_SPEED : Float = 0.01F

///|
const SMALL_CUBE_SIZE : Float = 0.1F

///|
const LARGE_CUBE_SIZE : Float = 2.0F

///|
priv struct SmallCube {
  entity : @core.Entity
  local_position : @math.Vec3
}

///|
priv struct OcclusionState {
  mut occlusion_enabled : Bool
  mut sphere_angle : Float
  mut camera : @core.Entity?
  mut large_cube : @core.Entity?
  mut rendered_count : Int
  mut culled_count : Int
  small_cubes : Array[SmallCube]
  mut help_text : @text.TextHandle?
}

///|
fn default_state() -> OcclusionState {
  {
    occlusion_enabled: true,
    sphere_angle: 0.0F,
    camera: None,
    large_cube: None,
    rendered_count: 0,
    culled_count: 0,
    small_cubes: [],
    help_text: None,
  }
}

///|
let occlusion_state : Ref[OcclusionState] = Ref::new(default_state())

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn rotate_y(v : @math.Vec3, angle : Float) -> @math.Vec3 {
  let c = @math.cos(angle)
  let s = @math.sin(angle)
  @math.Vec3::new(v.x * c - v.z * s, v.y, v.x * s + v.z * c)
}

///|
fn approximate_occluded(world_pos : @math.Vec3) -> Bool {
  if world_pos.z >= 0.0F {
    return false
  }
  let half = LARGE_CUBE_SIZE * 0.65F
  absf(world_pos.x) < half && absf(world_pos.y) < half
}

///|
fn help_text_content() -> String {
  let status = if occlusion_state.val.occlusion_enabled { "ON" } else { "OFF" }
  let total = occlusion_state.val.small_cubes.length() + 1
  "Occlusion culling \{status} (Press Space to toggle)\n" +
  "\{occlusion_state.val.rendered_count}/\{total} meshes rendered\n" +
  "Approx culled meshes: \{occlusion_state.val.culled_count}\n\n" +
  "Adapted note: Bevy's GPU indirect-parameter readback APIs are unavailable."
}

///|
fn update_help_text() -> Unit {
  if occlusion_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text_content())
  }
}

///|
fn recompute_counts() -> Unit {
  let mut culled = 0
  for i in 0..<occlusion_state.val.small_cubes.length() {
    let cube = occlusion_state.val.small_cubes[i]
    let world_pos = rotate_y(
      cube.local_position,
      occlusion_state.val.sphere_angle,
    )
    if occlusion_state.val.occlusion_enabled && approximate_occluded(world_pos) {
      culled = culled + 1
    }
  }
  occlusion_state.val.culled_count = culled
  let total = occlusion_state.val.small_cubes.length() + 1
  occlusion_state.val.rendered_count = if occlusion_state.val.occlusion_enabled {
    total - culled
  } else {
    total
  }
}

///|
fn spawn_small_cubes(
  world : @ecs.World,
  material : @asset.Handle[@pbr.StandardMaterial],
) -> Unit {
  let mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @pbr.mesh3d_geometry_cuboid(
          SMALL_CUBE_SIZE,
          SMALL_CUBE_SIZE,
          SMALL_CUBE_SIZE,
        ),
      ),
    ),
  )
  let lat_steps = OUTER_SUBDIVISION_COUNT * 2
  let lon_steps = OUTER_SUBDIVISION_COUNT * 4

  for lat in 0..<(lat_steps + 1) {
    let lat_f = float_from_int(lat)
    let lat_steps_f = float_from_int(lat_steps)
    let phi = -PI / 2.0F + PI * lat_f / lat_steps_f
    let y = OUTER_RADIUS * @math.sin(phi)
    let ring = OUTER_RADIUS * @math.cos(phi)
    for lon in 0..<lon_steps {
      let lon_f = float_from_int(lon)
      let lon_steps_f = float_from_int(lon_steps)
      let theta = TWO_PI * lon_f / lon_steps_f
      let local_position = @math.Vec3::new(
        ring * @math.cos(theta),
        y,
        ring * @math.sin(theta),
      )
      let entity = @pbr.MeshMaterial3dBundle::new(
        mesh,
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(
          local_position.x,
          local_position.y,
          local_position.z,
        ),
      ).spawn(world)
      occlusion_state.val.small_cubes.push({ entity, local_position })
    }
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  occlusion_state.val = default_state()
  let asset_server = @asset.AssetServer::new()

  let small_cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  spawn_small_cubes(world, small_cube_material)

  let large_cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::default().with_base_color_texture(
      Some(asset_server.load("branding/icon.png")),
    ),
  )
  let large_cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(
            LARGE_CUBE_SIZE,
            LARGE_CUBE_SIZE,
            LARGE_CUBE_SIZE,
          ),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(large_cube_material),
    @transform.Transform::identity(),
  ).spawn(world)
  occlusion_state.val.large_cube = Some(large_cube)

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::default(),
  )
  let light_rot = @math.Quat::from_rotation_y(-0.15F * PI).mul(
    @math.Quat::from_rotation_x(-0.15F * PI),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_rotation(light_rot),
  )

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 0.0F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  occlusion_state.val.camera = Some(camera)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_depth_prepass,
    @pbr.DepthPrepass::default(),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_occlusion_culling,
    @pbr.OcclusionCulling::default(),
  )

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  occlusion_state.val.help_text = Some(help_text)

  recompute_counts()
  update_help_text()
}

///|
fn spin_small_cubes(world : @ecs.World) -> Unit {
  occlusion_state.val.sphere_angle = occlusion_state.val.sphere_angle +
    ROTATION_SPEED
  for i in 0..<occlusion_state.val.small_cubes.length() {
    let cube = occlusion_state.val.small_cubes[i]
    let position = rotate_y(
      cube.local_position,
      occlusion_state.val.sphere_angle,
    )
    try! (world.replace(
      cube.entity,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(position.x, position.y, position.z),
    )
    |> ignore)
  }
}

///|
fn spin_large_cube(world : @ecs.World) -> Unit {
  guard occlusion_state.val.large_cube is Some(large_cube) else { return }
  guard (try! world.get_by_key(large_cube, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let speed = ROTATION_SPEED
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_x(0.13F * speed))
    .mul(@math.Quat::from_rotation_y(0.29F * speed))
    .mul(@math.Quat::from_rotation_z(0.35F * speed))
    .normalize()
  try! (world.replace(
    large_cube,
    @transform.ecs_key_transform,
    transform.with_rotation(rotation),
  )
  |> ignore)
}

///|
fn toggle_occlusion_culling_on_request(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  occlusion_state.val.occlusion_enabled = !occlusion_state.val.occlusion_enabled
  if occlusion_state.val.camera is Some(camera) {
    if occlusion_state.val.occlusion_enabled {
      try! world.set_by_key(
        camera,
        @pbr.ecs_key_occlusion_culling,
        @pbr.OcclusionCulling::default(),
      )
    } else {
      try! (world.take(camera, @pbr.ecs_key_occlusion_culling) |> ignore)
    }
  }
  recompute_counts()
  update_help_text()
}

///|
fn update_status_text(world : @ecs.World) -> Unit {
  world |> ignore
  recompute_counts()
  update_help_text()
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(spin_small_cubes))
  .add_systems(@app.Update, @app.system(spin_large_cube))
  .add_systems(@app.Update, @app.system(update_status_text))
  .add_systems(@app.Update, @app.system(toggle_occlusion_culling_on_request))
  .run()
}
