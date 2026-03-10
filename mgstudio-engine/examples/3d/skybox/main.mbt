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
/// Port of `bevy/examples/3d/skybox.rs`.
///
/// Exact parity target: Bevy camera/light/cubemap-swap flow with runtime
/// compressed-format capability gating.

///|
const PI : Float = 3.141592653589793F

///|
const CUBEMAP_SWAP_DELAY : Float = 3.0F

///|
const CUBEMAP_COUNT : Int = 4

///|
priv struct CubemapState {
  mut is_loaded : Bool
  mut index : Int
  mut image_handle : @asset.Handle[@asset.Image]?
  mut supported_formats : Int
  mut camera : @core.Entity?
  mut next_swap_time : Float
  mut directional_light : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let cubemap_state : Ref[CubemapState] = Ref::new({
  is_loaded: false,
  index: 0,
  image_handle: None,
  supported_formats: 0,
  camera: None,
  next_swap_time: 0.0F,
  directional_light: None,
  help_text: None,
})

///|
fn cubemap_path(index : Int) -> String {
  if index == 0 {
    "textures/Ryfjallet_cubemap.png".to_string()
  } else if index == 1 {
    "textures/Ryfjallet_cubemap_astc4x4.ktx2".to_string()
  } else if index == 2 {
    "textures/Ryfjallet_cubemap_bc7.ktx2".to_string()
  } else {
    "textures/Ryfjallet_cubemap_etc2.ktx2".to_string()
  }
}

///|
fn cubemap_format_name(index : Int) -> String {
  if index == 0 {
    "PNG".to_string()
  } else if index == 1 {
    "ASTC 4x4 (KTX2)".to_string()
  } else if index == 2 {
    "BC7 (KTX2)".to_string()
  } else {
    "ETC2 (KTX2)".to_string()
  }
}

///|
fn cubemap_required_format(index : Int) -> Int {
  if index == 0 {
    @asset.COMPRESSED_IMAGE_FORMAT_NONE
  } else if index == 1 {
    @asset.COMPRESSED_IMAGE_FORMAT_ASTC_LDR
  } else if index == 2 {
    @asset.COMPRESSED_IMAGE_FORMAT_BC
  } else {
    @asset.COMPRESSED_IMAGE_FORMAT_ETC2
  }
}

///|
fn supported_format_tags(supported_formats : Int) -> String {
  let tags : Array[String] = ["PNG"]
  if @asset.asset_compressed_image_formats_contains(
      supported_formats,
      @asset.COMPRESSED_IMAGE_FORMAT_ASTC_LDR,
    ) {
    tags.push("ASTC")
  }
  if @asset.asset_compressed_image_formats_contains(
      supported_formats,
      @asset.COMPRESSED_IMAGE_FORMAT_BC,
    ) {
    tags.push("BC")
  }
  if @asset.asset_compressed_image_formats_contains(
      supported_formats,
      @asset.COMPRESSED_IMAGE_FORMAT_ETC2,
    ) {
    tags.push("ETC2")
  }
  let mut out = ""
  for i in 0..<tags.length() {
    if i > 0 {
      out = out + ","
    }
    out = out + tags[i]
  }
  out
}

///|
fn supports_any_compressed_cubemap_format(supported_formats : Int) -> Bool {
  @asset.asset_compressed_image_formats_contains(
    supported_formats,
    @asset.COMPRESSED_IMAGE_FORMAT_ASTC_LDR,
  ) ||
  @asset.asset_compressed_image_formats_contains(
    supported_formats,
    @asset.COMPRESSED_IMAGE_FORMAT_BC,
  ) ||
  @asset.asset_compressed_image_formats_contains(
    supported_formats,
    @asset.COMPRESSED_IMAGE_FORMAT_ETC2,
  )
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@render3d.ecs_key_global_ambient_light, ambient)
}

///|
fn update_help_text() -> Unit {
  if cubemap_state.val.help_text is Some(handle) {
    let status = if cubemap_state.val.is_loaded {
      "Loaded"
    } else {
      "Loading..."
    }
    let capability_note = if supports_any_compressed_cubemap_format(
        cubemap_state.val.supported_formats,
      ) {
      "Compressed cubemap cycling: enabled for runtime/GPU supported formats."
    } else {
      "Compressed cubemap cycling: no ASTC/BC/ETC2 support reported in this environment."
    }
    @text.text_set_content(
      handle,
      "skybox\n" +
      "Current cubemap: " +
      cubemap_path(cubemap_state.val.index) +
      "\n" +
      "Format: " +
      cubemap_format_name(cubemap_state.val.index) +
      "\n" +
      "Runtime supported formats: " +
      supported_format_tags(cubemap_state.val.supported_formats) +
      "\n" +
      "Status: " +
      status +
      "\n\n" +
      "Auto-swap interval: 3s\n" +
      "Controls:\n" +
      "  Hold left mouse: grab cursor and look around\n" +
      "  M: toggle cursor grab\n" +
      "  WASD/E/Q: move camera\n" +
      "  Shift: run\n" +
      "  Mouse wheel: adjust movement speed\n" +
      capability_note,
    )
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  cubemap_state.val.is_loaded = false
  cubemap_state.val.index = 0
  cubemap_state.val.image_handle = None
  cubemap_state.val.supported_formats = @asset.asset_supported_compressed_image_formats()
  cubemap_state.val.camera = None
  cubemap_state.val.next_swap_time = 0.0F
  cubemap_state.val.directional_light = None
  cubemap_state.val.help_text = None

  let tick = world.read_change_tick()

  let directional_light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@sprite.Color::white(), 32_000.0F, true),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional_light,
    @math.Transform::from_xyz(0.0F, 2.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_x(-PI / 4.0F),
    ),
    tick,
  )
  cubemap_state.val.directional_light = Some(directional_light)

  set_global_ambient_light(
    world,
    @sprite.Color::new(210.0F / 255.0F, 220.0F / 255.0F, 240.0F / 255.0F, 1.0F),
    1.0F,
  )

  let camera_transform = @math.Transform::from_xyz(0.0F, 0.0F, 8.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let camera = @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    camera_transform,
  ).spawn(world)
  world
  .component(@render3d.ecs_key_msaa)
  .insert(camera, @render3d.Msaa::Off, tick)
  world
  .component(@render3d.ecs_key_screen_space_ambient_occlusion)
  .insert(camera, @render3d.ScreenSpaceAmbientOcclusion::default(), tick)
  // Keep the Bevy TAA component surface for parity; web runtimes may treat it
  // as a marker/no-op until full backend parity is available.
  world
  .component(@render3d.ecs_key_temporal_anti_aliasing)
  .insert(camera, @render3d.TemporalAntiAliasing::default(), tick)
  world
  .component(@render3d.ecs_key_free_camera)
  .insert(camera, @render3d.FreeCamera::default(), tick)
  cubemap_state.val.camera = Some(camera)

  let asset_server = @asset.AssetServer::new()
  let initial_image = asset_server.load(cubemap_path(0))
  cubemap_state.val.image_handle = Some(initial_image)
  world
  .component(@render3d.ecs_key_skybox)
  .insert(camera, @render3d.Skybox::new(initial_image, 1000.0F), tick)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
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
  cubemap_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn cycle_cubemap_asset() -> Unit {
  let now = @time.time_elapsed_seconds()
  if cubemap_state.val.next_swap_time == 0.0F {
    cubemap_state.val.next_swap_time = now + CUBEMAP_SWAP_DELAY
    return
  } else if now < cubemap_state.val.next_swap_time {
    return
  }

  cubemap_state.val.next_swap_time = cubemap_state.val.next_swap_time +
    CUBEMAP_SWAP_DELAY

  cubemap_state.val.supported_formats = @asset.asset_supported_compressed_image_formats()
  let supported_formats = cubemap_state.val.supported_formats
  let mut new_index = cubemap_state.val.index
  for _ in 0..<CUBEMAP_COUNT {
    new_index = (new_index + 1) % CUBEMAP_COUNT
    if @asset.asset_compressed_image_formats_contains(
        supported_formats,
        cubemap_required_format(new_index),
      ) {
      break
    }
    println(
      "Skipping unsupported cubemap format: \{cubemap_format_name(new_index)}",
    )
  }
  if new_index == cubemap_state.val.index {
    return
  }

  cubemap_state.val.index = new_index
  cubemap_state.val.is_loaded = false
  let asset_server = @asset.AssetServer::new()
  cubemap_state.val.image_handle = Some(
    asset_server.load(cubemap_path(new_index)),
  )
  update_help_text()
}

///|
fn asset_loaded(world : @ecs.World) -> Unit {
  if cubemap_state.val.is_loaded {
    return
  }
  guard cubemap_state.val.image_handle is Some(handle) else { return }
  if !@asset.asset_is_texture_loaded(handle) {
    return
  }
  guard cubemap_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_change_tick()
  if world.component(@render3d.ecs_key_skybox).get(camera_entity)
    is Some(skybox) {
    println("Swapping to \{cubemap_path(cubemap_state.val.index)}")
    world
    .component(@render3d.ecs_key_skybox)
    .set(camera_entity, skybox.with_image(Some(handle)), tick)
    |> ignore
  }

  cubemap_state.val.is_loaded = true
  update_help_text()
}

///|
fn animate_light_direction(world : @ecs.World) -> Unit {
  guard cubemap_state.val.directional_light is Some(light_entity) else {
    return
  }
  if world.component(@math.ecs_key_transform).get(light_entity)
    is Some(transform) {
    let tick = world.read_change_tick()
    let next_rotation = transform.rotation
      .mul(@math.Quat::from_rotation_y(@time.time_delta_seconds() * 0.5F))
      .normalize()
    world
    .component(@math.ecs_key_transform)
    .set(light_entity, transform.with_rotation(next_rotation), tick)
    |> ignore
  }
}

///|
fn update(world : @ecs.World) -> Unit {
  cycle_cubemap_asset()
  asset_loaded(world)
  animate_light_direction(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@render3d.free_camera_plugin])
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(update))
  .run()
}
