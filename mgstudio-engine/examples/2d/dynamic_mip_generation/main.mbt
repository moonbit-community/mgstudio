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
const MAX_MIP_LABEL_COUNT : Int = 16

///|
priv enum EnableMipGeneration {
  On
  Off
}

///|
priv enum ImageSize {
  Size240
  Size480
  Size640
  Size1080
  Size1920
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
priv struct DynamicMipState {
  mut help_text : @text.TextHandle?
  mut mip_label_handles : Array[@text.TextHandle]
  mut source_texture : @asset.Handle[@asset.Image]?
  mut mip_views : Array[@asset.Handle[@asset.Image]]
  mut mip_sizes : Array[@math.UVec2]
  mut current_level : Int
}

///|
let dynamic_mip_state_resource_key : @ecs.ResourceKey[DynamicMipState] = @ecs.register_resource(
  debug_name="examples.2d.dynamic_mip_generation.DynamicMipState",
)

///|
impl @app.Resource for DynamicMipState with resource() {
  dynamic_mip_state_resource_key
}

///|
fn DynamicMipState::default() -> DynamicMipState {
  DynamicMipState::{
    help_text: None,
    mip_label_handles: [],
    source_texture: None,
    mip_views: [],
    mip_sizes: [],
    current_level: 0,
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
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(setup),
  )
  let handle_input_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(handle_app_setting_input),
  )
  let handle_resize_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(handle_window_resize_events),
  )
  let regenerate_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param5(regenerate_image_when_requested),
  )
  let animate_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(animate_image_scale),
  )
  let help_text_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(update_help_text),
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(AppStatus::default)
  .init_resource(DynamicMipState::default)
  .add_message(regenerate_image_key)
  .add_systems(@app.Startup, setup_system)
  .add_systems(
    @app.Update,
    (
      handle_input_system, handle_resize_system, regenerate_system, animate_system,
      help_text_system,
    )
    |> @app.chain(),
  )
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  dynamic_state : @app.ResMut[DynamicMipState],
  regenerate_writer : @ecs.MessageWriter[RegenerateImage],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let state_ref = dynamic_state.get_ref()
  state_ref.val.help_text = Some(spawn_help_overlay(commands, font))
  state_ref.val.mip_label_handles = spawn_mip_level_labels(font)

  ignore(regenerate_writer.write(RegenerateImage::{  }))
}

///|
fn handle_app_setting_input(
  key_input : @input.ButtonInput[@window.KeyCode],
  app_status : @app.ResMut[AppStatus],
  regenerate_writer : @ecs.MessageWriter[RegenerateImage],
) -> Unit {
  let status_ref = app_status.get_ref()
  let mut should_regenerate = false

  if key_input.just_pressed(@window.KeyCode::KeyR) {
    should_regenerate = true
  }

  if key_input.just_pressed(@window.KeyCode::KeyM) {
    status_ref.val.enable_mip_generation = toggle_mip_generation(
      status_ref.val.enable_mip_generation,
    )
    should_regenerate = true
  }

  if key_input.just_pressed(@window.KeyCode::KeyQ) {
    status_ref.val.image_width = previous_image_size(status_ref.val.image_width)
    should_regenerate = true
  }

  if key_input.just_pressed(@window.KeyCode::KeyA) {
    status_ref.val.image_width = next_image_size(status_ref.val.image_width)
    should_regenerate = true
  }

  if key_input.just_pressed(@window.KeyCode::KeyW) {
    status_ref.val.image_height = previous_image_size(
      status_ref.val.image_height,
    )
    should_regenerate = true
  }

  if key_input.just_pressed(@window.KeyCode::KeyS) {
    status_ref.val.image_height = next_image_size(status_ref.val.image_height)
    should_regenerate = true
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
  app_status : @app.ResMut[AppStatus],
  dynamic_state : @app.ResMut[DynamicMipState],
  regenerate_reader : @ecs.MessageReader[RegenerateImage],
) -> Unit {
  if (try! regenerate_reader.read()).length() == 0 {
    return
  }

  try! image_views.for_each(fn(entity, _view) {
    commands.entity(entity).despawn()
  })

  let status_ref = app_status.get_ref()
  let state_ref = dynamic_state.get_ref()
  clear_all_mip_labels(state_ref.val.mip_label_handles)

  let levels = generate_image_levels(status_ref)
  if levels.length() == 0 {
    reset_dynamic_mip_state(state_ref)
    return
  }

  let (source_texture, mip_views, sizes) = create_mip_textures(
    levels,
    status_ref.val.enable_mip_generation,
  )
  if mip_views.length() == 0 {
    reset_dynamic_mip_state(state_ref)
    return
  }

  state_ref.val.source_texture = Some(source_texture)
  state_ref.val.mip_views = mip_views
  state_ref.val.mip_sizes = sizes
  state_ref.val.current_level = 0

  let window_size = current_window_size()
  spawn_animated_mesh(commands, state_ref.val, status_ref.val, window_size)
  spawn_mip_level_views(commands, state_ref.val, window_size)
}

///|
fn animate_image_scale(
  animated_images : @ecs.Query1Filtered[
    @transform.Transform,
    @ecs.With[AnimatedImage],
  ],
  app_status : @app.Res[AppStatus],
  dynamic_state : @app.ResMut[DynamicMipState],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let state_ref = dynamic_state.get_ref()
  let mip_count = state_ref.val.mip_sizes.length()
  if mip_count == 0 {
    return
  }

  let window_size = current_window_size()
  let animated_size = animated_mesh_size(
    app_status.get(),
    window_size,
    mip_count,
  )
  let wave = triangle_wave(time.get().elapsed_seconds(), ANIMATION_PERIOD)
  let next_scale = vec2_scale(animated_size, wave)

  try! animated_images.view_mut(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.scale = @math.Vec3::new(next_scale.x, next_scale.y, 1.0F)
    transform.set_changed()
  })

  let display_size = max_float(next_scale.x, next_scale.y)
  state_ref.val.current_level = pick_mip_level(
    display_size,
    app_status.get(),
    mip_count,
  )
}

///|
fn update_help_text(
  dynamic_state : @app.Res[DynamicMipState],
  app_status : @app.Res[AppStatus],
) -> Unit {
  if dynamic_state.get().help_text is Some(handle) {
    @text.text_set_content(
      handle,
      help_text_content(app_status.get(), dynamic_state.get().current_level),
    )
  }
}

///|
fn spawn_animated_mesh(
  commands : @app.Commands,
  dynamic_state : DynamicMipState,
  app_status : AppStatus,
  window_size : @math.Vec2,
) -> Unit {
  guard dynamic_state.source_texture is Some(source_texture) else { return }

  let area_size = animated_mesh_area_size(
    window_size,
    dynamic_state.mip_sizes.length(),
  )
  let image_size = animated_mesh_size(
    app_status,
    window_size,
    dynamic_state.mip_sizes.length(),
  )
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
  dynamic_state : DynamicMipState,
  window_size : @math.Vec2,
) -> Unit {
  let textures = dynamic_state.mip_views
  let sizes = dynamic_state.mip_sizes
  let level_count = sizes.length()
  if textures.length() == 0 || level_count == 0 {
    return
  }

  let max_slice_size = max_mip_slice_size(window_size, level_count)
  let y_origin = vertical_mip_slice_origin(window_size, level_count)
  let y_spacing = vertical_mip_slice_spacing(window_size, level_count)
  let x_origin = horizontal_mip_slice_origin(window_size, level_count)
  let label_x = x_origin - max_slice_size.x * 0.5F - 64.0F

  for i in 0..<level_count {
    let mip_size = sizes[i]
    let mip_size_f32 = @math.Vec2::new(
      int_to_float(mip_size.x),
      int_to_float(mip_size.y),
    )
    let ratios = vec2_component_div(max_slice_size, mip_size_f32)
    let slice_scale = min_float(min_float(ratios.x, ratios.y), 1.0F)
    let final_size = vec2_scale(mip_size_f32, slice_scale)
    let y_center = y_origin - y_spacing * int_to_float(i)

    let entity = commands.spawn(
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
    commands.entity(entity).insert_component(ImageView::{  })
    update_mip_label(
      dynamic_state.mip_label_handles,
      i,
      mip_size,
      label_x,
      y_center,
    )
  }
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  font : @asset.Handle[@asset.Font],
) -> @text.TextHandle {
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
      @transform.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
        @ui.UiText::new(text_handle),
      ),
    ),
  )

  text_handle
}

///|
fn spawn_mip_level_labels(
  font : @asset.Handle[@asset.Font],
) -> Array[@text.TextHandle] {
  let handles : Array[@text.TextHandle] = []
  for _ in 0..<MAX_MIP_LABEL_COUNT {
    let handle = @text.Text2dBundle::new(
        @text.Text2d::new(""),
        @text.TextFont::default().with_font(font).with_font_size(FONT_SIZE),
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(-10000.0F, -10000.0F),
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
        ),
      )
      .with_color(@text.TextColor::new(@sprite.Color::white()))
      .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
      .spawn()
    handles.push(handle)
  }
  handles
}

///|
fn clear_all_mip_labels(handles : Array[@text.TextHandle]) -> Unit {
  for handle in handles {
    @text.text_set_content(handle, "")
    @text.text_set_transform(
      handle,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-10000.0F, -10000.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      ),
    )
  }
}

///|
fn update_mip_label(
  handles : Array[@text.TextHandle],
  level : Int,
  size : @math.UVec2,
  x : Float,
  y : Float,
) -> Unit {
  if level >= handles.length() {
    return
  }

  let handle = handles[level]
  @text.text_set_content(
    handle,
    "Level " +
    level.to_string() +
    "\n" +
    size.x.to_string() +
    "x" +
    size.y.to_string(),
  )
  @text.text_set_transform(
    handle,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(x, y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
}

///|
fn reset_dynamic_mip_state(state_ref : Ref[DynamicMipState]) -> Unit {
  state_ref.val.source_texture = None
  state_ref.val.mip_views.clear()
  state_ref.val.mip_sizes.clear()
  state_ref.val.current_level = 0
}

///|
fn generate_image_levels(
  app_status_ref : Ref[AppStatus],
) -> Array[(Int, Int, Bytes)] {
  let width = image_size_to_int(app_status_ref.val.image_width)
  let height = image_size_to_int(app_status_ref.val.image_height)
  let image_data = generate_image_data(app_status_ref, width, height)
  @asset.asset_generate_mip_chain_rgba8(width, height, image_data)
}

///|
fn create_mip_textures(
  levels : Array[(Int, Int, Bytes)],
  enable_mip_generation : EnableMipGeneration,
) -> (
  @asset.Handle[@asset.Image],
  Array[@asset.Handle[@asset.Image]],
  Array[@math.UVec2],
) {
  let mip_views : Array[@asset.Handle[@asset.Image]] = []
  let sizes : Array[@math.UVec2] = []
  let base_level = levels[0]
  let base_size = @math.UVec2::new(base_level.0, base_level.1)
  let source_texture = @asset.asset_create_dynamic_texture_with_mips(
    base_size,
    levels.length(),
    false,
  )

  for i in 0..<levels.length() {
    let level = levels[i]
    let width = level.0
    let height = level.1
    let size = @math.UVec2::new(width, height)
    let pixels = if i == 0 || is_mip_generation_on(enable_mip_generation) {
      level.2
    } else {
      Bytes::make(width * height * 4, (0).to_byte())
    }
    @asset.asset_update_texture_region_rgba8_mip(
      source_texture,
      @math.URect::new(@math.UVec2::zero(), size),
      i,
      pixels,
    )
    mip_views.push(@asset.asset_create_texture_mip_view(source_texture, i))
    sizes.push(size)
  }

  (source_texture, mip_views, sizes)
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
fn pick_mip_level(
  display_size : Float,
  app_status : AppStatus,
  mip_count : Int,
) -> Int {
  if mip_count <= 1 {
    return 0
  }

  if display_size <= 0.0F {
    return mip_count - 1
  }

  let base_size = int_to_float(
    max_int(
      image_size_to_int(app_status.image_width),
      image_size_to_int(app_status.image_height),
    ),
  )

  let mut ratio = base_size / display_size
  if ratio < 1.0F {
    ratio = 1.0F
  }

  let mut level = 0
  while ratio >= 2.0F && level + 1 < mip_count {
    ratio = ratio * 0.5F
    level = level + 1
  }

  level
}

///|
fn help_text_content(app_status : AppStatus, current_level : Int) -> String {
  "Regenerate Top Mip Level: (R)\n" +
  "Toggle Mip Generation: (M) " +
  enable_mip_generation_text(app_status.enable_mip_generation) +
  "\n" +
  "Image Width: (Q/A) " +
  image_size_to_int(app_status.image_width).to_string() +
  "\n" +
  "Image Height: (W/S) " +
  image_size_to_int(app_status.image_height).to_string() +
  "\n" +
  "Current Displayed Mip: " +
  current_level.to_string() +
  "\n"
}

///|
fn enable_mip_generation_text(setting : EnableMipGeneration) -> String {
  match setting {
    On => "On"
    Off => "Off"
  }
}

///|
fn is_mip_generation_on(setting : EnableMipGeneration) -> Bool {
  match setting {
    On => true
    Off => false
  }
}

///|
fn toggle_mip_generation(setting : EnableMipGeneration) -> EnableMipGeneration {
  match setting {
    On => Off
    Off => On
  }
}

///|
fn next_image_size(size : ImageSize) -> ImageSize {
  match size {
    Size240 => Size480
    Size480 => Size640
    Size640 => Size1080
    Size1080 => Size1920
    Size1920 => Size240
  }
}

///|
fn previous_image_size(size : ImageSize) -> ImageSize {
  match size {
    Size240 => Size1920
    Size480 => Size240
    Size640 => Size480
    Size1080 => Size640
    Size1920 => Size1080
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
fn current_window_size() -> @math.Vec2 {
  let width = @window.window_width()
  let height = @window.window_height()
  @math.Vec2::new(
    int_to_float(max_int(width, 1)),
    int_to_float(max_int(height, 1)),
  )
}

///|
fn vertical_mip_slice_spacing(
  window_size : @math.Vec2,
  level_count : Int,
) -> Float {
  window_size.y / int_to_float(max_int(level_count, 1))
}

///|
fn vertical_mip_slice_origin(
  window_size : @math.Vec2,
  level_count : Int,
) -> Float {
  let spacing = vertical_mip_slice_spacing(window_size, level_count)
  window_size.y * 0.5F - spacing * 0.5F
}

///|
fn max_mip_slice_size(
  window_size : @math.Vec2,
  level_count : Int,
) -> @math.Vec2 {
  let spacing = vertical_mip_slice_spacing(window_size, level_count)
  @math.Vec2::new(window_size.x * MIP_SLICES_WIDTH, spacing)
}

///|
fn horizontal_mip_slice_origin(
  window_size : @math.Vec2,
  level_count : Int,
) -> Float {
  let max_slice_size = max_mip_slice_size(window_size, level_count)
  window_size.x * 0.5F - max_slice_size.x * 0.5F - MIP_SLICES_MARGIN_RIGHT
}

///|
fn animated_mesh_area_size(
  window_size : @math.Vec2,
  level_count : Int,
) -> @math.Vec2 {
  @math.Vec2::new(
    horizontal_mip_slice_origin(window_size, max_int(level_count, 1)) * 2.0F -
    MIP_SLICES_MARGIN_LEFT * 2.0F,
    window_size.y,
  )
}

///|
fn animated_mesh_size(
  app_status : AppStatus,
  window_size : @math.Vec2,
  level_count : Int,
) -> @math.Vec2 {
  let max_image_size = animated_mesh_area_size(window_size, level_count)
  let image_size = @math.Vec2::new(
    int_to_float(image_size_to_int(app_status.image_width)),
    int_to_float(image_size_to_int(app_status.image_height)),
  )
  let ratios = vec2_component_div(max_image_size, image_size)
  let image_scale = min_float(ratios.x, ratios.y)
  vec2_scale(image_size, image_scale)
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
