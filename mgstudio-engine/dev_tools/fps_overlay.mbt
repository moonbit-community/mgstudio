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
//
// Adapted from Bevy's `bevy_dev_tools` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub const FPS_OVERLAY_ZINDEX : Int = 2147483615

///|
const MIN_SAFE_INTERVAL_MILLIS : Int64 = 50L

///|
const FRAME_TIME_GRAPH_WIDTH_SCALE : Float = 6.0F

///|
const FRAME_TIME_GRAPH_HEIGHT_SCALE : Float = 2.0F

///|
const DEFAULT_OVERLAY_TEXT : String = "FPS: --"

///|
pub let fps_overlay_set_customize : @app.SystemSet = @app.system_set(
  "bevy.dev_tools.fps_overlay.customize",
)

///|
pub let fps_overlay_set_update_text : @app.SystemSet = @app.system_set(
  "bevy.dev_tools.fps_overlay.update_text",
)

///|
pub(all) struct FpsOverlayPlugin {
  config : FpsOverlayConfig
}

///|
pub fn FpsOverlayPlugin::default() -> FpsOverlayPlugin {
  FpsOverlayPlugin::{ config: FpsOverlayConfig::default() }
}

///|
pub(all) struct FpsOverlayConfig {
  mut text_config : @text.TextFont
  mut text_color : @sprite.Color
  mut enabled : Bool
  mut refresh_interval : @core.Duration
  mut frame_time_graph_config : FrameTimeGraphConfig
}

///|
fn fps_overlay_touch_config_mutability(config : FpsOverlayConfig) -> Unit {
  config.text_config = config.text_config
  config.text_color = config.text_color
  config.enabled = config.enabled
  config.refresh_interval = config.refresh_interval
  config.frame_time_graph_config = config.frame_time_graph_config
}

///|
pub fn FpsOverlayConfig::default() -> FpsOverlayConfig {
  let config = FpsOverlayConfig::{
    text_config: @text.TextFont::from_font_size(32.0F),
    text_color: @sprite.Color::white(),
    enabled: true,
    refresh_interval: @core.Duration::from_millis(100L),
    frame_time_graph_config: FrameTimeGraphConfig::target_fps(60.0F),
  }
  fps_overlay_touch_config_mutability(config)
  config
}

///|
let fps_overlay_config_resource_key : @ecs.ResourceKey[FpsOverlayConfig] = @ecs.register_resource(
  debug_name="bevy_dev_tools::fps_overlay::FpsOverlayConfig",
)

///|
pub impl @app.Resource for FpsOverlayConfig with resource() {
  fps_overlay_config_resource_key
}

///|
pub(all) struct FrameTimeGraphConfig {
  mut enabled : Bool
  mut min_fps : Float
  mut target_fps : Float
}

///|
fn fps_overlay_touch_frame_time_graph_config_mutability(
  config : FrameTimeGraphConfig,
) -> Unit {
  config.enabled = config.enabled
  config.min_fps = config.min_fps
  config.target_fps = config.target_fps
}

///|
pub fn FrameTimeGraphConfig::default() -> FrameTimeGraphConfig {
  let config = FrameTimeGraphConfig::{
    enabled: true,
    min_fps: 30.0F,
    target_fps: 60.0F,
  }
  fps_overlay_touch_frame_time_graph_config_mutability(config)
  config
}

///|
pub fn FrameTimeGraphConfig::target_fps(
  target_fps : Float,
) -> FrameTimeGraphConfig {
  let config = FrameTimeGraphConfig::{
    ..FrameTimeGraphConfig::default(),
    target_fps,
  }
  fps_overlay_touch_frame_time_graph_config_mutability(config)
  config
}

///|
priv struct FpsOverlayPluginMarker {}

///|
let fps_overlay_plugin_marker_key : @ecs.ResourceKey[FpsOverlayPluginMarker] = @ecs.register_resource(
  debug_name="bevy_dev_tools::fps_overlay::FpsOverlayPluginMarker",
)

///|
priv struct FpsOverlayState {
  mut root_entity : @core.Entity?
  mut text_entity : @core.Entity?
  mut graph_entity : @core.Entity?
  bar_entities : Array[@core.Entity]
}

///|
fn FpsOverlayState::default() -> FpsOverlayState {
  FpsOverlayState::{
    root_entity: None,
    text_entity: None,
    graph_entity: None,
    bar_entities: [],
  }
}

///|
let fps_overlay_state_resource_key : @ecs.ResourceKey[FpsOverlayState] = @ecs.register_resource(
  debug_name="bevy_dev_tools::fps_overlay::FpsOverlayState",
)

///|
fn fps_overlay_state_ref(world : @ecs.World) -> Ref[FpsOverlayState] {
  let tick = @app.current_system_ticks().this_run
  match
    (try! world.get_resource_ref_mut(fps_overlay_state_resource_key, tick)) {
    Some(state) => state
    None => abort("Missing FpsOverlayState resource")
  }
}

///|
fn fps_overlay_config(world : @ecs.World) -> FpsOverlayConfig {
  match (try! world.get_resource(fps_overlay_config_resource_key)) {
    Some(config) => config
    None => abort("Missing FpsOverlayConfig resource")
  }
}

///|
fn fps_overlay_warn_on_low_interval(config : FpsOverlayConfig) -> Unit {
  if config.refresh_interval.as_millis() < MIN_SAFE_INTERVAL_MILLIS {
    @app.log_record(
      @app.Warn,
      message="Low refresh interval (" +
        config.refresh_interval.to_string() +
        ") may degrade performance. Min recommended: " +
        @core.Duration::from_millis(MIN_SAFE_INTERVAL_MILLIS).to_string(),
    )
  }
}

///|
fn fps_overlay_has_frame_time_diagnostics(app : @app.App[@ecs.World]) -> Bool {
  match
    (try! app.world().get_resource(@diagnostic.DiagnosticsStore::resource())) {
    Some(store) =>
      store.get(@diagnostic.frame_time_diagnostic_fps) is Some(_) &&
      store.get(@diagnostic.frame_time_diagnostic_frame_time) is Some(_)
    None => false
  }
}

///|
pub fn fps_overlay_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  fps_overlay_plugin_with(app, FpsOverlayPlugin::default())
}

///|
pub fn fps_overlay_plugin_with(
  app : @app.App[@ecs.World],
  plugin : FpsOverlayPlugin,
) -> @app.App[@ecs.World] {
  if app.contains_resource(fps_overlay_plugin_marker_key) {
    return app
  }
  let mut next = app
  if !fps_overlay_has_frame_time_diagnostics(next) {
    next = next.add_plugin(@diagnostic.frame_time_diagnostics_plugin)
  }
  fps_overlay_warn_on_low_interval(plugin.config)
  next
  .insert_world_resource(fps_overlay_plugin_marker_key, FpsOverlayPluginMarker::{

  })
  .insert_resource(plugin.config)
  .insert_world_resource(
    fps_overlay_state_resource_key,
    FpsOverlayState::default(),
  )
  .add_systems(@app.Startup, @app.system(fps_overlay_setup))
  .add_systems(
    @app.Update,
    @app.system(fps_overlay_customize_system)
    .run_if(@app.resource_changed(fps_overlay_config_resource_key))
    .in_set(fps_overlay_set_customize),
  )
  .add_systems(
    @app.Update,
    @app.system(fps_overlay_update_system)
    .run_if(@time.on_timer(plugin.config.refresh_interval))
    .in_set(fps_overlay_set_update_text)
    .after(fps_overlay_set_customize),
  )
}

///|
fn fps_overlay_font_size(config : FpsOverlayConfig) -> Float {
  if config.text_config.font_size < 1.0F {
    1.0F
  } else {
    config.text_config.font_size
  }
}

///|
fn fps_overlay_graph_width(config : FpsOverlayConfig) -> Float {
  fps_overlay_font_size(config) * FRAME_TIME_GRAPH_WIDTH_SCALE
}

///|
fn fps_overlay_graph_height(config : FpsOverlayConfig) -> Float {
  fps_overlay_font_size(config) * FRAME_TIME_GRAPH_HEIGHT_SCALE
}

///|
fn fps_overlay_text_display(config : FpsOverlayConfig) -> @ui.Display {
  if config.enabled {
    @ui.Display::Flex
  } else {
    @ui.Display::None
  }
}

///|
fn fps_overlay_graph_display(config : FpsOverlayConfig) -> @ui.Display {
  if config.frame_time_graph_config.enabled {
    @ui.Display::Flex
  } else {
    @ui.Display::None
  }
}

///|
fn fps_overlay_text_value(fps : Float?) -> String {
  match fps {
    Some(value) => "FPS: \{fps_overlay_format_with_two_decimals(value)}"
    None => DEFAULT_OVERLAY_TEXT
  }
}

///|
fn fps_overlay_format_with_two_decimals(value : Float) -> String {
  let scaled = Float::round(value * 100.0F).to_int()
  let negative = scaled < 0
  let magnitude = if negative { -scaled } else { scaled }
  let whole = magnitude / 100
  let fractional = magnitude % 100
  let fractional_string = if fractional < 10 {
    "0" + fractional.to_string()
  } else {
    fractional.to_string()
  }
  let prefix = if negative { "-" } else { "" }
  prefix + whole.to_string() + "." + fractional_string
}

///|
fn fps_overlay_color_lerp(
  start : @sprite.Color,
  ending : @sprite.Color,
  t : Float,
) -> @sprite.Color {
  let weight = if t < 0.0F { 0.0F } else if t > 1.0F { 1.0F } else { t }
  @sprite.Color::new(
    start.r + (ending.r - start.r) * weight,
    start.g + (ending.g - start.g) * weight,
    start.b + (ending.b - start.b) * weight,
    start.a + (ending.a - start.a) * weight,
  )
}

///|
fn fps_overlay_log2(value : Float) -> Float {
  if value <= 0.0F {
    return 0.0F
  }
  let mut normalized = value
  let mut exponent = 0.0F
  while normalized < 1.0F {
    normalized = normalized * 2.0F
    exponent = exponent - 1.0F
  }
  while normalized >= 2.0F {
    normalized = normalized / 2.0F
    exponent = exponent + 1.0F
  }
  let mut fraction = 0.0F
  let mut factor = 0.5F
  let mut current = normalized
  for _ in 0..<16 {
    current = current * current
    if current >= 2.0F {
      current = current / 2.0F
      fraction = fraction + factor
    }
    factor = factor / 2.0F
  }
  exponent + fraction
}

///|
fn fps_overlay_graph_ratio(
  frame_time_ms : Float,
  config : FrameTimeGraphConfig,
) -> Float {
  let dt = frame_time_ms / 1000.0F
  let dt_min = 1.0F / (config.target_fps * 1.2F)
  let dt_max = 1.0F / config.min_fps
  let dt_min_log2 = fps_overlay_log2(dt_min)
  let dt_max_log2 = fps_overlay_log2(dt_max)
  if dt_max_log2 == dt_min_log2 {
    return 1.0F
  }
  let ratio = (fps_overlay_log2(dt) - dt_min_log2) / (dt_max_log2 - dt_min_log2)
  if ratio < 0.0F {
    0.0F
  } else if ratio > 1.0F {
    1.0F
  } else {
    ratio
  }
}

///|
fn fps_overlay_graph_color(
  frame_time_ms : Float,
  config : FrameTimeGraphConfig,
) -> @sprite.Color {
  let dt = frame_time_ms / 1000.0F
  let dt_max = 1.0F / config.min_fps
  fps_overlay_color_lerp(
    @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    dt / dt_max,
  )
}

///|
fn fps_overlay_graph_bar_width(
  frame_time_ms : Float,
  graph_width : Float,
  count : Int,
  config : FrameTimeGraphConfig,
) -> Float {
  let dt = frame_time_ms / 1000.0F
  let dt_min = 1.0F / (config.target_fps * 1.2F)
  graph_width * (dt / dt_min / Float::from_int(count))
}

///|
fn fps_overlay_setup(world : @ecs.World) -> Unit {
  let config = fps_overlay_config(world)
  let state_ref = fps_overlay_state_ref(world)
  if state_ref.val.root_entity is Some(_) {
    return
  }

  let root = world.spawn_empty()
  try! world.set_component(root, @ui.UiRoot::default())
  try! world.set_component(
    root,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_flex_direction(@ui.FlexDirection::Column),
  )
  try! world.set_component(root, @ui.GlobalZIndex::new(FPS_OVERLAY_ZINDEX))

  let text_entity = world.spawn_empty()
  try! world.set_component(text_entity, @hierarchy.Parent::new(root))
  try! world.set_component(text_entity, @ui.Node::default())
  try! world.set_component(text_entity, @text.Text::new(DEFAULT_OVERLAY_TEXT))
  try! world.set_component(text_entity, config.text_config)
  try! world.set_component(text_entity, @text.TextColor::new(config.text_color))

  let graph_entity = world.spawn_empty()
  try! world.set_component(graph_entity, @hierarchy.Parent::new(root))
  try! world.set_component(
    graph_entity,
    @ui.Node::default()
    .with_width(@ui.Val::Px(fps_overlay_graph_width(config)))
    .with_height(@ui.Val::Px(fps_overlay_graph_height(config)))
    .with_display(fps_overlay_graph_display(config))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_align_items(@ui.AlignItems::End)
    .with_overflow(
      @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Hidden),
    ),
  )
  try! world.set_component(
    graph_entity,
    @ui.BackgroundColor::new(@sprite.Color::new(0.0F, 0.0F, 0.0F, 0.5F)),
  )

  state_ref.val.root_entity = Some(root)
  state_ref.val.text_entity = Some(text_entity)
  state_ref.val.graph_entity = Some(graph_entity)
  fps_overlay_customize_system(world)
}

///|
fn fps_overlay_customize_system(world : @ecs.World) -> Unit {
  let config = fps_overlay_config(world)
  let state_ref = fps_overlay_state_ref(world)
  if state_ref.val.text_entity is Some(text_entity) {
    ignore(
      try
        world.update_component(text_entity, fn(node : @ui.Node) {
          node.with_display(fps_overlay_text_display(config))
        })
      catch {
        _ => false
      } noraise {
        value => value
      },
    )
  }

  if state_ref.val.text_entity is Some(text_entity) {
    ignore(
      try world.set_component(text_entity, config.text_config) catch {
        _ => false
      } noraise {
        _ => true
      },
    )
    ignore(
      try
        world.set_component(
          text_entity,
          @text.TextColor::new(config.text_color),
        )
      catch {
        _ => false
      } noraise {
        _ => true
      },
    )
  }

  if state_ref.val.graph_entity is Some(graph_entity) {
    ignore(
      try
        world.update_component(graph_entity, fn(node : @ui.Node) {
          node
          .with_width(@ui.Val::Px(fps_overlay_graph_width(config)))
          .with_height(@ui.Val::Px(fps_overlay_graph_height(config)))
          .with_display(fps_overlay_graph_display(config))
        })
      catch {
        _ => false
      } noraise {
        value => value
      },
    )
  }
}

///|
fn fps_overlay_resize_bars(
  world : @ecs.World,
  state_ref : Ref[FpsOverlayState],
  graph_entity : @core.Entity,
  count : Int,
) -> Unit {
  while state_ref.val.bar_entities.length() < count {
    let bar = world.spawn_empty()
    try! world.set_component(bar, @hierarchy.Parent::new(graph_entity))
    try! world.set_component(bar, @ui.Node::default())
    try! world.set_component(
      bar,
      @ui.BackgroundColor::new(@sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)),
    )
    state_ref.val.bar_entities.push(bar)
  }
  while state_ref.val.bar_entities.length() > count {
    guard state_ref.val.bar_entities.pop() is Some(bar) else { break }
    try! world.despawn(bar)
  }
}

///|
fn fps_overlay_update_system(world : @ecs.World) -> Unit {
  let config = fps_overlay_config(world)
  let state_ref = fps_overlay_state_ref(world)
  guard (try! world.get_resource(@diagnostic.DiagnosticsStore::resource()))
    is Some(store) else {
    return
  }

  let fps_value = match store.get(@diagnostic.frame_time_diagnostic_fps) {
    Some(diagnostic) => diagnostic.smoothed()
    None => None
  }
  let next_text = fps_overlay_text_value(fps_value)
  if state_ref.val.text_entity is Some(text_entity) {
    let tick = world.read_change_tick()
    let text_store = world.component(@text.ecs_key_text)
    if text_store.get(text_entity) is Some(text_value) {
      text_value.content = next_text
      ignore(text_store.set(text_entity, text_value, tick))
    }
  }

  guard state_ref.val.graph_entity is Some(graph_entity) else { return }
  guard store.get(@diagnostic.frame_time_diagnostic_frame_time)
    is Some(frame_time) else {
    fps_overlay_resize_bars(world, state_ref, graph_entity, 0)
    return
  }
  let values = frame_time.values()
  fps_overlay_resize_bars(world, state_ref, graph_entity, values.length())
  if values.length() == 0 {
    return
  }

  let graph_width = fps_overlay_graph_width(config)
  let graph_height = fps_overlay_graph_height(config)
  for i in 0..<values.length() {
    let bar_entity = state_ref.val.bar_entities[i]
    let height = graph_height *
      fps_overlay_graph_ratio(values[i], config.frame_time_graph_config)
    let width = fps_overlay_graph_bar_width(
      values[i],
      graph_width,
      values.length(),
      config.frame_time_graph_config,
    )
    ignore(
      try
        world.update_component(bar_entity, fn(node : @ui.Node) {
          node.with_width(@ui.Val::Px(width)).with_height(@ui.Val::Px(height))
        })
      catch {
        _ => false
      } noraise {
        value => value
      },
    )
    try! world.set_component(
      bar_entity,
      @ui.BackgroundColor::new(
        fps_overlay_graph_color(values[i], config.frame_time_graph_config),
      ),
    )
  }
}
