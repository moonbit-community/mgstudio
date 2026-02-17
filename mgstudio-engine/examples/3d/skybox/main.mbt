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
/// Baseline parity: Bevy's native `Skybox` cubemap component, compressed-format
/// capability filtering via render-device features, and `FreeCameraPlugin` are
/// not currently exposed in mgstudio APIs. This port preserves the same startup
/// scene setup, timed cubemap rotation flow, and animated directional light,
/// while using a large textured-unlit cube as the skybox proxy.

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
  mut sky_material : @asset.Handle[@render3d.StandardMaterial]?
  mut next_swap_time : Float
  mut light_angle : Float
  mut directional_light : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let cubemap_state : Ref[CubemapState] = Ref::new({
  is_loaded: false,
  index: 0,
  image_handle: None,
  sky_material: None,
  next_swap_time: 0.0F,
  light_angle: 0.0F,
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
fn set_global_ambient_light(
  world : @ecs_world.World,
  color : @render2d.Color,
  brightness : Float,
) -> Unit {
  let tick = world.read_change_tick()
  let ambient = @render3d.GlobalAmbientLight::new(color, brightness)
  if world.get_global_ambient_light_resource().get_ref_mut(tick)
    is Some(current) {
    current.val = ambient
  } else {
    world.get_global_ambient_light_resource().insert(ambient, tick)
  }
}

///|
fn update_help_text() -> Unit {
  if cubemap_state.val.help_text is Some(handle) {
    let status = if cubemap_state.val.is_loaded {
      "Loaded"
    } else {
      "Loading..."
    }
    @text.text_set_content(
      handle,
      "skybox (Adapted)\n" +
      "Current cubemap: " +
      cubemap_path(cubemap_state.val.index) +
      "\n" +
      "Format: " +
      cubemap_format_name(cubemap_state.val.index) +
      "\n" +
      "Status: " +
      status +
      "\n\n" +
      "Auto-swap interval: 3s\n" +
      "Adapted runtime note: native Skybox + free camera path is replaced by a skybox proxy mesh.",
    )
  }
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  cubemap_state.val.is_loaded = false
  cubemap_state.val.index = 0
  cubemap_state.val.image_handle = None
  cubemap_state.val.sky_material = None
  cubemap_state.val.next_swap_time = 0.0F
  cubemap_state.val.light_angle = 0.0F
  cubemap_state.val.directional_light = None
  cubemap_state.val.help_text = None

  let tick = world.read_change_tick()

  let directional_light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 32_000.0F, true),
    tick,
  )
  world
  .get_transform_store()
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
    @render2d.Color::new(
      210.0F / 255.0F,
      220.0F / 255.0F,
      240.0F / 255.0F,
      1.0F,
    ),
    1.0F,
  )

  let camera_transform = @math.Transform::from_xyz(0.0F, 0.0F, 8.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  @render3d.Camera3dBundle::new(@render2d.Camera::default(), camera_transform).spawn(
    world,
  )
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let initial_image = asset_server.load(cubemap_path(0))
  cubemap_state.val.image_handle = Some(initial_image)

  let sky_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white())
    .with_base_color_texture(Some(initial_image))
    .with_unlit(true)
    .with_emissive(@render2d.Color::new(4.0F, 4.0F, 4.0F, 1.0F))
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )
  cubemap_state.val.sky_material = Some(sky_material)

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(200.0F, 200.0F, 200.0F),
    @render3d.MeshMaterial3d::new(sky_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 8.0F),
  ).spawn(world)
  |> ignore

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
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
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

  let new_index = (cubemap_state.val.index + 1) % CUBEMAP_COUNT
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
fn asset_loaded() -> Unit {
  if cubemap_state.val.is_loaded {
    return
  }
  guard cubemap_state.val.image_handle is Some(handle) else { return }
  if !@asset.asset_is_texture_loaded(handle) {
    return
  }
  guard cubemap_state.val.sky_material is Some(material_handle) else { return }
  guard @render3d.standard_material_get(material_handle) is Some(material) else {
    return
  }

  @render3d.standard_material_set(
    material_handle,
    material.with_base_color_texture(Some(handle)),
  )
  |> ignore

  cubemap_state.val.is_loaded = true
  update_help_text()
}

///|
fn animate_light_direction(world : @ecs_world.World) -> Unit {
  guard cubemap_state.val.directional_light is Some(light_entity) else {
    return
  }
  cubemap_state.val.light_angle = cubemap_state.val.light_angle +
    @time.time_delta_seconds() * 0.5F
  let x = @math.sin(cubemap_state.val.light_angle) * 2.0F
  let z = @math.cos(cubemap_state.val.light_angle) * 2.0F
  let tick = world.read_change_tick()
  world
  .get_transform_store()
  .set(
    light_entity,
    @math.Transform::from_xyz(x, 2.0F, z).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  |> ignore
}

///|
fn update(world : @ecs_world.World) -> Unit {
  cycle_cubemap_asset()
  asset_loaded()
  animate_light_direction(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(update)
  .run()
}
