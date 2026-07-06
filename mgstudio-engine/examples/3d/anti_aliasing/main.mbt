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
// Bevy source: `bevy/examples/3d/anti_aliasing.rs`.

///|
const PI : Float = 3.141592653589793F

///|
const TEXTURE_SIZE : Int = 8

///|
fn byte_from_int(value : Int) -> Byte {
  value.to_byte()
}

///|
fn clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
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
  ui.write_string("(\{shortcut}) \{star}\{label}\{star}\n")
}

///|
fn remove_taa_components(camera : @app.EntityCommands) -> Unit {
  camera.remove(@anti_alias.ecs_key_temporal_anti_aliasing)
  camera.remove(@anti_alias.ecs_key_temporal_jitter)
  camera.remove(@anti_alias.ecs_key_mip_bias)
  camera.remove(@pbr.ecs_key_depth_prepass)
  camera.remove(@pbr.ecs_key_motion_vector_prepass)
}

///|
fn remove_dlss_components(_camera : @app.EntityCommands) -> Unit {
  // This example follows Bevy's non-DLSS cfg branch. mgstudio's DLSS package
  // exists, but the example does not enable a DLSS feature/project id branch.
}

///|
fn insert_taa_components(camera : @app.EntityCommands) -> Unit {
  camera.insert_component(
    @anti_alias.TemporalAntiAliasing::TemporalAntiAliasing(),
  )
  camera.insert_component(@anti_alias.TemporalJitter::TemporalJitter())
  camera.insert_component(@anti_alias.MipBias::MipBias())
  camera.insert_component(@pbr.DepthPrepass::DepthPrepass())
  camera.insert_component(@pbr.MotionVectorPrepass::MotionVectorPrepass())
}

///|
fn modify_aa(
  keys : @input.ButtonInput[@window.KeyCode],
  camera : @app.Single[
    (
      @core.Entity,
      @ecs.Optional[@anti_alias.Fxaa],
      @ecs.Optional[@anti_alias.Smaa],
      @ecs.Optional[@anti_alias.TemporalAntiAliasing],
      @ecs.Write[@anti_alias.Msaa],
    ),
    @ecs.With[@camera.Camera3d],
  ],
  commands : @app.Commands,
) -> Unit {
  let (camera_entity, fxaa, smaa, taa, msaa) = camera.get()
  let camera_commands = commands.entity(camera_entity)

  if keys.just_pressed(@window.KeyCode::Digit1) {
    msaa.set(@anti_alias.Msaa::Off)
    camera_commands.remove(@anti_alias.ecs_key_fxaa)
    camera_commands.remove(@anti_alias.ecs_key_smaa)
    remove_taa_components(camera_commands)
    remove_dlss_components(camera_commands)
  }

  if keys.just_pressed(@window.KeyCode::Digit2) &&
    msaa.value() == @anti_alias.Msaa::Off {
    camera_commands.remove(@anti_alias.ecs_key_fxaa)
    camera_commands.remove(@anti_alias.ecs_key_smaa)
    remove_taa_components(camera_commands)
    remove_dlss_components(camera_commands)
    msaa.set(@anti_alias.Msaa::Sample4)
  }

  if msaa.value() != @anti_alias.Msaa::Off {
    if keys.just_pressed(@window.KeyCode::KeyQ) {
      msaa.set(@anti_alias.Msaa::Sample2)
    }
    if keys.just_pressed(@window.KeyCode::KeyW) {
      msaa.set(@anti_alias.Msaa::Sample4)
    }
    if keys.just_pressed(@window.KeyCode::KeyE) {
      msaa.set(@anti_alias.Msaa::Sample8)
    }
  }

  if keys.just_pressed(@window.KeyCode::Digit3) && fxaa.value() is None {
    msaa.set(@anti_alias.Msaa::Off)
    camera_commands.remove(@anti_alias.ecs_key_smaa)
    remove_taa_components(camera_commands)
    remove_dlss_components(camera_commands)
    camera_commands.insert_component(@anti_alias.Fxaa::Fxaa())
  }

  match fxaa.value() {
    Some(fxaa_value) => {
      if keys.just_pressed(@window.KeyCode::KeyQ) {
        camera_commands.insert_component(
          fxaa_value.with_sensitivity(@anti_alias.FxaaSensitivity::Low),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyW) {
        camera_commands.insert_component(
          fxaa_value.with_sensitivity(@anti_alias.FxaaSensitivity::Medium),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyE) {
        camera_commands.insert_component(
          fxaa_value.with_sensitivity(@anti_alias.FxaaSensitivity::High),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyR) {
        camera_commands.insert_component(
          fxaa_value.with_sensitivity(@anti_alias.FxaaSensitivity::Ultra),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyT) {
        camera_commands.insert_component(
          fxaa_value.with_sensitivity(@anti_alias.FxaaSensitivity::Extreme),
        )
      }
    }
    None => ()
  }

  if keys.just_pressed(@window.KeyCode::Digit4) && smaa.value() is None {
    msaa.set(@anti_alias.Msaa::Off)
    camera_commands.remove(@anti_alias.ecs_key_fxaa)
    remove_taa_components(camera_commands)
    remove_dlss_components(camera_commands)
    camera_commands.insert_component(@anti_alias.Smaa::Smaa())
  }

  match smaa.value() {
    Some(smaa_value) => {
      if keys.just_pressed(@window.KeyCode::KeyQ) {
        camera_commands.insert_component(
          smaa_value.with_preset(@anti_alias.SmaaPreset::Low),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyW) {
        camera_commands.insert_component(
          smaa_value.with_preset(@anti_alias.SmaaPreset::Medium),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyE) {
        camera_commands.insert_component(
          smaa_value.with_preset(@anti_alias.SmaaPreset::High),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyR) {
        camera_commands.insert_component(
          smaa_value.with_preset(@anti_alias.SmaaPreset::Ultra),
        )
      }
    }
    None => ()
  }

  if keys.just_pressed(@window.KeyCode::Digit5) && taa.value() is None {
    msaa.set(@anti_alias.Msaa::Off)
    camera_commands.remove(@anti_alias.ecs_key_fxaa)
    camera_commands.remove(@anti_alias.ecs_key_smaa)
    remove_dlss_components(camera_commands)
    insert_taa_components(camera_commands)
  }
}

///|
fn modify_sharpening(
  keys : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[
    @ecs.Write[@anti_alias.ContrastAdaptiveSharpening],
    @ecs.All,
  ],
) -> Unit {
  try! query.for_each(fn(_entity, cas) {
    if keys.just_pressed(@window.KeyCode::Digit0) {
      cas.set(cas.value().with_enabled(!cas.value().enabled))
    }
    if cas.value().enabled {
      if keys.just_pressed(@window.KeyCode::Minus) {
        cas.set(
          cas
          .value()
          .with_sharpening_strength(
            clamp01(cas.value().sharpening_strength - 0.1F),
          ),
        )
      }
      if keys.just_pressed(@window.KeyCode::Equal) {
        cas.set(
          cas
          .value()
          .with_sharpening_strength(
            clamp01(cas.value().sharpening_strength + 0.1F),
          ),
        )
      }
      if keys.just_pressed(@window.KeyCode::KeyD) {
        cas.set(cas.value().with_denoise(!cas.value().denoise))
      }
    }
  })
}

///|
fn modify_projection(
  keys : @input.ButtonInput[@window.KeyCode],
  query : @ecs.Query[@ecs.Write[@pbr.Projection], @ecs.All],
) -> Unit {
  if !keys.just_pressed(@window.KeyCode::KeyO) {
    return
  }
  try! query.for_each(fn(_entity, projection) {
    match projection.value() {
      Perspective(_) =>
        projection.set(
          Orthographic(@pbr.OrthographicProjection3d::{
            ..@pbr.OrthographicProjection3d::default_3d(),
            scale: 0.002F,
          }),
        )
      _ =>
        projection.set(
          Perspective(@pbr.PerspectiveProjection3d::PerspectiveProjection3d()),
        )
    }
  })
}

///|
fn update_ui(
  camera : @app.Single[
    (
      @ecs.Read[@pbr.Projection],
      @ecs.Optional[@anti_alias.Fxaa],
      @ecs.Optional[@anti_alias.Smaa],
      @ecs.Optional[@anti_alias.TemporalAntiAliasing],
      @ecs.Read[@anti_alias.ContrastAdaptiveSharpening],
      @ecs.Read[@anti_alias.Msaa],
    ),
    @ecs.With[@camera.Camera3d],
  ],
  ui_text : @app.Single[@ecs.Write[@text.Text], @ecs.All],
) -> Unit {
  let (projection, fxaa, smaa, taa, cas, msaa) = camera.get()
  let fxaa_value = fxaa.value()
  let smaa_value = smaa.value()
  let taa_value = taa.value()
  let cas_value = cas.value()
  let msaa_value = msaa.value()
  let dlss_none = true
  let ui = StringBuilder::new()
  ui.write_string("Antialias Method\n")
  draw_selectable_menu_item(
    ui,
    "No AA",
    "1",
    msaa_value == @anti_alias.Msaa::Off &&
    fxaa_value is None &&
    taa_value is None &&
    smaa_value is None &&
    dlss_none,
  )
  draw_selectable_menu_item(
    ui,
    "MSAA",
    "2",
    msaa_value != @anti_alias.Msaa::Off,
  )
  draw_selectable_menu_item(ui, "FXAA", "3", fxaa_value is Some(_))
  draw_selectable_menu_item(ui, "SMAA", "4", smaa_value is Some(_))
  draw_selectable_menu_item(ui, "TAA", "5", taa_value is Some(_))

  if msaa_value != @anti_alias.Msaa::Off {
    ui.write_string("\n----------\n\nSample Count\n")
    draw_selectable_menu_item(
      ui,
      "2",
      "Q",
      msaa_value == @anti_alias.Msaa::Sample2,
    )
    draw_selectable_menu_item(
      ui,
      "4",
      "W",
      msaa_value == @anti_alias.Msaa::Sample4,
    )
    draw_selectable_menu_item(
      ui,
      "8",
      "E",
      msaa_value == @anti_alias.Msaa::Sample8,
    )
  }

  match fxaa_value {
    Some(fxaa) => {
      ui.write_string("\n----------\n\nSensitivity\n")
      draw_selectable_menu_item(
        ui,
        "Low",
        "Q",
        fxaa.edge_threshold == @anti_alias.FxaaSensitivity::Low,
      )
      draw_selectable_menu_item(
        ui,
        "Medium",
        "W",
        fxaa.edge_threshold == @anti_alias.FxaaSensitivity::Medium,
      )
      draw_selectable_menu_item(
        ui,
        "High",
        "E",
        fxaa.edge_threshold == @anti_alias.FxaaSensitivity::High,
      )
      draw_selectable_menu_item(
        ui,
        "Ultra",
        "R",
        fxaa.edge_threshold == @anti_alias.FxaaSensitivity::Ultra,
      )
      draw_selectable_menu_item(
        ui,
        "Extreme",
        "T",
        fxaa.edge_threshold == @anti_alias.FxaaSensitivity::Extreme,
      )
    }
    None => ()
  }

  match smaa_value {
    Some(smaa) => {
      ui.write_string("\n----------\n\nQuality\n")
      draw_selectable_menu_item(
        ui,
        "Low",
        "Q",
        smaa.preset == @anti_alias.SmaaPreset::Low,
      )
      draw_selectable_menu_item(
        ui,
        "Medium",
        "W",
        smaa.preset == @anti_alias.SmaaPreset::Medium,
      )
      draw_selectable_menu_item(
        ui,
        "High",
        "E",
        smaa.preset == @anti_alias.SmaaPreset::High,
      )
      draw_selectable_menu_item(
        ui,
        "Ultra",
        "R",
        smaa.preset == @anti_alias.SmaaPreset::Ultra,
      )
    }
    None => ()
  }

  ui.write_string("\n----------\n\n")
  draw_selectable_menu_item(ui, "Sharpening", "0", cas_value.enabled)
  if cas_value.enabled {
    ui.write_string(
      "(-/+) Strength: \{cas_value.sharpening_strength.to_string()}\n",
    )
    draw_selectable_menu_item(ui, "Denoising", "D", cas_value.denoise)
  }

  ui.write_string("\n----------\n\n")
  draw_selectable_menu_item(
    ui,
    "Orthographic",
    "O",
    projection.value() is Orthographic(_),
  )
  ui_text.get().set(@text.Text::new(ui.to_string()))
}

///|
fn uv_debug_texture(
  images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> @asset.Handle[@asset.Image] {
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

  let image = @asset.Image::new(
    TEXTURE_SIZE,
    TEXTURE_SIZE,
    Bytes::from_array(texture_data),
  ).with_format(Rgba8UnormSrgb)
  let handle = images.modify(fn(assets) { assets.add(image) })
  @asset.asset_set_texture_sampler(
    handle,
    @asset.ImageSampler::Descriptor(
      @asset.ImageSamplerDescriptor::ImageSamplerDescriptor(),
    ),
  )
  handle
}

///|
fn add_mesh_from_geometry(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  geometry : @mesh.Mesh3dGeometry,
) -> @asset.Handle[@mesh.Mesh] {
  meshes.modify(fn(assets) { assets |> @pbr.add_mesh(geometry) })
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let asset_server = asset_server.get()

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          add_mesh_from_geometry(
            meshes,
            @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
              @math.Vec2::new(20.0F, 20.0F),
            ).build(),
          ),
        ),
        @pbr.MeshMaterial3dTyped::new(
          materials.modify(fn(assets) {
            assets.add(
              @pbr.StandardMaterial::from_color(
                @color.Color::srgb(0.1F, 0.2F, 0.1F),
              ),
            )
          }),
        ),
      ),
    ),
  )

  let cube_material = materials.modify(fn(assets) {
    assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::white()).with_base_color_texture(
        Some(uv_debug_texture(images)),
      ),
    )
  })
  for i in 0..<5 {
    let i_f = Float::from_int(i)
    ignore(
      commands.spawn(
        (
          @mesh.Mesh3d::new(
            meshes.modify(fn(assets) {
              assets |> @pbr.add_mesh(@math.Cuboid::new(0.25F, 0.25F, 0.25F))
            }),
          ),
          @pbr.MeshMaterial3dTyped::new(cube_material),
          @transform.Transform::from_xyz(
            i_f * 0.25F - 1.0F,
            0.125F,
            -i_f * 0.5F,
          ),
        ),
      ),
    )
  }

  ignore(
    commands.spawn_component(
      @scene.WorldAssetRoot::new(
        @scene.scene_load_gltf_scene(
          asset_server,
          @gltf.GltfAssetLabel::Scene(0).from_asset(
            "models/FlightHelmet/FlightHelmet.gltf",
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight()
        .with_illuminance(110_000.0F)
        .with_shadow_maps_enabled(true),
        @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
        .with_maximum_distance(3.0F)
        .with_first_cascade_far_bound(0.9F)
        .build(),
        @transform.Transform::identity().with_rotation(
          @math.Quat::from_euler(
            @math.EulerRot::ZYX,
            0.0F,
            PI * -0.15F,
            PI * -0.15F,
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @camera_camera.Camera::Camera(),
        @anti_alias.Msaa::Off,
        @pbr.Hdr::Hdr(),
        @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
          @math.Vec3::new(0.0F, 0.3F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @anti_alias.ContrastAdaptiveSharpening::ContrastAdaptiveSharpening().with_enabled(
          false,
        ),
        @pbr.EnvironmentMapLight::new(
          Some(
            asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
          ),
          Some(
            asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
          ),
          150.0F,
        ),
        @pbr.DistanceFog::new(
          @color.Color::new(
            43.0F / 255.0F,
            44.0F / 255.0F,
            47.0F / 255.0F,
            1.0F,
          ),
          @pbr.FogFalloff3d::linear(1.0F, 4.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param5(@app.Startup, setup)
  .add_systems_param3(@app.Update, modify_aa)
  .add_systems_param2(@app.Update, modify_sharpening)
  .add_systems_param2(@app.Update, modify_projection)
  .add_systems_param2(@app.Update, update_ui)
  .run()
}
