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
/// Port of `bevy/examples/3d/anti_aliasing.rs`.
///
/// Parity target: keep Bevy's AA control surface and component semantics on the
/// camera (`Msaa`, `Fxaa`, `TemporalAntiAliasing` + prepass markers). Renderer
/// backends that are still unavailable (`SMAA`, `DLSS`, CAS pass quality) are
/// explicitly represented through visual proxy mapping in this example.

///|
const TEXTURE_SIZE : Int = 8

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
  mut cube_material : @asset.Handle[@render3d.StandardMaterial]?
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
  cube_material: None,
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
  let tick = world.read_change_tick()
  let projection = if anti_aliasing_state.val.use_orthographic {
    @render3d.Projection::Orthographic(
      @render3d.OrthographicProjection3d::default_3d().with_scale(0.002F),
    )
  } else {
    @render3d.Projection::Perspective(
      @render3d.PerspectiveProjection3d::default(),
    )
  }
  world
  .component(@render3d.ecs_key_projection)
  .set(camera_entity, projection, tick)
  |> ignore
}

///|
fn msaa_component_from_selection(samples : MSAASamples) -> @render3d.Msaa {
  if msaa_samples_eq(samples, MSAASamples::Sample2) {
    @render3d.Msaa::Sample2
  } else if msaa_samples_eq(samples, MSAASamples::Sample4) {
    @render3d.Msaa::Sample4
  } else {
    @render3d.Msaa::Sample8
  }
}

///|
fn fxaa_sensitivity_component(
  sensitivity : FXAASensitivity,
) -> @render3d.FxaaSensitivity {
  if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Low) {
    @render3d.FxaaSensitivity::Low
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Medium) {
    @render3d.FxaaSensitivity::Medium
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::High) {
    @render3d.FxaaSensitivity::High
  } else if fxaa_sensitivity_eq(sensitivity, FXAASensitivity::Ultra) {
    @render3d.FxaaSensitivity::Ultra
  } else {
    @render3d.FxaaSensitivity::Extreme
  }
}

///|
fn clear_temporal_aa_components(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Unit {
  world
  .component(@render3d.ecs_key_temporal_anti_aliasing)
  .remove(camera_entity)
  |> ignore
  world.component(@render3d.ecs_key_temporal_jitter).remove(camera_entity)
  |> ignore
  world.component(@render3d.ecs_key_depth_prepass).remove(camera_entity)
  |> ignore
  world.component(@render3d.ecs_key_motion_vector_prepass).remove(camera_entity)
  |> ignore
}

///|
fn apply_aa_components(world : @ecs.World) -> Unit {
  guard anti_aliasing_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  let aa_method = anti_aliasing_state.val.aa_method
  if aa_method_eq(aa_method, AAMethod::NoAA) {
    world
    .component(@render3d.ecs_key_msaa)
    .insert(camera_entity, @render3d.Msaa::Off, tick)
    world.component(@render3d.ecs_key_fxaa).remove(camera_entity) |> ignore
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  if aa_method_eq(aa_method, AAMethod::MSAA) {
    world
    .component(@render3d.ecs_key_msaa)
    .insert(
      camera_entity,
      msaa_component_from_selection(anti_aliasing_state.val.msaa_samples),
      tick,
    )
    world.component(@render3d.ecs_key_fxaa).remove(camera_entity) |> ignore
    clear_temporal_aa_components(world, camera_entity)
    return
  }
  if aa_method_eq(aa_method, AAMethod::FXAA) {
    world
    .component(@render3d.ecs_key_msaa)
    .insert(camera_entity, @render3d.Msaa::Off, tick)
    clear_temporal_aa_components(world, camera_entity)
    world
    .component(@render3d.ecs_key_fxaa)
    .insert(
      camera_entity,
      @render3d.Fxaa::default().with_sensitivity(
        fxaa_sensitivity_component(anti_aliasing_state.val.fxaa_sensitivity),
      ),
      tick,
    )
    return
  }
  if aa_method_eq(aa_method, AAMethod::TAA) {
    world
    .component(@render3d.ecs_key_msaa)
    .insert(camera_entity, @render3d.Msaa::Off, tick)
    world.component(@render3d.ecs_key_fxaa).remove(camera_entity) |> ignore
    world
    .component(@render3d.ecs_key_temporal_anti_aliasing)
    .insert(camera_entity, @render3d.TemporalAntiAliasing::default(), tick)
    world
    .component(@render3d.ecs_key_temporal_jitter)
    .insert(camera_entity, @render3d.TemporalJitter::default(), tick)
    world
    .component(@render3d.ecs_key_depth_prepass)
    .insert(camera_entity, @render3d.DepthPrepass::default(), tick)
    world
    .component(@render3d.ecs_key_motion_vector_prepass)
    .insert(camera_entity, @render3d.MotionVectorPrepass::default(), tick)
    return
  }
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera_entity, @render3d.Msaa::Off, tick)
  world.component(@render3d.ecs_key_fxaa).remove(camera_entity) |> ignore
  clear_temporal_aa_components(world, camera_entity)
}

///|
fn aa_proxy_roughness() -> Float {
  let aa_method = anti_aliasing_state.val.aa_method
  if aa_method_eq(aa_method, AAMethod::NoAA) {
    0.85F
  } else if aa_method_eq(aa_method, AAMethod::MSAA) {
    if msaa_samples_eq(
        anti_aliasing_state.val.msaa_samples,
        MSAASamples::Sample2,
      ) {
      0.70F
    } else if msaa_samples_eq(
        anti_aliasing_state.val.msaa_samples,
        MSAASamples::Sample4,
      ) {
      0.58F
    } else {
      0.45F
    }
  } else if aa_method_eq(aa_method, AAMethod::FXAA) {
    if fxaa_sensitivity_eq(
        anti_aliasing_state.val.fxaa_sensitivity,
        FXAASensitivity::Low,
      ) {
      0.64F
    } else if fxaa_sensitivity_eq(
        anti_aliasing_state.val.fxaa_sensitivity,
        FXAASensitivity::Medium,
      ) {
      0.58F
    } else if fxaa_sensitivity_eq(
        anti_aliasing_state.val.fxaa_sensitivity,
        FXAASensitivity::High,
      ) {
      0.52F
    } else if fxaa_sensitivity_eq(
        anti_aliasing_state.val.fxaa_sensitivity,
        FXAASensitivity::Ultra,
      ) {
      0.46F
    } else {
      0.40F
    }
  } else if aa_method_eq(aa_method, AAMethod::SMAA) {
    if smaa_quality_eq(anti_aliasing_state.val.smaa_quality, SMAAQuality::Low) {
      0.62F
    } else if smaa_quality_eq(
        anti_aliasing_state.val.smaa_quality,
        SMAAQuality::Medium,
      ) {
      0.54F
    } else if smaa_quality_eq(
        anti_aliasing_state.val.smaa_quality,
        SMAAQuality::High,
      ) {
      0.46F
    } else {
      0.38F
    }
  } else if aa_method_eq(aa_method, AAMethod::TAA) {
    0.35F
  } else if dlss_quality_eq(
      anti_aliasing_state.val.dlss_quality,
      DLSSQuality::UltraPerformance,
    ) {
    0.33F
  } else if dlss_quality_eq(
      anti_aliasing_state.val.dlss_quality,
      DLSSQuality::Performance,
    ) {
    0.31F
  } else if dlss_quality_eq(
      anti_aliasing_state.val.dlss_quality,
      DLSSQuality::Balanced,
    ) {
    0.29F
  } else if dlss_quality_eq(
      anti_aliasing_state.val.dlss_quality,
      DLSSQuality::Quality,
    ) {
    0.27F
  } else if dlss_quality_eq(
      anti_aliasing_state.val.dlss_quality,
      DLSSQuality::Dlaa,
    ) {
    0.25F
  } else {
    0.30F
  }
}

///|
fn aa_proxy_fog_end() -> Float {
  let aa_method = anti_aliasing_state.val.aa_method
  if aa_method_eq(aa_method, AAMethod::NoAA) {
    3.4F
  } else if aa_method_eq(aa_method, AAMethod::MSAA) {
    3.9F
  } else if aa_method_eq(aa_method, AAMethod::FXAA) {
    4.3F
  } else if aa_method_eq(aa_method, AAMethod::SMAA) {
    4.8F
  } else if aa_method_eq(aa_method, AAMethod::TAA) {
    5.3F
  } else {
    5.8F
  }
}

///|
fn apply_aa_proxy() -> Unit {
  if anti_aliasing_state.val.cube_material is Some(material_handle) {
    if @render3d.standard_material_get(material_handle) is Some(material) {
      let cas = anti_aliasing_state.val.cas
      let strength = if cas.enabled { cas.strength } else { 0.0F }
      let emissive_value = 0.15F * strength
      let updated = material
        .with_perceptual_roughness(aa_proxy_roughness())
        .with_reflectance(0.5F + strength * 0.3F)
        .with_emissive(
          @render2d.Color::new(
            emissive_value, emissive_value, emissive_value, 1.0F,
          ),
        )
        .with_metallic(if cas.denoise { 0.0F } else { 0.1F + strength * 0.2F })
      @render3d.standard_material_set(material_handle, updated) |> ignore
    }
  }

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F, 1.0F),
      @render3d.FogFalloff3d::linear(1.0F, aa_proxy_fog_end()),
    ),
  )
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
    "SMAA".to_string(),
    "4".to_string(),
    aa_method_eq(state.aa_method, AAMethod::SMAA),
  )
  draw_selectable_menu_item(
    ui,
    "TAA".to_string(),
    "5".to_string(),
    aa_method_eq(state.aa_method, AAMethod::TAA),
  )
  draw_selectable_menu_item(
    ui,
    "DLSS".to_string(),
    "6".to_string(),
    aa_method_eq(state.aa_method, AAMethod::DLSS),
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

  if aa_method_eq(state.aa_method, AAMethod::SMAA) {
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

  if aa_method_eq(state.aa_method, AAMethod::DLSS) {
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
    "Sharpening".to_string(),
    "0".to_string(),
    state.cas.enabled,
  )
  if state.cas.enabled {
    ui.write_string("(-/=) Strength: " + state.cas.strength.to_string() + "\n")
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
  ui.write_string(
    "\nRuntime note: MSAA/FXAA/TAA camera components follow Bevy semantics; SMAA/DLSS/CAS stay proxy-mapped in current runtime.",
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
  anti_aliasing_state.val.cube_material = None
  anti_aliasing_state.val.help_text = None

  let tick = world.read_change_tick()

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_plane(20.0F, 20.0F),
    @render3d.MeshMaterial3d::new(
      @render3d.standard_material_add(
        @render3d.StandardMaterial::from_color(
          @render2d.Color::new(0.1F, 0.2F, 0.1F, 1.0F),
        ),
      ),
    ),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_base_color_texture(Some(uv_debug_texture()))
    .with_perceptual_roughness(0.85F)
    .with_metallic(0.0F),
  )
  anti_aliasing_state.val.cube_material = Some(cube_material)

  for i in 0..<5 {
    let i_f = Float::from_double(i.to_double())
    @render3d.MeshMaterial3dBundle::new(
      @render3d.Mesh3d::from_cuboid(0.25F, 0.25F, 0.25F),
      @render3d.MeshMaterial3d::new(cube_material),
      @math.Transform::from_xyz(i_f * 0.25F - 1.0F, 0.125F, -i_f * 0.5F),
    ).spawn(world)
    |> ignore
  }

  let asset_server = @asset.AssetServer::new()
  let helmet = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(
    helmet,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @scene.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
    tick,
  )

  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_xyz(0.0F, 2.0F, 2.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let camera_entity = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  anti_aliasing_state.val.camera = Some(camera_entity)
  world
  .component(@render3d.ecs_key_environment_map_light)
  .insert(
    camera_entity,
    @render3d.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      150.0F,
    ),
    tick,
  )

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F, 1.0F),
      @render3d.FogFalloff3d::linear(1.0F, 4.0F),
    ),
  )

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
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
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  anti_aliasing_state.val.help_text = Some(help_text)

  set_camera_projection(world)
  apply_aa_components(world)
  apply_aa_proxy()
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
    anti_aliasing_state.val.aa_method = AAMethod::SMAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    anti_aliasing_state.val.aa_method = AAMethod::TAA
    changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    anti_aliasing_state.val.aa_method = AAMethod::DLSS
    changed = true
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

  if aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::SMAA) {
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

  if aa_method_eq(anti_aliasing_state.val.aa_method, AAMethod::DLSS) {
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
    apply_aa_proxy()
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
