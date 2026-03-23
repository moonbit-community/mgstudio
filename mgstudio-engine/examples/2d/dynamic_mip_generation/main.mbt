// Copyright 2025 International Digital Economy Academy
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
const ANIMATION_PERIOD : Float = 2.0F

///|
const MIP_SLICES_MARGIN_LEFT : Float = 64.0F

///|
const MIP_SLICES_MARGIN_RIGHT : Float = 12.0F

///|
const MIP_SLICES_WIDTH : Float = 0.16666667F

///|
const FONT_SIZE : Float = 16.0F

///|
priv enum EnableMipGeneration {
  On
  Off
} derive(Eq)

///|
priv enum ImageSize {
  Size240
  Size480
  Size640
  Size1080
  Size1920
} derive(Eq)

///|
priv enum AppSetting {
  RegenerateTopMipLevel
  EnableMipGeneration(EnableMipGeneration)
  ImageWidth(ImageSize)
  ImageHeight(ImageSize)
}

///|
priv struct AppStatus {
  mut enable_mip_generation : EnableMipGeneration
  mut image_width : ImageSize
  mut image_height : ImageSize
  rng : @random.Rand
}

///|
let app_status_resource_key : @ecs.ResourceKey[AppStatus] = @ecs.register_resource(
  debug_name="examples.2d.dynamic_mip_generation.AppStatus",
)

///|
impl @app.Resource for AppStatus with resource() {
  app_status_resource_key
}

///|
fn AppStatus::default() -> AppStatus {
  AppStatus::{
    enable_mip_generation: On,
    image_width: Size640,
    image_height: Size480,
    rng: seeded_rng(),
  }
}

///|
fn AppStatus::image_size(self : AppStatus) -> @math.UVec2 {
  @math.UVec2::new(
    image_size_to_int(self.image_width),
    image_size_to_int(self.image_height),
  )
}

///|
fn AppStatus::mip_level_sizes(self : AppStatus) -> Array[@math.UVec2] {
  let sizes : Array[@math.UVec2] = []
  let mut size = self.image_size()
  while true {
    sizes.push(size)
    if size.x == 1 && size.y == 1 {
      break
    }
    size = @math.UVec2::new(max_int(size.x / 2, 1), max_int(size.y / 2, 1))
  }
  sizes
}

///|
fn AppStatus::animated_mesh_area_size(
  self : AppStatus,
  window_size : @math.Vec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    self.horizontal_mip_slice_origin(window_size) * 2.0F -
    MIP_SLICES_MARGIN_LEFT * 2.0F,
    window_size.y,
  )
}

///|
fn AppStatus::animated_mesh_size(
  self : AppStatus,
  window_size : @math.Vec2,
) -> @math.Vec2 {
  let max_image_size = self.animated_mesh_area_size(window_size)
  let image_size = @math.Vec2::new(
    int_to_float(image_size_to_int(self.image_width)),
    int_to_float(image_size_to_int(self.image_height)),
  )
  let ratios = vec2_component_div(max_image_size, image_size)
  let image_scale = min_float(ratios.x, ratios.y)
  vec2_scale(image_size, image_scale)
}

///|
fn AppStatus::vertical_mip_slice_spacing(
  self : AppStatus,
  window_size : @math.Vec2,
) -> Float {
  window_size.y / int_to_float(max_int(self.mip_level_sizes().length(), 1))
}

///|
fn AppStatus::vertical_mip_slice_origin(
  self : AppStatus,
  window_size : @math.Vec2,
) -> Float {
  let spacing = self.vertical_mip_slice_spacing(window_size)
  window_size.y * 0.5F - spacing * 0.5F
}

///|
fn AppStatus::max_mip_slice_size(
  self : AppStatus,
  window_size : @math.Vec2,
) -> @math.Vec2 {
  let spacing = self.vertical_mip_slice_spacing(window_size)
  @math.Vec2::new(window_size.x * MIP_SLICES_WIDTH, spacing)
}

///|
fn AppStatus::horizontal_mip_slice_origin(
  self : AppStatus,
  window_size : @math.Vec2,
) -> Float {
  let max_slice_size = self.max_mip_slice_size(window_size)
  window_size.x * 0.5F - max_slice_size.x * 0.5F - MIP_SLICES_MARGIN_RIGHT
}

///|
priv struct AppAssets {
  text_font : @text.TextFont
}

///|
let app_assets_resource_key : @ecs.ResourceKey[AppAssets] = @ecs.register_resource(
  debug_name="examples.2d.dynamic_mip_generation.AppAssets",
)

///|
impl @app.Resource for AppAssets with resource() {
  app_assets_resource_key
}

///|
fn AppAssets::new(asset_server : @asset.AssetServer) -> AppAssets {
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  AppAssets::{
    text_font: @text.TextFont::default()
    .with_font(font)
    .with_font_size(FONT_SIZE),
  }
}

///|
struct AnimatedImage {}

///|
let animated_image_key : @ecs.ComponentKey[AnimatedImage] = @ecs.register_component(
  debug_name="examples.2d.dynamic_mip_generation.AnimatedImage",
)

///|
pub impl @ecs.Component for AnimatedImage with component() {
  animated_image_key
}

///|
struct ImageView {}

///|
let image_view_key : @ecs.ComponentKey[ImageView] = @ecs.register_component(
  debug_name="examples.2d.dynamic_mip_generation.ImageView",
)

///|
pub impl @ecs.Component for ImageView with component() {
  image_view_key
}

///|
struct RegenerateImage {}

///|
let regenerate_image_key : @ecs.MessageKey[RegenerateImage] = @ecs.register_message(
  debug_name="examples.2d.dynamic_mip_generation.RegenerateImage",
)

///|
pub impl @ecs.Message for RegenerateImage with message() {
  regenerate_image_key
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets.WidgetClickEvent[AppSetting],
  ] = @widgets.widget_click_event_key()
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(setup),
  )
  let handle_widget_interactions_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(handle_widget_interactions),
  )
  let handle_app_setting_change_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(handle_app_setting_change),
  )
  let update_radio_buttons_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(update_radio_buttons),
  )
  let handle_resize_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(handle_window_resize_events),
  )
  let regenerate_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param6(regenerate_image_when_requested),
  )
  let animate_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(animate_image_scale),
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(AppStatus::default)
  .add_message(regenerate_image_key)
  .add_message(widget_click_message_key)
  .add_systems(@app.Startup, setup_system)
  .add_systems(
    @app.Update,
    (
      handle_widget_interactions_system, handle_app_setting_change_system, update_radio_buttons_system,
    )
    |> @app.chain(),
  )
  .add_systems(
    @app.Update,
    (handle_resize_system, regenerate_system) |> @app.chain(),
  )
  .add_systems(@app.Update, animate_system)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  regenerate_writer : @ecs.MessageWriter[RegenerateImage],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  commands.insert_resource(AppAssets::new(asset_server.get()))
  spawn_ui(commands)
  ignore(regenerate_writer.write(RegenerateImage::{  }))
}

///|
fn spawn_ui(commands : @app.Commands) -> Unit {
  let root = commands.spawn((@ui.UiRoot::default(), @widgets.main_ui_node()))

  ignore(
    @widgets.spawn_action_button(
      commands,
      root,
      AppSetting::RegenerateTopMipLevel,
      "Regenerate Top Mip Level",
    ),
  )
  ignore(
    @widgets.spawn_option_buttons(
      commands,
      root,
      "Mip Generation",
      [
        (AppSetting::EnableMipGeneration(On), "On"),
        (AppSetting::EnableMipGeneration(Off), "Off"),
      ],
      0,
    ),
  )
  ignore(
    @widgets.spawn_option_buttons(
      commands,
      root,
      "Image Width",
      [
        (AppSetting::ImageWidth(Size240), "240"),
        (AppSetting::ImageWidth(Size480), "480"),
        (AppSetting::ImageWidth(Size640), "640"),
        (AppSetting::ImageWidth(Size1080), "1080"),
        (AppSetting::ImageWidth(Size1920), "1920"),
      ],
      2,
    ),
  )
  ignore(
    @widgets.spawn_option_buttons(
      commands,
      root,
      "Image Height",
      [
        (AppSetting::ImageHeight(Size240), "240"),
        (AppSetting::ImageHeight(Size480), "480"),
        (AppSetting::ImageHeight(Size640), "640"),
        (AppSetting::ImageHeight(Size1080), "1080"),
        (AppSetting::ImageHeight(Size1920), "1920"),
      ],
      1,
    ),
  )
}

///|
fn handle_widget_interactions(
  interactions : @ecs.Query2Filtered[
    @ui.Interaction,
    @widgets.WidgetClickSender[AppSetting],
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets.WidgetClickEvent[AppSetting],
  ],
) -> Unit {
  @widgets.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query2RefMutFiltered[
    @widgets.WidgetClickSender[AppSetting],
    @ui.BackgroundColor,
    @ecs.With[@widgets.RadioButton],
  ],
  radio_button_texts : @ecs.Query2RefMutFiltered[
    @widgets.WidgetClickSender[AppSetting],
    @text.TextColor,
    @ecs.With[@widgets.RadioButtonText],
  ],
  app_status : @app.Res[AppStatus],
) -> Unit {
  let status = app_status.get()

  try! radio_buttons.view_mut(fn(_entity, sender, background_color) {
    @widgets.update_ui_radio_button(
      background_color,
      app_setting_selected(sender.value().get(), status),
    )
  })

  try! radio_button_texts.view_mut(fn(_entity, sender, text_color) {
    @widgets.update_ui_radio_button_text(
      text_color,
      app_setting_selected(sender.value().get(), status),
    )
  })
}

///|
fn app_setting_selected(setting : AppSetting, app_status : AppStatus) -> Bool {
  match setting {
    AppSetting::RegenerateTopMipLevel => false
    AppSetting::EnableMipGeneration(enable_mip_generation) =>
      enable_mip_generation == app_status.enable_mip_generation
    AppSetting::ImageWidth(image_width) => image_width == app_status.image_width
    AppSetting::ImageHeight(image_height) =>
      image_height == app_status.image_height
  }
}

///|
fn handle_app_setting_change(
  events : @ecs.MessageReader[@widgets.WidgetClickEvent[AppSetting]],
  app_status : @app.ResMut[AppStatus],
  regenerate_writer : @ecs.MessageWriter[RegenerateImage],
) -> Unit {
  let status_ref = app_status.get_ref()
  let mut should_regenerate = false

  for event in (try! events.read()) {
    match event.get() {
      AppSetting::RegenerateTopMipLevel => should_regenerate = true
      AppSetting::EnableMipGeneration(enable_mip_generation) =>
        if status_ref.val.enable_mip_generation != enable_mip_generation {
          status_ref.val.enable_mip_generation = enable_mip_generation
          should_regenerate = true
        }
      AppSetting::ImageWidth(image_size) =>
        if status_ref.val.image_width != image_size {
          status_ref.val.image_width = image_size
          should_regenerate = true
        }
      AppSetting::ImageHeight(image_size) =>
        if status_ref.val.image_height != image_size {
          status_ref.val.image_height = image_size
          should_regenerate = true
        }
    }
  }

  if should_regenerate {
    ignore(regenerate_writer.write(RegenerateImage::{  }))
  }
}

///|
fn handle_window_resize_events(
  resized_events : @ecs.MessageReader[@window.WindowResized],
  regenerate_writer : @ecs.MessageWriter[RegenerateImage],
) -> Unit {
  for _event in (try! resized_events.read()) {
    ignore(regenerate_writer.write(RegenerateImage::{  }))
  }
}

///|
fn regenerate_image_when_requested(
  commands : @app.Commands,
  image_views : @ecs.Query1[ImageView],
  windows : @ecs.Query1Filtered[
    @window.Window,
    @ecs.With[@window.PrimaryWindow],
  ],
  app_status : @app.ResMut[AppStatus],
  app_assets : @app.Res[AppAssets],
  regenerate_reader : @ecs.MessageReader[RegenerateImage],
) -> Unit {
  if (try! regenerate_reader.read()).length() == 0 {
    return
  }

  try! image_views.for_each(fn(entity, _view) {
    commands.entity(entity).despawn()
  })

  let status_ref = app_status.get_ref()
  let levels = generate_image_levels(status_ref)

  if levels.length() == 0 {
    return
  }

  let (source_texture, mip_views) = regenerate_mipmap_source_image(
    levels,
    status_ref.val.enable_mip_generation,
  )

  let window_size = primary_window_size(windows)
  spawn_animated_mesh(commands, status_ref.val, window_size, source_texture)
  spawn_mip_level_views(
    commands,
    status_ref.val,
    app_assets.get(),
    window_size,
    mip_views,
  )
}

///|
fn animate_image_scale(
  animated_images : @ecs.Query1Filtered[
    @transform.Transform,
    @ecs.With[AnimatedImage],
  ],
  windows : @ecs.Query1Filtered[
    @window.Window,
    @ecs.With[@window.PrimaryWindow],
  ],
  app_status : @app.Res[AppStatus],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let next_scale = vec2_scale(
    app_status.get().animated_mesh_size(primary_window_size(windows)),
    triangle_wave(time.get().elapsed_seconds(), ANIMATION_PERIOD),
  )

  try! animated_images.view_mut(fn(_entity, transform) {
    transform.get_ref().val.scale = @math.Vec3::new(
      next_scale.x,
      next_scale.y,
      1.0F,
    )
    transform.set_changed()
  })
}

///|
fn spawn_animated_mesh(
  commands : @app.Commands,
  app_status : AppStatus,
  window_size : @math.Vec2,
  source_texture : @asset.Handle[@asset.Image],
) -> Unit {
  let area_size = app_status.animated_mesh_area_size(window_size)
  let image_size = app_status.animated_mesh_size(window_size)
  let entity = commands.spawn(
    @sprite.SpriteBundle::new(
      @sprite.Sprite::from_image(source_texture).with_custom_size(
        Some(@math.Vec2::new(1.0F, 1.0F)),
      ),
      @transform.Transform::from_xy_rotation_scale(
        vec2_sub(vec2_scale(area_size, 0.5F), vec2_scale(window_size, 0.5F)),
        0.0F,
        image_size,
      ),
    ),
  )
  commands.entity(entity).insert((AnimatedImage::{  }, ImageView::{  }))
}

///|
fn spawn_mip_level_views(
  commands : @app.Commands,
  app_status : AppStatus,
  app_assets : AppAssets,
  window_size : @math.Vec2,
  textures : Array[@asset.Handle[@asset.Image]],
) -> Unit {
  let sizes = app_status.mip_level_sizes()
  if textures.length() == 0 || sizes.length() == 0 {
    return
  }

  let max_slice_size = app_status.max_mip_slice_size(window_size)
  let y_origin = app_status.vertical_mip_slice_origin(window_size)
  let y_spacing = app_status.vertical_mip_slice_spacing(window_size)
  let x_origin = app_status.horizontal_mip_slice_origin(window_size)
  let label_x = x_origin - max_slice_size.x * 0.5F - 64.0F

  for i in 0..<min_int(textures.length(), sizes.length()) {
    let mip_size = sizes[i]
    let mip_size_f32 = @math.Vec2::new(
      int_to_float(mip_size.x),
      int_to_float(mip_size.y),
    )
    let ratios = vec2_component_div(max_slice_size, mip_size_f32)
    let slice_scale = min_float(min_float(ratios.x, ratios.y), 1.0F)
    let final_size = vec2_scale(mip_size_f32, slice_scale)
    let y_center = y_origin - y_spacing * int_to_float(i)

    let sprite_entity = commands.spawn(
      @sprite.SpriteBundle::new(
        @sprite.Sprite::from_image(textures[i]).with_custom_size(
          Some(@math.Vec2::new(1.0F, 1.0F)),
        ),
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(x_origin, y_center),
          0.0F,
          final_size,
        ),
      ),
    )
    commands.entity(sprite_entity).insert_component(ImageView::{  })

    ignore(
      commands.spawn(
        (
          @text.Text2d::new(mip_level_label(i, mip_size)),
          app_assets.text_font,
          @text.TextLayout::new_with_justify(@text.Justify::Center),
          @text.Text2dShadow::default(),
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(label_x, y_center),
            0.0F,
            @math.Vec2::new(1.0F, 1.0F),
          ),
          ImageView::{  },
        ),
      ),
    )
  }
}

///|
fn mip_level_label(level : Int, size : @math.UVec2) -> String {
  "Level " +
  level.to_string() +
  "\n" +
  size.x.to_string() +
  "x" +
  size.y.to_string()
}

///|
fn generate_image_levels(
  app_status_ref : Ref[AppStatus],
) -> Array[(Int, Int, Bytes)] {
  let image_size = app_status_ref.val.image_size()
  let image_data = generate_image_data(
    app_status_ref,
    image_size.x,
    image_size.y,
  )
  @asset.asset_generate_mip_chain_rgba8(image_size.x, image_size.y, image_data)
}

///|
fn regenerate_mipmap_source_image(
  levels : Array[(Int, Int, Bytes)],
  enable_mip_generation : EnableMipGeneration,
) -> (@asset.Handle[@asset.Image], Array[@asset.Handle[@asset.Image]]) {
  let mip_views : Array[@asset.Handle[@asset.Image]] = []
  let base_level = levels[0]
  let base_size = @math.UVec2::new(base_level.0, base_level.1)
  let source_texture = @asset.asset_create_dynamic_texture_with_mips(
    base_size,
    levels.length(),
    false,
  )

  for i in 0..<levels.length() {
    let level = levels[i]
    let size = @math.UVec2::new(level.0, level.1)
    let pixels = if i == 0 || enable_mip_generation == On {
      level.2
    } else {
      Bytes::make(level.0 * level.1 * 4, (0).to_byte())
    }
    @asset.asset_update_texture_region_rgba8_mip(
      source_texture,
      @math.URect::new(@math.UVec2::zero(), size),
      i,
      pixels,
    )
    mip_views.push(@asset.asset_create_texture_mip_view(source_texture, i))
  }

  (source_texture, mip_views)
}

///|
fn generate_image_data(
  app_status_ref : Ref[AppStatus],
  width : Int,
  height : Int,
) -> Bytes {
  let outer_color = random_rgb_color(app_status_ref.val.rng)
  let inner_color = random_rgb_color(app_status_ref.val.rng)

  let center = vec2_scale(
    @math.Vec2::new(int_to_float(width), int_to_float(height)),
    0.5F,
  )
  let inner_radii = vec2_scale(center, 0.5F)
  let outer_radii = center

  let pixels : Array[Byte] = []
  for y in 0..<height {
    for x in 0..<width {
      let point = @math.Vec2::new(int_to_float(x), int_to_float(y))
      let in_inner = point_in_ellipse(point, center, inner_radii)
      let in_outer = point_in_ellipse(point, center, outer_radii)

      if in_inner {
        pixels.push(inner_color.0)
        pixels.push(inner_color.1)
        pixels.push(inner_color.2)
        pixels.push((255).to_byte())
      } else if in_outer {
        pixels.push(outer_color.0)
        pixels.push(outer_color.1)
        pixels.push(outer_color.2)
        pixels.push((255).to_byte())
      } else {
        pixels.push((0).to_byte())
        pixels.push((0).to_byte())
        pixels.push((0).to_byte())
        pixels.push((0).to_byte())
      }
    }
  }

  Bytes::from_array(pixels)
}

///|
fn point_in_ellipse(
  point : @math.Vec2,
  center : @math.Vec2,
  radii : @math.Vec2,
) -> Bool {
  let dx = (point.x - center.x) / radii.x
  let dy = (point.y - center.y) / radii.y
  dx * dx + dy * dy < 1.0F
}

///|
fn triangle_wave(time : Float, wavelength : Float) -> Float {
  let normalized = time / wavelength
  let whole_cycles = normalized.to_int()
  let phase = normalized - int_to_float(whole_cycles)
  if phase < 0.5F {
    phase * 2.0F
  } else {
    (1.0F - phase) * 2.0F
  }
}

///|
fn image_size_to_int(size : ImageSize) -> Int {
  match size {
    Size240 => 240
    Size480 => 480
    Size640 => 640
    Size1080 => 1080
    Size1920 => 1920
  }
}

///|
fn primary_window_size(
  windows : @ecs.Query1Filtered[
    @window.Window,
    @ecs.With[@window.PrimaryWindow],
  ],
) -> @math.Vec2 {
  if (try! windows.single()) is Some(window) {
    @math.Vec2::new(
      max_float(window.width(), 1.0F),
      max_float(window.height(), 1.0F),
    )
  } else {
    @math.Vec2::new(1.0F, 1.0F)
  }
}

///|
fn random_rgb_color(rng : @random.Rand) -> (Byte, Byte, Byte) {
  (
    rng.int(limit=256).to_byte(),
    rng.int(limit=256).to_byte(),
    rng.int(limit=256).to_byte(),
  )
}

///|
fn seeded_rng() -> @random.Rand {
  @random.Rand::chacha8(seed=b"bevy-dynmip-seed-x19878367467713")
}

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn vec2_scale(v : @math.Vec2, s : Float) -> @math.Vec2 {
  @math.Vec2::new(v.x * s, v.y * s)
}

///|
fn vec2_sub(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x - b.x, a.y - b.y)
}

///|
fn vec2_component_div(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x / b.x, a.y / b.y)
}
