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
/// Port of `bevy/examples/3d/tonemapping.rs`.
///
/// Baseline parity: Bevy's native tonemapping/color-grading pipeline
/// (`Tonemapping`, `ColorGrading`, HDR camera setup) is mapped directly to
/// mgstudio camera components; drag-drop HDR/EXR loading and custom
/// shader-material gradient remain adapted.

///|
const PI : Float = 3.141592653589793F

///|
const METHOD_COUNT : Int = 8

///|
const PARAMETER_COUNT : Int = 4

///|
const CAMERA_HEIGHT : Float = 0.7F

///|
priv struct ColorGradeSettings {
  exposure : Float
  gamma : Float
  pre_saturation : Float
  post_saturation : Float
}

///|
priv struct SceneEntity {
  entity : @core.Entity
  scene : Int
}

///|
priv struct TonemappingState {
  mut current_scene : Int
  mut tonemap_mode : Int
  mut selected_parameter : Int
  mut hide_ui : Bool
  mut ui_text : @text.TextHandle?
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  scene_entities : Array[SceneEntity]
  settings : Array[ColorGradeSettings]
}

///|
let tonemapping_state : Ref[TonemappingState] = Ref::new({
  current_scene: 1,
  tonemap_mode: 6,
  selected_parameter: 0,
  hide_ui: false,
  ui_text: None,
  camera: None,
  directional_light: None,
  point_light: None,
  scene_entities: [],
  settings: [],
})

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn default_color_grading() -> ColorGradeSettings {
  { exposure: 0.0F, gamma: 1.0F, pre_saturation: 1.0F, post_saturation: 1.0F }
}

///|
fn basic_scene_recommendation(mode : Int) -> ColorGradeSettings {
  if mode == 1 || mode == 2 {
    { exposure: 0.5F, gamma: 1.0F, pre_saturation: 1.0F, post_saturation: 1.0F }
  } else if mode == 3 {
    {
      exposure: 0.35F,
      gamma: 1.0F,
      pre_saturation: 1.0F,
      post_saturation: 1.0F,
    }
  } else if mode == 4 {
    {
      exposure: -0.2F,
      gamma: 1.0F,
      pre_saturation: 1.1F,
      post_saturation: 1.1F,
    }
  } else {
    default_color_grading()
  }
}

///|
fn build_recommended_settings() -> Array[ColorGradeSettings] {
  let settings : Array[ColorGradeSettings] = []
  for i in 0..<METHOD_COUNT {
    settings.push(basic_scene_recommendation(i))
  }
  settings
}

///|
fn method_name(mode : Int) -> String {
  if mode == 0 {
    "Disabled"
  } else if mode == 1 {
    "Reinhard"
  } else if mode == 2 {
    "Reinhard Luminance"
  } else if mode == 3 {
    "ACES Fitted"
  } else if mode == 4 {
    "AgX"
  } else if mode == 5 {
    "SomewhatBoringDisplayTransform"
  } else if mode == 6 {
    "TonyMcMapface"
  } else {
    "Blender Filmic"
  }
}

///|
fn tonemapping_mode(mode : Int) -> @render3d.Tonemapping {
  if mode == 0 {
    @render3d.Tonemapping::None
  } else if mode == 1 {
    @render3d.Tonemapping::Reinhard
  } else if mode == 2 {
    @render3d.Tonemapping::ReinhardLuminance
  } else if mode == 3 {
    @render3d.Tonemapping::AcesFitted
  } else if mode == 4 {
    @render3d.Tonemapping::AgX
  } else if mode == 5 {
    @render3d.Tonemapping::SomewhatBoringDisplayTransform
  } else if mode == 6 {
    @render3d.Tonemapping::TonyMcMapface
  } else {
    @render3d.Tonemapping::BlenderFilmic
  }
}

///|
fn color_grading_from_settings(
  settings : ColorGradeSettings,
) -> @render3d.ColorGrading {
  let global = @render3d.ColorGradingGlobal::new()
    .with_exposure(settings.exposure)
    .with_post_saturation(settings.post_saturation)
  let section = @render3d.ColorGradingSection::new()
    .with_gamma(settings.gamma)
    .with_saturation(settings.pre_saturation)
  @render3d.ColorGrading::new(
    global,
    @render3d.ColorGradingSettings::with_identical_sections(section),
  )
}

///|
fn selected_marker(value : Int, selected : Int) -> String {
  if value == selected {
    "> "
  } else {
    ""
  }
}

///|
fn register_scene_entity(
  world : @ecs_world.World,
  entity : @core.Entity,
  scene : Int,
) -> Unit {
  let tick = world.read_change_tick()
  world
  .get_visibility_store()
  .insert(
    entity,
    if scene == tonemapping_state.val.current_scene {
      @visibility.Visibility::Inherited
    } else {
      @visibility.Visibility::Hidden
    },
    tick,
  )
  tonemapping_state.val.scene_entities.push({ entity, scene })
}

///|
fn spawn_scene_mesh(
  world : @ecs_world.World,
  scene : Int,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  let entity = @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  register_scene_entity(world, entity, scene)
}

///|
fn setup_scene_basic(world : @ecs_world.World) -> Unit {
  let scene = 1

  let floor_color = @render2d.Color::new(0.16F, 0.16F, 0.18F, 1.0F)
  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(floor_color)
    .with_perceptual_roughness(0.85F)
    .with_reflectance(0.3F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_plane(2.8F, 2.8F),
    floor_material,
    @math.Transform::from_xyz(0.0F, -0.12F, 0.0F),
  )

  for i in 0..<8 {
    let i_f = float_from_int(i)
    let x = -0.98F + i_f * 0.28F
    let emission = 0.8F + i_f * i_f * 0.25F
    let r = clamp01(0.12F + i_f * 0.12F)
    let g = clamp01(0.95F - i_f * 0.09F)
    let b = clamp01(0.25F + i_f * 0.07F)
    let bar_color = @render2d.Color::new(r, g, b, 1.0F)

    let bar_material = @render3d.standard_material_add(
      @render3d.StandardMaterial::from_color(bar_color)
      .with_unlit(true)
      .with_emissive(
        @render2d.Color::new(
          bar_color.r * emission,
          bar_color.g * emission,
          bar_color.b * emission,
          1.0F,
        ),
      )
      .with_perceptual_roughness(0.2F),
    )
    spawn_scene_mesh(
      world,
      scene,
      @render3d.Mesh3d::from_cuboid(0.2F, 0.75F, 0.22F),
      bar_material,
      @math.Transform::from_xyz(x, 0.28F, -0.28F),
    )
  }

  let sphere_color = @render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)
  let sphere_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(sphere_color)
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.15F)
    .with_reflectance(0.7F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_tetrahedron(0.18F),
    sphere_material,
    @math.Transform::from_xyz(-0.45F, 0.22F, 0.38F).with_rotation(
      @math.Quat::from_rotation_y(PI / 4.0F),
    ),
  )

  let sphere_2_color = @render2d.Color::new(0.22F, 0.82F, 0.58F, 1.0F)
  let sphere_2_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(sphere_2_color)
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.35F)
    .with_reflectance(0.5F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_tetrahedron(0.17F),
    sphere_2_material,
    @math.Transform::from_xyz(0.44F, 0.2F, 0.38F).with_rotation(
      @math.Quat::from_rotation_x(PI / 5.0F),
    ),
  )
}

///|
fn setup_scene_color_sweep(world : @ecs_world.World) -> Unit {
  let scene = 2
  let rows = 6
  let cols = 10

  for row in 0..<rows {
    for col in 0..<cols {
      let u = float_from_int(col) / float_from_int(cols - 1)
      let v = float_from_int(row) / float_from_int(rows - 1)
      let r = clamp01(u)
      let g = clamp01(v)
      let b = clamp01(1.0F - u * 0.85F + v * 0.15F)
      let color = @render2d.Color::new(r, g, b, 1.0F)

      let mat = @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(color)
        .with_unlit(true)
        .with_perceptual_roughness(0.4F),
      )

      let x = -0.9F + float_from_int(col) * 0.2F
      let y = -0.04F + float_from_int(row) * 0.12F
      spawn_scene_mesh(
        world,
        scene,
        @render3d.Mesh3d::from_cuboid(0.18F, 0.11F, 0.14F),
        mat,
        @math.Transform::from_xyz(x, y, 0.0F),
      )
    }
  }

  let panel_color = @render2d.Color::new(0.05F, 0.05F, 0.06F, 1.0F)
  let panel = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(panel_color)
    .with_perceptual_roughness(1.0F)
    .with_reflectance(0.2F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_cuboid(2.2F, 1.15F, 0.06F),
    panel,
    @math.Transform::from_xyz(0.0F, 0.3F, -0.1F),
  )
}

///|
fn setup_scene_image_viewer(world : @ecs_world.World) -> Unit {
  let scene = 3
  let asset_server = @asset.AssetServer::new()
  let logo_texture = asset_server.load("branding/bevy_logo_dark_big.png")

  let image_color = @render2d.Color::white()
  let image_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(image_color)
    .with_base_color_texture(Some(logo_texture))
    .with_unlit(true)
    .with_alpha_mode(@render3d.AlphaMode3d::Blend),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_cuboid(1.45F, 0.75F, 0.02F),
    image_material,
    @math.Transform::from_xyz(0.0F, 0.34F, 0.04F),
  )

  let frame_color = @render2d.Color::new(0.08F, 0.08F, 0.08F, 1.0F)
  let frame_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(frame_color)
    .with_perceptual_roughness(0.8F)
    .with_reflectance(0.2F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_cuboid(1.55F, 0.85F, 0.05F),
    frame_material,
    @math.Transform::from_xyz(0.0F, 0.34F, -0.02F),
  )

  let floor_color = @render2d.Color::new(0.14F, 0.14F, 0.16F, 1.0F)
  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(floor_color)
    .with_perceptual_roughness(0.9F)
    .with_reflectance(0.25F),
  )
  spawn_scene_mesh(
    world,
    scene,
    @render3d.Mesh3d::from_plane(2.4F, 2.4F),
    floor_material,
    @math.Transform::from_xyz(0.0F, -0.13F, 0.0F),
  )
}

///|
fn setup_lights(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let directional = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    directional,
    @math.Transform::from_xyz(2.5F, 4.0F, 2.5F).looking_at(
      @math.Vec3::new(0.0F, 0.2F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    directional,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  tonemapping_state.val.directional_light = Some(directional)

  let point = world.spawn_empty()
  world
  .get_transform_store()
  .insert(point, @math.Transform::from_xyz(-0.6F, 1.3F, 1.2F), tick)
  world
  .get_point_light_store()
  .insert(
    point,
    @render3d.PointLight::new(
      @render2d.Color::new(1.0F, 0.9F, 0.8F, 1.0F),
      2_000.0F,
      8.0F,
      true,
    ),
    tick,
  )
  tonemapping_state.val.point_light = Some(point)
}

///|
fn setup_camera(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.7F, CAMERA_HEIGHT, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)

  let tick = world.read_change_tick()
  world.get_hdr_store().insert(camera, @render3d.Hdr::default(), tick)
  world
  .get_environment_map_light_store()
  .insert(
    camera,
    @render3d.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
    tick,
  )
  tonemapping_state.val.camera = Some(camera)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F, 1.0F),
      @render3d.FogFalloff3d::linear(1.0F, 8.0F),
    ),
  )
}

///|
fn ui_text_content() -> String {
  let state = tonemapping_state.val
  let settings = state.settings[state.tonemap_mode]

  let mut content = "(H) Hide UI\n\n" +
    "Test Scene:\n" +
    "(Q) " +
    selected_marker(1, state.current_scene) +
    "Basic Scene\n" +
    "(W) " +
    selected_marker(2, state.current_scene) +
    "Color Sweep\n" +
    "(E) " +
    selected_marker(3, state.current_scene) +
    "Image Viewer\n\n" +
    "Tonemapping Method:\n" +
    "(1) " +
    selected_marker(0, state.tonemap_mode) +
    "Disabled\n" +
    "(2) " +
    selected_marker(1, state.tonemap_mode) +
    "Reinhard\n" +
    "(3) " +
    selected_marker(2, state.tonemap_mode) +
    "Reinhard Luminance\n" +
    "(4) " +
    selected_marker(3, state.tonemap_mode) +
    "ACES Fitted\n" +
    "(5) " +
    selected_marker(4, state.tonemap_mode) +
    "AgX\n" +
    "(6) " +
    selected_marker(5, state.tonemap_mode) +
    "SomewhatBoringDisplayTransform\n" +
    "(7) " +
    selected_marker(6, state.tonemap_mode) +
    "TonyMcMapface\n" +
    "(8) " +
    selected_marker(7, state.tonemap_mode) +
    "Blender Filmic\n\n" +
    "Color Grading (Arrow Up/Down select, Left/Right adjust):\n" +
    selected_marker(0, state.selected_parameter) +
    "Exposure: \{settings.exposure}\n" +
    selected_marker(1, state.selected_parameter) +
    "Gamma: \{settings.gamma}\n" +
    selected_marker(2, state.selected_parameter) +
    "PreSaturation: \{settings.pre_saturation}\n" +
    selected_marker(3, state.selected_parameter) +
    "PostSaturation: \{settings.post_saturation}\n" +
    "(Space) Reset all methods to default\n"

  if state.current_scene == 1 {
    content = content + "(Enter) Reset all methods to scene recommendation\n"
  }

  if state.current_scene == 3 {
    content = content +
      "Image viewer note: HDR/EXR drag-drop is not available in current mgstudio runtime.\n"
  }

  content = content + "\nActive Method: " + method_name(state.tonemap_mode)
  content
}

///|
fn setup_ui(_world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(ui_text_content()),
      @text.TextFont::default().with_font(font).with_font_size(15.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()
  tonemapping_state.val.ui_text = Some(handle)
}

///|
fn update_ui() -> Unit {
  if tonemapping_state.val.ui_text is Some(handle) {
    if tonemapping_state.val.hide_ui {
      @text.text_set_content(handle, "")
    } else {
      @text.text_set_content(handle, ui_text_content())
    }
  }
}

///|
fn apply_scene_visibility(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  for entry in tonemapping_state.val.scene_entities {
    world
    .get_visibility_store()
    .set(
      entry.entity,
      if entry.scene == tonemapping_state.val.current_scene {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      },
      tick,
    )
    |> ignore
  }
}

///|
fn apply_scene_lighting(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let scene = tonemapping_state.val.current_scene

  if tonemapping_state.val.directional_light is Some(light) {
    let illuminance = if scene == 1 {
      15_000.0F
    } else if scene == 2 {
      4_000.0F
    } else {
      0.0F
    }
    world
    .get_directional_light_store()
    .set(
      light,
      @render3d.DirectionalLight::new(
        @render2d.Color::white(),
        illuminance,
        true,
      ),
      tick,
    )
    |> ignore
  }

  if tonemapping_state.val.point_light is Some(light) {
    let intensity = if scene == 1 {
      2_000.0F
    } else if scene == 2 {
      12_000.0F
    } else {
      0.0F
    }
    world
    .get_point_light_store()
    .set(
      light,
      @render3d.PointLight::new(
        @render2d.Color::new(1.0F, 0.9F, 0.8F, 1.0F),
        intensity,
        8.0F,
        true,
      ),
      tick,
    )
    |> ignore
  }
}

///|
fn apply_color_grading(world : @ecs_world.World) -> Unit {
  let state = tonemapping_state.val
  guard state.camera is Some(camera_entity) else { return }
  let settings = state.settings[state.tonemap_mode]
  let tonemapping = tonemapping_mode(state.tonemap_mode)
  let color_grading = color_grading_from_settings(settings)
  let tick = world.read_change_tick()

  let tonemapping_store = world.get_tonemapping_store()
  if tonemapping_store.contains(camera_entity) {
    tonemapping_store.set(camera_entity, tonemapping, tick) |> ignore
  } else {
    tonemapping_store.insert(camera_entity, tonemapping, tick)
  }

  let color_grading_store = world.get_color_grading_store()
  if color_grading_store.contains(camera_entity) {
    color_grading_store.set(camera_entity, color_grading, tick) |> ignore
  } else {
    color_grading_store.insert(camera_entity, color_grading, tick)
  }
}

///|
fn set_scene(scene : Int, world : @ecs_world.World) -> Unit {
  tonemapping_state.val.current_scene = scene
  apply_scene_visibility(world)
  apply_scene_lighting(world)
  apply_color_grading(world)
}

///|
fn set_tonemap_mode(mode : Int, world : @ecs_world.World) -> Unit {
  tonemapping_state.val.tonemap_mode = mode
  apply_color_grading(world)
}

///|
fn reset_all_methods_to_default(world : @ecs_world.World) -> Unit {
  for i in 0..<METHOD_COUNT {
    tonemapping_state.val.settings[i] = default_color_grading()
  }
  apply_color_grading(world)
}

///|
fn reset_all_methods_to_recommendation(world : @ecs_world.World) -> Unit {
  for i in 0..<METHOD_COUNT {
    tonemapping_state.val.settings[i] = basic_scene_recommendation(i)
  }
  apply_color_grading(world)
}

///|
fn update_color_grading_settings(world : @ecs_world.World) -> Unit {
  let delta = @time.time_delta_seconds() * 0.25F
  let signed_delta = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    -delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta
  } else {
    0.0F
  }

  if signed_delta == 0.0F {
    return
  }

  let mode = tonemapping_state.val.tonemap_mode
  let current = tonemapping_state.val.settings[mode]
  let updated = if tonemapping_state.val.selected_parameter == 0 {
    {
      ..current,
      exposure: clampf(current.exposure + signed_delta, -2.5F, 2.5F),
    }
  } else if tonemapping_state.val.selected_parameter == 1 {
    { ..current, gamma: clampf(current.gamma + signed_delta, 0.2F, 3.0F) }
  } else if tonemapping_state.val.selected_parameter == 2 {
    {
      ..current,
      pre_saturation: clampf(current.pre_saturation + signed_delta, 0.0F, 2.0F),
    }
  } else {
    {
      ..current,
      post_saturation: clampf(
        current.post_saturation + signed_delta,
        0.0F,
        2.0F,
      ),
    }
  }

  tonemapping_state.val.settings[mode] = updated
  apply_color_grading(world)
  update_ui()
}

///|
fn update_system(world : @ecs_world.World) -> Unit {
  let mut ui_changed = false

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    set_scene(1, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::KeyW) {
    set_scene(2, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::KeyE) {
    set_scene(3, world)
    ui_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    set_tonemap_mode(0, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    set_tonemap_mode(1, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    set_tonemap_mode(2, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit4) {
    set_tonemap_mode(3, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit5) {
    set_tonemap_mode(4, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit6) {
    set_tonemap_mode(5, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit7) {
    set_tonemap_mode(6, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit8) {
    set_tonemap_mode(7, world)
    ui_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::ArrowDown) {
    tonemapping_state.val.selected_parameter = (
        tonemapping_state.val.selected_parameter + 1
      ) %
      PARAMETER_COUNT
    ui_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::ArrowUp) {
    tonemapping_state.val.selected_parameter = (
        tonemapping_state.val.selected_parameter + PARAMETER_COUNT - 1
      ) %
      PARAMETER_COUNT
    ui_changed = true
  }

  if @input.key_pressed(@window.KeyCode::ArrowLeft) ||
    @input.key_pressed(@window.KeyCode::ArrowRight) {
    update_color_grading_settings(world)
    ui_changed = false
  }

  if @input.key_just_pressed(@window.KeyCode::Space) {
    reset_all_methods_to_default(world)
    ui_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) &&
    tonemapping_state.val.current_scene == 1 {
    reset_all_methods_to_recommendation(world)
    ui_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyH) {
    tonemapping_state.val.hide_ui = !tonemapping_state.val.hide_ui
    ui_changed = true
  }

  if ui_changed {
    update_ui()
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  tonemapping_state.val = {
    current_scene: 1,
    tonemap_mode: 6,
    selected_parameter: 0,
    hide_ui: false,
    ui_text: None,
    camera: None,
    directional_light: None,
    point_light: None,
    scene_entities: [],
    settings: build_recommended_settings(),
  }

  setup_scene_basic(world)
  setup_scene_color_sweep(world)
  setup_scene_image_viewer(world)
  setup_lights(world)
  setup_camera(world)
  setup_ui(world)

  apply_scene_visibility(world)
  apply_scene_lighting(world)
  apply_color_grading(world)
  update_ui()
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update_system)
  .run()
}
