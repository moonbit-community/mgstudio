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
/// Parity target: keep Bevy's AA control surface and component semantics on the
/// camera (`Msaa`, `Fxaa`, `TemporalAntiAliasing` + prepass markers).

///|
const TEXTURE_SIZE : Int = 8

///|
const HAS_SMAA : Bool = false

///|
const HAS_DLSS : Bool = false

///|
const HAS_CAS : Bool = false

///|
pub(all) enum AAMethod {
  NoAA
  MSAA
  FXAA
  SMAA
  TAA
  DLSS
}

///|
pub(all) enum MSAASamples {
  Sample2
  Sample4
  Sample8
}

///|
pub(all) enum FXAASensitivity {
  Low
  Medium
  High
  Ultra
  Extreme
}

///|
pub(all) enum SMAAQuality {
  Low
  Medium
  High
  Ultra
}

///|
pub(all) enum DLSSQuality {
  Auto
  UltraPerformance
  Performance
  Balanced
  Quality
  Dlaa
}

///|
priv struct CASState {
  enabled : Bool
  strength : Float
  denoise : Bool
}

///|
priv struct AntiAliasingState {
  mut aa_method : AAMethod
  mut msaa_samples : MSAASamples
  mut fxaa_sensitivity : FXAASensitivity
  mut smaa_quality : SMAAQuality
  mut dlss_quality : DLSSQuality
  mut cas : CASState
  mut use_orthographic : Bool
  mut camera : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let anti_aliasing_state : Ref[AntiAliasingState] = Ref::new({
  aa_method: AAMethod::NoAA,
  msaa_samples: MSAASamples::Sample4,
  fxaa_sensitivity: FXAASensitivity::Medium,
  smaa_quality: SMAAQuality::High,
  dlss_quality: DLSSQuality::Auto,
  cas: { enabled: false, strength: 0.0F, denoise: false },
  use_orthographic: false,
  camera: None,
  help_text: None,
})

///|
fn byte_from_int(value : Int) -> Byte {
  value.to_byte()
}

///|
fn aa_method_eq(lhs : AAMethod, rhs : AAMethod) -> Bool {
  if lhs is NoAA {
    rhs is NoAA
  } else if lhs is MSAA {
    rhs is MSAA
  } else if lhs is FXAA {
    rhs is FXAA
  } else if lhs is SMAA {
    rhs is SMAA
  } else if lhs is TAA {
    rhs is TAA
  } else {
    rhs is DLSS
  }
}

///|
fn msaa_samples_eq(lhs : MSAASamples, rhs : MSAASamples) -> Bool {
  if lhs is Sample2 {
    rhs is Sample2
  } else if lhs is Sample4 {
    rhs is Sample4
  } else {
    rhs is Sample8
  }
}

///|
fn fxaa_sensitivity_eq(lhs : FXAASensitivity, rhs : FXAASensitivity) -> Bool {
  if lhs is Low {
    rhs is Low
  } else if lhs is Medium {
    rhs is Medium
  } else if lhs is High {
    rhs is High
  } else if lhs is Ultra {
    rhs is Ultra
  } else {
    rhs is Extreme
  }
}

///|
fn smaa_quality_eq(lhs : SMAAQuality, rhs : SMAAQuality) -> Bool {
  if lhs is Low {
    rhs is Low
  } else if lhs is Medium {
    rhs is Medium
  } else if lhs is High {
    rhs is High
  } else {
    rhs is Ultra
  }
}

///|
fn dlss_quality_eq(lhs : DLSSQuality, rhs : DLSSQuality) -> Bool {
  if lhs is Auto {
    rhs is Auto
  } else if lhs is UltraPerformance {
    rhs is UltraPerformance
  } else if lhs is Performance {
    rhs is Performance
  } else if lhs is Balanced {
    rhs is Balanced
  } else if lhs is Quality {
    rhs is Quality
  } else {
    rhs is Dlaa
  }
}

///|
fn draw_selectable_menu_item(
  ui : StringBuilder,
  label : String,
  shortcut : String,
  enabled : Bool,
) -> Unit {
  let star = if enabled { "*" } else { "" }
  ui.write_string("(")
  ui.write_string(shortcut)
  ui.write_string(") ")
  ui.write_string(star)
  ui.write_string(label)
  ui.write_string(star)
  ui.write_string("\n")
}

///|
fn set_camera_projection(world : @ecs.World) -> Unit {
  guard anti_aliasing_state.val.camera is Some(camera_entity) else { return }
  let projection = if anti_aliasing_state.val.use_orthographic {
    @pbr.Projection::Orthographic(@pbr.OrthographicProjection3d::{
      ..@pbr.OrthographicProjection3d::default_3d(),
      scale: 0.002F,
    })
  } else {
    @pbr.Projection::Perspective(@pbr.PerspectiveProjection3d::default())
  }
  try! (world.replace(camera_entity, @pbr.ecs_key_projection, projection)
  |> ignore)
}

///|
fn msaa_component_from_selection(samples : MSAASamples) -> @pbr.Msaa {
  if msaa_samples_eq(samples, MSAASamples::Sample2) {
    @pbr.Msaa::Sample2
  } else if msaa_samples_eq(samples, MSAASamples::Sample4) {
    @pbr.Msaa::Sample4
  } else {
    @pbr.Msaa::Sample8
  }
}

///|
fn fxaa_sensitivity_component(
  sensitivity : FXAASensitivity,
) -> @post_process.FxaaSensitivity {
  if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Low) {
    @post_process.FxaaSensitivity::Low
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Medium) {
    @post_process.FxaaSensitivity::Medium
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::High) {
    @post_process.FxaaSensitivity::High
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Ultra) {
    @post_process.FxaaSensitivity::Ultra
  } else {
    @post_process.FxaaSensitivity::Extreme
  }
}

///|
fn clear_temporal_aa_components(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Unit {
  try! (world.take(camera_entity, @post_process.ecs_key_temporal_anti_aliasing)
  |> ignore)
  try! (world.take(camera_entity, @post_process.ecs_key_temporal_jitter)
  |> ignore)
  try! (world.take(camera_entity, @pbr.ecs_key_depth_prepass) |> ignore)
  try! (world.take(camera_entity, @pbr.ecs_key_motion_vector_prepass) |> ignore)
}

///|
fn apply_aa_components(world : @ecs.World) -> Unit {
  guard anti_aliasing_state.val.camera is Some(camera_entity) else { return }
  let aa_method = anti_aliasing_state.val.aa_method
  if aa_method_eq(aa_method, AAMethod::NoAA) {
    try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
    try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  if aa_method_eq(aa_method, AAMethod::MSAA) {
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_msaa,
      msaa_component_from_selection(anti_aliasing_state.val.msaa_samples),
    )
    try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  if aa_method_eq(aa_method, AAMethod::FXAA) {
    try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
    clear_temporal_aa_components(world, camera_entity)
    try! world.set_by_key(
      camera_entity,
      @post_process.ecs_key_fxaa,
      @post_process.Fxaa::default().with_sensitivity(
        fxaa_sensitivity_component(anti_aliasing_state.val.fxaa_sensitivity),
      ),
    )
    return
  }
  if aa_method_eq(aa_method, AAMethod::TAA) {
    try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
    try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
    try! world.set_by_key(
      camera_entity,
      @post_process.ecs_key_temporal_anti_aliasing,
      @post_process.TemporalAntiAliasing::default(),
    )
    try! world.set_by_key(
      camera_entity,
      @post_process.ecs_key_temporal_jitter,
      @post_process.TemporalJitter::default(),
    )
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_depth_prepass,
      @pbr.DepthPrepass::default(),
    )
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_motion_vector_prepass,
      @pbr.MotionVectorPrepass::default(),
    )
    return
  }
  if aa_method_eq(aa_method, AAMethod::SMAA) && !HAS_SMAA {
    try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
    try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  if aa_method_eq(aa_method, AAMethod::DLSS) && !HAS_DLSS {
    try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
    try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  try! world.set_by_key(camera_entity, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! (world.take(camera_entity, @post_process.ecs_key_fxaa) |> ignore)
  clear_temporal_aa_components(world, camera_entity)
}

///|
fn update_ui() -> Unit {
  guard anti_aliasing_state.val.help_text is Some(handle) else { return }
  let state = anti_aliasing_state.val
  let ui = StringBuilder::new()
  ui.write_string("Antialias Method\n")

  draw_selectable_menu_item(
    ui,
    "No AA".to_string(),
    "1".to_string(),
    aa_method_eq(state.aa_method, AAMethod::NoAA),
  )
  draw_selectable_menu_item(
    ui,
    "MSAA".to_string(),
    "2".to_string(),
    aa_method_eq(state.aa_method, AAMethod::MSAA),
  )
  draw_selectable_menu_item(
    ui,
    "FXAA".to_string(),
    "3".to_string(),
    aa_method_eq(state.aa_method, AAMethod::FXAA),
  )
  draw_selectable_menu_item(
    ui,
    if HAS_SMAA {
      "SMAA".to_string()
    } else {
      "SMAA (Unavailable)".to_string()
    },
    "4".to_string(),
    HAS_SMAA && aa_method_eq(state.aa_method, AAMethod::SMAA),
  )
  draw_selectable_menu_item(
    ui,
    "TAA".to_string(),
    "5".to_string(),
    aa_method_eq(state.aa_method, AAMethod::TAA),
  )
  draw_selectable_menu_item(
    ui,
    if HAS_DLSS {
      "DLSS".to_string()
    } else {
      "DLSS (Unavailable)".to_string()
    },
    "6".to_string(),
    HAS_DLSS && aa_method_eq(state.aa_method, AAMethod::DLSS),
  )

  if aa_method_eq(state.aa_method, AAMethod::MSAA) {
    ui.write_string("\n----------\n\nSample Count\n")
    draw_selectable_menu_item(
      ui,
      "2".to_string(),
      "Q".to_string(),
      msaa_samples_eq(state.msaa_samples, MSAASamples::Sample2),
    )
    draw_selectable_menu_item(
      ui,
      "4".to_string(),
      "W".to_string(),
      msaa_samples_eq(state.msaa_samples, MSAASamples::Sample4),
    )
    draw_selectable_menu_item(
      ui,
      "8".to_string(),
      "E".to_string(),
      msaa_samples_eq(state.msaa_samples, MSAASamples::Sample8),
    )
  }

  if aa_method_eq(state.aa_method, AAMethod::FXAA) {
    ui.write_string("\n----------\n\nSensitivity\n")
    draw_selectable_menu_item(
      ui,
      "Low".to_string(),
      "Q".to_string(),
      fxaa_sensitivity_eq(state.fxaa_sensitivity, FXAASensitivity::Low),
    )
    draw_selectable_menu_item(
      ui,
      "Medium".to_string(),
      "W".to_string(),
      fxaa_sensitivity_eq(state.fxaa_sensitivity, FXAASensitivity::Medium),
    )
    draw_selectable_menu_item(
      ui,
      "High".to_string(),
      "E".to_string(),
      fxaa_sensitivity_eq(state.fxaa_sensitivity, FXAASensitivity::High),
    )
    draw_selectable_menu_item(
      ui,
      "Ultra".to_string(),
      "R".to_string(),
      fxaa_sensitivity_eq(state.fxaa_sensitivity, FXAASensitivity::Ultra),
    )
    draw_selectable_menu_item(
      ui,
      "Extreme".to_string(),
      "T".to_string(),
      fxaa_sensitivity_eq(state.fxaa_sensitivity, FXAASensitivity::Extreme),
    )
  }

  if HAS_SMAA && aa_method_eq(state.aa_method, AAMethod::SMAA) {
    ui.write_string("\n----------\n\nQuality\n")
    draw_selectable_menu_item(
      ui,
      "Low".to_string(),
      "Q".to_string(),
      smaa_quality_eq(state.smaa_quality, SMAAQuality::Low),
    )
    draw_selectable_menu_item(
      ui,
      "Medium".to_string(),
      "W".to_string(),
      smaa_quality_eq(state.smaa_quality, SMAAQuality::Medium),
    )
    draw_selectable_menu_item(
      ui,
      "High".to_string(),
      "E".to_string(),
      smaa_quality_eq(state.smaa_quality, SMAAQuality::High),
    )
    draw_selectable_menu_item(
      ui,
      "Ultra".to_string(),
      "R".to_string(),
      smaa_quality_eq(state.smaa_quality, SMAAQuality::Ultra),
    )
  }

  if HAS_DLSS && aa_method_eq(state.aa_method, AAMethod::DLSS) {
    ui.write_string("\n----------\n\nQuality\n")
    draw_selectable_menu_item(
      ui,
      "Auto".to_string(),
      "Z".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::Auto),
    )
    draw_selectable_menu_item(
      ui,
      "UltraPerformance".to_string(),
      "X".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::UltraPerformance),
    )
    draw_selectable_menu_item(
      ui,
      "Performance".to_string(),
      "C".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::Performance),
    )
    draw_selectable_menu_item(
      ui,
      "Balanced".to_string(),
      "V".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::Balanced),
    )
    draw_selectable_menu_item(
      ui,
      "Quality".to_string(),
      "B".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::Quality),
    )
    draw_selectable_menu_item(
      ui,
      "DLAA".to_string(),
      "N".to_string(),
      dlss_quality_eq(state.dlss_quality, DLSSQuality::Dlaa),
    )
  }

  ui.write_string("\n----------\n\n")
  draw_selectable_menu_item(
    ui,
    if HAS_CAS {
      "Sharpening".to_string()
    } else {
      "Sharpening (Unavailable)".to_string()
    },
    "0".to_string(),
    HAS_CAS && state.cas.enabled,
  )
  if HAS_CAS && state.cas.enabled {
    ui.write_string("(-/=) Strength: \{state.cas.strength.to_string()}\n")
    draw_selectable_menu_item(
      ui,
      "Denoising".to_string(),
      "D".to_string(),
      state.cas.denoise,
    )
  }
  ui.write_string("\n----------\n\n")
  draw_selectable_menu_item(
    ui,
    "Orthographic".to_string(),
    "O".to_string(),
    state.use_orthographic,
  )
  @text.text_set_content(handle, ui.to_string())
}

///|
fn uv_debug_texture() -> @asset.Handle[@asset.Image] {
  let mut palette : Array[Byte] = [
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(159),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(159),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
  ]

  let texture_data : Array[Byte] = []
  for _y in 0..<TEXTURE_SIZE {
    for i in 0..<palette.length() {
      texture_data.push(palette[i])
    }
    let rotated : Array[Byte] = []
    for i in 0..<palette.length() {
      let source = if i < 4 { palette.length() - 4 + i } else { i - 4 }
      rotated.push(palette[source])
    }
    palette = rotated
  }

  let size = @math.UVec2::new(TEXTURE_SIZE, TEXTURE_SIZE)
  let texture = @asset.asset_create_dynamic_texture(size, true)
  @asset.asset_update_texture_region_rgba8(
    texture,
    @math.URect::new(@math.UVec2::new(0, 0), size),
    Bytes::from_array(texture_data),
  )
  texture
}

///|
fn setup(world : @ecs.World) -> Unit {
  anti_aliasing_state.val.aa_method = AAMethod::NoAA
  anti_aliasing_state.val.msaa_samples = MSAASamples::Sample4
  anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::Medium
  anti_aliasing_state.val.smaa_quality = SMAAQuality::High
  anti_aliasing_state.val.dlss_quality = DLSSQuality::Auto
  anti_aliasing_state.val.cas = {
    enabled: false,
    strength: 0.0F,
    denoise: false,
  }
  anti_aliasing_state.val.use_orthographic = false
  anti_aliasing_state.val.camera = None
  anti_aliasing_state.val.help_text = None

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(20.0F, 20.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::new(0.1F, 0.2F, 0.1F, 1.0F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_base_color_texture(Some(uv_debug_texture()))
    .with_perceptual_roughness(0.85F)
    .with_metallic(0.0F),
  )

  for i in 0..<5 {
    let i_f = Float::from_double(i.to_double())
    @pbr.MeshMaterial3dBundle::new(
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(0.25F, 0.25F, 0.25F),
          ),
        ),
      ),
      @pbr.MeshMaterial3d::new(cube_material),
      @transform.Transform::from_xyz(i_f * 0.25F - 1.0F, 0.125F, -i_f * 0.5F),
    ).spawn(world)
    |> ignore
  }

  let asset_server = @asset.AssetServer::new()
  let helmet = world.spawn_empty()
  try! world.set_by_key(
    helmet,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
  )

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 15_000.0F, true),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 2.0F, 2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let camera_entity = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_distance_fog(
      Some(
        @pbr.DistanceFog::new(
          @sprite.Color::new(
            43.0F / 255.0F,
            44.0F / 255.0F,
            47.0F / 255.0F,
            1.0F,
          ),
          @pbr.FogFalloff3d::linear(1.0F, 4.0F),
        ),
      ),
    )
    .spawn(world)
  anti_aliasing_state.val.camera = Some(camera_entity)
  try! world.set_by_key(
    camera_entity,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      150.0F,
    ),
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
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  anti_aliasing_state.val.help_text = Some(help_text)

  set_camera_projection(world)
  apply_aa_components(world)
  update_ui()
}

///|
fn read_cas_character_shortcuts(
  keyboard_inputs : @ecs.MessageReader[@input.KeyboardInput],
) -> (Bool, Bool, Bool) {
  let mut toggle = false
  let mut decrement = false
  let mut increment = false
  for event in (try! keyboard_inputs.read()) {
    if event.state is Released || event.repeat {
      continue
    }
    if event.logical_key is @input.Key::Character(character) {
      if character == "0" || character == ")" {
        toggle = true
      } else if character == "-" || character == "_" {
        decrement = true
      } else if character == "=" || character == "+" {
        increment = true
      }
    }
  }
  (toggle, decrement, increment)
}

///|
fn modify_aa(
  world : @ecs.World,
  keyboard_inputs : @ecs.MessageReader[@input.KeyboardInput],
) -> Bool {
  let (cas_toggle_char, cas_decrease_char, cas_increase_char) = read_cas_character_shortcuts(
    keyboard_inputs,
  )
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    anti_aliasing_state.val.aa_method = AAMethod::NoAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    anti_aliasing_state.val.aa_method = AAMethod::MSAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    anti_aliasing_state.val.aa_method = AAMethod::FXAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    if HAS_SMAA {
      anti_aliasing_state.val.aa_method = AAMethod::SMAA
      changed = true
    }
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    anti_aliasing_state.val.aa_method = AAMethod::TAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    if HAS_DLSS {
      anti_aliasing_state.val.aa_method = AAMethod::DLSS
      changed = true
    }
  }

  if aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::MSAA) {
    if @input.key_just_pressed(@window.KeyCode::KeyQ) {
      anti_aliasing_state.val.msaa_samples = MSAASamples::Sample2
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyW) {
      anti_aliasing_state.val.msaa_samples = MSAASamples::Sample4
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyE) {
      anti_aliasing_state.val.msaa_samples = MSAASamples::Sample8
      changed = true
    }
  }

  if aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::FXAA) {
    if @input.key_just_pressed(@window.KeyCode::KeyQ) {
      anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::Low
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyW) {
      anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::Medium
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyE) {
      anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::High
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyR) {
      anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::Ultra
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyT) {
      anti_aliasing_state.val.fxaa_sensitivity = FXAASensitivity::Extreme
      changed = true
    }
  }

  if HAS_SMAA && aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::SMAA) {
    if @input.key_just_pressed(@window.KeyCode::KeyQ) {
      anti_aliasing_state.val.smaa_quality = SMAAQuality::Low
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyW) {
      anti_aliasing_state.val.smaa_quality = SMAAQuality::Medium
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyE) {
      anti_aliasing_state.val.smaa_quality = SMAAQuality::High
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyR) {
      anti_aliasing_state.val.smaa_quality = SMAAQuality::Ultra
      changed = true
    }
  }

  if HAS_DLSS && aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::DLSS) {
    if @input.key_just_pressed(@window.KeyCode::KeyZ) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::Auto
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyX) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::UltraPerformance
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyC) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::Performance
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyV) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::Balanced
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyB) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::Quality
      changed = true
    }
    if @input.key_just_pressed(@window.KeyCode::KeyN) {
      anti_aliasing_state.val.dlss_quality = DLSSQuality::Dlaa
      changed = true
    }
  }

  if HAS_CAS {
    if @input.key_just_pressed(@window.KeyCode::KeyP) || cas_toggle_char {
      anti_aliasing_state.val.cas = {
        ..anti_aliasing_state.val.cas,
        enabled: !anti_aliasing_state.val.cas.enabled,
      }
      changed = true
    }
    if anti_aliasing_state.val.cas.enabled {
      if @input.key_just_pressed(@window.KeyCode::Comma) || cas_decrease_char {
        anti_aliasing_state.val.cas = {
          ..anti_aliasing_state.val.cas,
          strength: if anti_aliasing_state.val.cas.strength - 0.1F < 0.0F {
            0.0F
          } else {
            anti_aliasing_state.val.cas.strength - 0.1F
          },
        }
        changed = true
      }
      if @input.key_just_pressed(@window.KeyCode::Period) || cas_increase_char {
        anti_aliasing_state.val.cas = {
          ..anti_aliasing_state.val.cas,
          strength: if anti_aliasing_state.val.cas.strength + 0.1F > 1.0F {
            1.0F
          } else {
            anti_aliasing_state.val.cas.strength + 0.1F
          },
        }
        changed = true
      }
      if @input.key_just_pressed(@window.KeyCode::KeyD) {
        anti_aliasing_state.val.cas = {
          ..anti_aliasing_state.val.cas,
          denoise: !anti_aliasing_state.val.cas.denoise,
        }
        changed = true
      }
    }
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    anti_aliasing_state.val.use_orthographic = !anti_aliasing_state.val.use_orthographic
    set_camera_projection(world)
    changed = true
  }

  changed
}

///|
fn update(keyboard_inputs : @ecs.MessageReader[@input.KeyboardInput]) -> Unit {
  let world = @app.current_world().unwrap()
  if modify_aa(world, keyboard_inputs) {
    apply_aa_components(world)
    update_ui()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param(update)))
  .run()
}
