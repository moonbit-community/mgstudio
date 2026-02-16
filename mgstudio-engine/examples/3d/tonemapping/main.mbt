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
/// (`Tonemapping`, `ColorGrading`, HDR/exr drag-drop path, custom shader
/// material) is approximated with the current mgstudio render controls using
/// material-space mapping proxies, fog/ambient response, and the same runtime
/// interaction model.

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
priv struct ControlledMaterial {
  handle : @asset.Handle[@render3d.StandardMaterial]
  base_color : @render2d.Color
  base_roughness : Float
  base_reflectance : Float
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
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  materials : Array[ControlledMaterial]
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
  directional_light: None,
  point_light: None,
  materials: [],
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
fn selected_marker(value : Int, selected : Int) -> String {
  if value == selected {
    "> "
  } else {
    ""
  }
}

///|
fn apply_saturation(
  r : Float,
  g : Float,
  b : Float,
  saturation : Float,
) -> (Float, Float, Float) {
  let gray = (r + g + b) / 3.0F
  (
    clampf(gray + (r - gray) * saturation, 0.0F, 8.0F),
    clampf(gray + (g - gray) * saturation, 0.0F, 8.0F),
    clampf(gray + (b - gray) * saturation, 0.0F, 8.0F),
  )
}

///|
fn method_tint(mode : Int) -> (Float, Float, Float, Float) {
  if mode == 0 {
    (1.0F, 1.0F, 1.0F, 1.0F)
  } else if mode == 1 {
    (1.03F, 1.0F, 0.96F, 0.95F)
  } else if mode == 2 {
    (0.98F, 1.02F, 1.05F, 0.9F)
  } else if mode == 3 {
    (1.08F, 1.0F, 0.94F, 1.08F)
  } else if mode == 4 {
    (1.02F, 0.98F, 0.90F, 1.04F)
  } else if mode == 5 {
    (0.95F, 1.02F, 1.08F, 0.94F)
  } else if mode == 6 {
    (1.12F, 1.04F, 0.96F, 1.0F)
  } else {
    (0.98F, 1.04F, 1.08F, 0.92F)
  }
}

///|
fn method_curve(value : Float, mode : Int) -> Float {
  let v = clampf(value, 0.0F, 16.0F)
  if mode == 0 {
    clamp01(v)
  } else if mode == 1 {
    clamp01(v / (1.0F + v))
  } else if mode == 2 {
    clamp01(@math.pow(v / (1.0F + v), 0.92F))
  } else if mode == 3 {
    let numerator = v * (2.51F * v + 0.03F)
    let denominator = v * (2.43F * v + 0.59F) + 0.14F
    if denominator <= 0.0001F {
      0.0F
    } else {
      clamp01(numerator / denominator)
    }
  } else if mode == 4 {
    clamp01(@math.pow(v / (1.0F + v), 0.82F))
  } else if mode == 5 {
    clamp01(v * 0.85F / (1.0F + v * 0.35F))
  } else if mode == 6 {
    clamp01(@math.pow(v / (1.0F + v), 1.1F))
  } else {
    clamp01(v * (v + 0.15F) / (v * v + 0.5F * v + 0.06F))
  }
}

///|
fn register_material(
  handle : @asset.Handle[@render3d.StandardMaterial],
  base_color : @render2d.Color,
  base_roughness : Float,
  base_reflectance : Float,
) -> Unit {
  tonemapping_state.val.materials.push({
    handle,
    base_color,
    base_roughness,
    base_reflectance,
  })
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
  register_material(floor_material, floor_color, 0.85F, 0.3F)
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
    register_material(bar_material, bar_color, 0.2F, 0.5F)
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
  register_material(sphere_material, sphere_color, 0.15F, 0.7F)
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
  register_material(sphere_2_material, sphere_2_color, 0.35F, 0.5F)
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
      register_material(mat, color, 0.4F, 0.5F)

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
  register_material(panel, panel_color, 1.0F, 0.2F)
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
  register_material(image_material, image_color, 0.3F, 0.5F)
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
  register_material(frame_material, frame_color, 0.8F, 0.2F)
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
  register_material(floor_material, floor_color, 0.9F, 0.25F)
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
  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.7F, CAMERA_HEIGHT, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
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
    "(Y) " +
    selected_marker(6, state.tonemap_mode) +
    "TonyMcMapface (Digit7 proxy)\n" +
    "(U) " +
    selected_marker(7, state.tonemap_mode) +
    "Blender Filmic (Digit8 proxy)\n\n" +
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
  let settings = state.settings[state.tonemap_mode]
  let exposure_scale = @math.pow(2.0F, settings.exposure)
  let gamma = clampf(settings.gamma, 0.2F, 3.0F)
  let (tint_r, tint_g, tint_b, contrast) = method_tint(state.tonemap_mode)

  for controlled in state.materials {
    if @render3d.standard_material_get(controlled.handle) is Some(material) {
      let (pre_r, pre_g, pre_b) = apply_saturation(
        controlled.base_color.r,
        controlled.base_color.g,
        controlled.base_color.b,
        settings.pre_saturation,
      )

      let mapped_r = method_curve(
        pre_r * tint_r * exposure_scale,
        state.tonemap_mode,
      )
      let mapped_g = method_curve(
        pre_g * tint_g * exposure_scale,
        state.tonemap_mode,
      )
      let mapped_b = method_curve(
        pre_b * tint_b * exposure_scale,
        state.tonemap_mode,
      )

      let gamma_r = @math.pow(clampf(mapped_r, 0.0F, 1.0F), 1.0F / gamma)
      let gamma_g = @math.pow(clampf(mapped_g, 0.0F, 1.0F), 1.0F / gamma)
      let gamma_b = @math.pow(clampf(mapped_b, 0.0F, 1.0F), 1.0F / gamma)

      let contrast_r = clamp01((gamma_r - 0.5F) * contrast + 0.5F)
      let contrast_g = clamp01((gamma_g - 0.5F) * contrast + 0.5F)
      let contrast_b = clamp01((gamma_b - 0.5F) * contrast + 0.5F)

      let (out_r, out_g, out_b) = apply_saturation(
        contrast_r,
        contrast_g,
        contrast_b,
        settings.post_saturation,
      )

      let updated = material
        .with_base_color(
          @render2d.Color::new(out_r, out_g, out_b, controlled.base_color.a),
        )
        .with_perceptual_roughness(
          clampf(
            controlled.base_roughness +
            (1.0F - settings.post_saturation) * 0.12F,
            0.0F,
            1.0F,
          ),
        )
        .with_reflectance(
          clampf(
            controlled.base_reflectance +
            (settings.post_saturation - 1.0F) * 0.08F,
            0.0F,
            1.0F,
          ),
        )

      @render3d.standard_material_set(controlled.handle, updated) |> ignore
    }
  }

  let scene_factor = if state.current_scene == 1 {
    1.0F
  } else if state.current_scene == 2 {
    0.8F
  } else {
    0.6F
  }

  let fog_start = clampf(1.0F - settings.exposure * 0.35F, 0.2F, 2.0F)
  let fog_end = clampf(8.0F + settings.exposure * 1.6F, 3.0F, 14.0F)
  let fog_color = @render2d.Color::new(
    clamp01(0.10F * scene_factor + tint_r * 0.06F),
    clamp01(0.11F * scene_factor + tint_g * 0.06F),
    clamp01(0.12F * scene_factor + tint_b * 0.06F),
    1.0F,
  )

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      fog_color,
      @render3d.FogFalloff3d::linear(fog_start, fog_end),
    ),
  )

  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    let brightness = clampf(
      0.01F + exposure_scale * 0.015F * scene_factor,
      0.0F,
      0.08F,
    )
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      brightness,
    )
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
  } else if @input.key_just_pressed(@window.KeyCode::KeyY) {
    set_tonemap_mode(6, world)
    ui_changed = true
  } else if @input.key_just_pressed(@window.KeyCode::KeyU) {
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
    directional_light: None,
    point_light: None,
    materials: [],
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
