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
///
/// Baseline parity: Bevy's per-mesh `Lightmap` component pipeline and UI widget
/// radio buttons are not exposed in current mgstudio runtime surfaces.
/// This port keeps the same four lighting modes, scene source asset,
/// sphere-move interaction, and mode semantics with keyboard-driven mode
/// selection and lighting proxies.

///|
const LIGHTMAP_EXPOSURE : Float = 600.0F

///|
const SPHERE_OFFSET : Float = 0.2F

///|
const PI : Float = 3.141592653589793F

///|
pub(all) enum LightingMode {
  Baked
  MixedDirect
  MixedIndirect
  RealTime
}

///|
priv struct AppStatus {
  mut lighting_mode : LightingMode
  mut camera : @core.Entity?
  mut sphere : @core.Entity?
  mut sphere_material : @asset.Handle[@pbr.StandardMaterial]?
  mut directional_light : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let app_status : Ref[AppStatus] = Ref({
  lighting_mode: LightingMode::MixedIndirect,
  camera: None,
  sphere: None,
  sphere_material: None,
  directional_light: None,
  help_text: None,
})

///|
fn initial_sphere_position() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.5233223F, 0.0F)
}

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
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn lighting_mode_name(mode : LightingMode) -> String {
  match mode {
    LightingMode::Baked => "Baked"
    LightingMode::MixedDirect => "Mixed (Direct)"
    LightingMode::MixedIndirect => "Mixed (Indirect)"
    LightingMode::RealTime => "Real-Time"
  }
}

///|
fn lighting_mode_eq(lhs : LightingMode, rhs : LightingMode) -> Bool {
  match lhs {
    LightingMode::Baked =>
      match rhs {
        LightingMode::Baked => true
        _ => false
      }
    LightingMode::MixedDirect =>
      match rhs {
        LightingMode::MixedDirect => true
        _ => false
      }
    LightingMode::MixedIndirect =>
      match rhs {
        LightingMode::MixedIndirect => true
        _ => false
      }
    LightingMode::RealTime =>
      match rhs {
        LightingMode::RealTime => true
        _ => false
      }
  }
}

///|
fn create_help_text(mode : LightingMode) -> String {
  let details = match mode {
    LightingMode::Baked =>
      "Scenery: Static, baked direct light, baked indirect light\nSphere: Static, baked direct light, baked indirect light"
    LightingMode::MixedDirect =>
      "Scenery: Static, baked direct light, baked indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere"
    LightingMode::MixedIndirect =>
      "Scenery: Static, real-time direct light, baked indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere"
    LightingMode::RealTime =>
      "Scenery: Dynamic, real-time direct light, no indirect light\nSphere: Dynamic, real-time direct light, no indirect light\nClick in the scene to move the sphere"
  }

  "\{details}\n\nControls:\n1: Baked, 2: Mixed (Direct), 3: Mixed (Indirect), 4: Real-Time\nHold left mouse button and point to move sphere\n\nTarget exposure: \{LIGHTMAP_EXPOSURE.to_string()}"
}

///|
fn update_help_text() -> Unit {
  if app_status.val.help_text is Some(help_text) {
    @text.text_set_content(
      help_text,
      "\{create_help_text(app_status.val.lighting_mode)}\n\nCurrent mode: \{lighting_mode_name(app_status.val.lighting_mode)}",
    )
  }
}

///|
fn mode_directional_illuminance(mode : LightingMode) -> Float {
  match mode {
    LightingMode::Baked => 0.0F
    LightingMode::MixedDirect => 12_000.0F
    LightingMode::MixedIndirect => 12_000.0F
    LightingMode::RealTime => 12_000.0F
  }
}

///|
fn mode_ambient_brightness(mode : LightingMode) -> Float {
  match mode {
    LightingMode::Baked => 10_000.0F
    LightingMode::MixedDirect => 6_500.0F
    LightingMode::MixedIndirect => 4_500.0F
    LightingMode::RealTime => 0.0F
  }
}

///|
fn mode_sphere_color(mode : LightingMode) -> @sprite.Color {
  match mode {
    LightingMode::Baked => @sprite.Color::new(0.95F, 0.84F, 0.84F, 1.0F)
    _ => @sprite.Color::new(0.92F, 0.92F, 0.92F, 1.0F)
  }
}

///|
fn apply_lighting_mode(world : @ecs.World) -> Unit {
  let mode = app_status.val.lighting_mode

  let scenery_is_lit_in_real_time = lighting_mode_eq(
      mode,
      LightingMode::MixedIndirect,
    ) ||
    lighting_mode_eq(mode, LightingMode::RealTime)

  if app_status.val.directional_light is Some(light_entity) {
    try! (world.replace(
      light_entity,
      @pbr.ecs_key_directional_light,
      @pbr.DirectionalLight::new(
        @sprite.Color::white(),
        mode_directional_illuminance(mode),
        scenery_is_lit_in_real_time,
      ),
    )
    |> ignore)
  }

  let ambient_light = @pbr.GlobalAmbientLight::new(
    @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    mode_ambient_brightness(mode),
  )
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient_light)

  if app_status.val.sphere_material is Some(handle) {
    if @pbr.standard_material_get(handle) is Some(material) {
      @pbr.standard_material_set(
        handle,
        material.with_base_color(mode_sphere_color(mode)),
      )
      |> ignore
    }
  }
}

///|
fn reset_sphere_position(world : @ecs.World) -> Unit {
  if app_status.val.sphere is Some(sphere_entity) {
    if (try! world.get_by_key(sphere_entity, @transform.ecs_key_transform))
      is Some(transform) {
      try! (world.replace(
        sphere_entity,
        @transform.ecs_key_transform,
        transform.with_translation(initial_sphere_position()),
      )
      |> ignore)
    }
  }
}

///|
fn ray_plane_intersection_ground(
  origin : @math.Vec3,
  direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(direction.y) <= 1.0e-6F {
    return None
  }
  let t = -origin.y / direction.y
  if t < 0.0F {
    return None
  }
  Some(origin.add(direction.mul_scalar(t)))
}

///|
fn move_sphere(world : @ecs.World) -> Unit {
  if lighting_mode_eq(app_status.val.lighting_mode, LightingMode::Baked) {
    return
  }
  if !@input.mouse_button_pressed(@window.MouseButton::Left) {
    return
  }

  guard app_status.val.camera is Some(camera_entity) else { return }
  guard app_status.val.sphere is Some(sphere_entity) else { return }
  guard @input.mouse_position() is Some(screen_pos) else { return }

  guard (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera))
    is Some(camera) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @pbr.ecs_key_projection))
    is Some(projection) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(camera_transform) else {
    return
  }

  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()

  guard @camera.camera_viewport_to_world_ray(
      screen_pos, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((origin, direction)) else {
    return
  }

  guard ray_plane_intersection_ground(origin, direction) is Some(point) else {
    return
  }

  guard (try! world.get_by_key(sphere_entity, @transform.ecs_key_transform))
    is Some(current_transform) else {
    return
  }

  let target = point.add(@math.Vec3::new(0.0F, SPHERE_OFFSET, 0.0F))
  try! (world.replace(
    sphere_entity,
    @transform.ecs_key_transform,
    current_transform.with_translation(target),
  )
  |> ignore)
}

///|
fn set_lighting_mode(mode : LightingMode) -> Bool {
  if lighting_mode_eq(app_status.val.lighting_mode, mode) {
    false
  } else {
    app_status.val.lighting_mode = mode
    true
  }
}

///|
fn update_mode_from_input(world : @ecs.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    changed = set_lighting_mode(LightingMode::Baked)
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    changed = set_lighting_mode(LightingMode::MixedDirect) || changed
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    changed = set_lighting_mode(LightingMode::MixedIndirect) || changed
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    changed = set_lighting_mode(LightingMode::RealTime) || changed
  }

  if changed {
    if lighting_mode_eq(app_status.val.lighting_mode, LightingMode::Baked) {
      reset_sphere_position(world)
    }
    apply_lighting_mode(world)
    update_help_text()
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  app_status.val.lighting_mode = LightingMode::MixedIndirect
  app_status.val.camera = None
  app_status.val.sphere = None
  app_status.val.sphere_material = None
  app_status.val.directional_light = None
  app_status.val.help_text = None

  let asset_server = @asset.AssetServer::new()

  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  app_status.val.camera = Some(camera)

  let scene_root = world.spawn_empty()
  try! world.set_by_key(
    scene_root,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/MixedLightingExample/MixedLightingExample.gltf",
        ),
      ),
    ),
  )

  let sphere_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.92F, 0.92F, 0.92F, 1.0F),
    )
    .with_perceptual_roughness(0.45F)
    .with_metallic(0.0F),
  )
  let sphere = @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.2F, 22, 42),
    @pbr.MeshMaterial3d::new(sphere_material),
    @transform.Transform::from_xyz(
      initial_sphere_position().x,
      initial_sphere_position().y,
      initial_sphere_position().z,
    ),
  ).spawn(world)
  app_status.val.sphere = Some(sphere)
  app_status.val.sphere_material = Some(sphere_material)

  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 12_000.0F, true),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 1.8F, 0.6F).looking_at(
      @math.Vec3::new(0.0F, 0.2F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  app_status.val.directional_light = Some(directional_light)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
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
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  app_status.val.help_text = Some(help_text)

  apply_lighting_mode(world)
  update_help_text()
}

///|
fn update(world : @ecs.World) -> Unit {
  update_mode_from_input(world)
  move_sphere(world)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update))
  .run()
}
