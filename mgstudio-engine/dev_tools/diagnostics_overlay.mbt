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
pub const INITIAL_DIAGNOSTICS_OVERLAY_PLANE_Z_INDEX : Int = 1_000_000

///|
pub(all) enum DiagnosticsOverlayStatistic {
  Value
  Average
  Smoothed
} derive(Eq, Show)

///|
pub fn DiagnosticsOverlayStatistic::default() -> DiagnosticsOverlayStatistic {
  Smoothed
}

///|
pub struct DiagnosticsOverlayItem {
  statistic : DiagnosticsOverlayStatistic
  path : @diagnostic.DiagnosticPath
  precision : Int
}

///|
pub fn DiagnosticsOverlayItem::default_with_path(
  path : @diagnostic.DiagnosticPath,
) -> DiagnosticsOverlayItem {
  DiagnosticsOverlayItem::{
    statistic: DiagnosticsOverlayStatistic::default(),
    path,
    precision: 4,
  }
}

///|
pub struct DiagnosticsOverlay {
  title : String
  diagnostic_overlay_items : Array[DiagnosticsOverlayItem]
}

///|
pub fn DiagnosticsOverlay::new(
  title : String,
  diagnostic_overlay_items : Array[DiagnosticsOverlayItem],
) -> DiagnosticsOverlay {
  DiagnosticsOverlay::{ title, diagnostic_overlay_items }
}

///|
pub fn DiagnosticsOverlay::fps() -> DiagnosticsOverlay {
  DiagnosticsOverlay::new("Fps", [
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.frame_time_diagnostic_fps,
    ),
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.frame_time_diagnostic_frame_time,
    ),
    DiagnosticsOverlayItem::{
      path: @diagnostic.frame_time_diagnostic_frame_count,
      statistic: DiagnosticsOverlayStatistic::Smoothed,
      precision: 0,
    },
  ])
}

///|
pub fn DiagnosticsOverlay::render() -> DiagnosticsOverlay {
  DiagnosticsOverlay::new("Render", [
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.render_diagnostic_queue_cpu_ms_2d,
    ),
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.render_diagnostic_execute_cpu_ms_2d,
    ),
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.render_diagnostic_queue_cpu_ms_3d,
    ),
    DiagnosticsOverlayItem::default_with_path(
      @diagnostic.render_diagnostic_execute_cpu_ms_3d,
    ),
    DiagnosticsOverlayItem::{
      path: @diagnostic.render_diagnostic_mesh2d_draw_calls,
      statistic: DiagnosticsOverlayStatistic::Value,
      precision: 0,
    },
    DiagnosticsOverlayItem::{
      path: @diagnostic.render_diagnostic_mesh3d_draw_calls,
      statistic: DiagnosticsOverlayStatistic::Value,
      precision: 0,
    },
  ])
}

///|
let ecs_key_diagnostics_overlay : @ecs.ComponentKey[DiagnosticsOverlay] = @ecs.register_component(
  debug_name="bevy_dev_tools::DiagnosticsOverlay",
)

///|
pub impl @ecs.Component for DiagnosticsOverlay with component() {
  ecs_key_diagnostics_overlay
}

///|
pub struct DiagnosticsOverlayPlane {}

///|
let ecs_key_diagnostics_overlay_plane : @ecs.ComponentKey[
  DiagnosticsOverlayPlane,
] = @ecs.register_component(
  debug_name="bevy_dev_tools::DiagnosticsOverlayPlane",
)

///|
pub impl @ecs.Component for DiagnosticsOverlayPlane with component() {
  ecs_key_diagnostics_overlay_plane
}

///|
pub(all) struct DiagnosticsOverlayPlugin {
  refresh_interval_seconds : Float
}

///|
pub fn DiagnosticsOverlayPlugin::default() -> DiagnosticsOverlayPlugin {
  DiagnosticsOverlayPlugin::{ refresh_interval_seconds: 1.0F }
}

///|
priv struct DiagnosticsOverlayWindow {
  contents_entity : @core.Entity
  mut collapsed : Bool
}

///|
let ecs_key_diagnostics_overlay_window : @ecs.ComponentKey[
  DiagnosticsOverlayWindow,
] = @ecs.register_component(debug_name="dev_tools.DiagnosticsOverlayWindow")

///|
impl @ecs.Component for DiagnosticsOverlayWindow with component() {
  ecs_key_diagnostics_overlay_window
}

///|
priv struct DiagnosticsOverlayHeader {
  overlay_entity : @core.Entity
}

///|
let ecs_key_diagnostics_overlay_header : @ecs.ComponentKey[
  DiagnosticsOverlayHeader,
] = @ecs.register_component(debug_name="dev_tools.DiagnosticsOverlayHeader")

///|
impl @ecs.Component for DiagnosticsOverlayHeader with component() {
  ecs_key_diagnostics_overlay_header
}

///|
priv struct DiagnosticsOverlayRuntimeState {
  mut timer : @time.Timer
  mut plane_entity : @core.Entity?
}

///|
fn DiagnosticsOverlayRuntimeState::default() -> DiagnosticsOverlayRuntimeState {
  DiagnosticsOverlayRuntimeState::{
    timer: @time.Timer::from_seconds(1.0F, @time.Repeating),
    plane_entity: None,
  }
}

///|
let diagnostics_overlay_runtime_state_resource_key : @ecs.ResourceKey[
  DiagnosticsOverlayRuntimeState,
] = @ecs.register_resource(
  debug_name="dev_tools.DiagnosticsOverlayRuntimeState",
)

///|
priv struct DiagnosticsOverlayDragState {
  mut active_overlay : @core.Entity?
  mut pointer_id : Int?
  mut offset_x : Float
  mut offset_y : Float
}

///|
fn DiagnosticsOverlayDragState::default() -> DiagnosticsOverlayDragState {
  DiagnosticsOverlayDragState::{
    active_overlay: None,
    pointer_id: None,
    offset_x: 0.0F,
    offset_y: 0.0F,
  }
}

///|
let diagnostics_overlay_drag_state_resource_key : @ecs.ResourceKey[
  DiagnosticsOverlayDragState,
] = @ecs.register_resource(debug_name="dev_tools.DiagnosticsOverlayDragState")

///|
impl @app.Resource for DiagnosticsOverlayDragState with resource() {
  diagnostics_overlay_drag_state_resource_key
}

///|
fn diagnostics_overlay_plugin_marker_key() -> @ecs.ResourceKey[Bool] {
  @ecs.register_resource(debug_name="dev_tools.DiagnosticsOverlayPluginMarker")
}

///|
fn diagnostics_overlay_fetch_statistic(
  statistic : DiagnosticsOverlayStatistic,
  diagnostic : @diagnostic.Diagnostic,
) -> Float? {
  match statistic {
    Value => diagnostic.value()
    Average => diagnostic.average()
    Smoothed => diagnostic.smoothed()
  }
}

///|
fn diagnostics_overlay_round_precision(
  value : Float,
  precision : Int,
) -> String {
  if precision <= 0 {
    value.to_double().round().to_int64().to_string()
  } else {
    let mut scale = 1L
    for _ in 0..<precision {
      scale = scale * 10L
    }
    let scaled = (value.to_double() * scale.to_double()).round().to_int64()
    let sign = if scaled < 0L { "-" } else { "" }
    let abs_scaled = if scaled < 0L { -scaled } else { scaled }
    let whole = abs_scaled / scale
    let frac = abs_scaled % scale
    let mut frac_text = frac.to_string()
    while frac_text.length() < precision {
      frac_text = "0" + frac_text
    }
    sign + whole.to_string() + "." + frac_text
  }
}

///|
fn diagnostics_overlay_measurement_text(
  item : DiagnosticsOverlayItem,
  store : @diagnostic.DiagnosticsStore,
) -> String {
  match store.get(item.path) {
    Some(diagnostic) =>
      match diagnostics_overlay_fetch_statistic(item.statistic, diagnostic) {
        Some(value) =>
          diagnostics_overlay_round_precision(value, item.precision) +
          diagnostic.suffix
        None => "No sample"
      }
    None => "Missing"
  }
}

///|
fn diagnostics_overlay_val_px(value : @ui.Val) -> Float {
  match value {
    @ui.Val::Px(px) => px
    _ => 0.0F
  }
}

///|
fn diagnostics_overlay_ensure_plane(
  world : @ecs.World,
  state : DiagnosticsOverlayRuntimeState,
) -> @core.Entity {
  if state.plane_entity is Some(plane) && world.is_alive(plane) {
    return plane
  }
  let plane = world.spawn_empty()
  try! (world.entity_mut(plane).insert_component(DiagnosticsOverlayPlane::{  })
  |> ignore)
  try! (world.entity_mut(plane).insert_component(@ui.UiRoot::default())
  |> ignore)
  try! (world
  .entity_mut(plane)
  .insert_component(
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )
  |> ignore)
  try! (world
  .entity_mut(plane)
  .insert_component(
    @ui.GlobalZIndex::new(INITIAL_DIAGNOSTICS_OVERLAY_PLANE_Z_INDEX),
  )
  |> ignore)
  state.plane_entity = Some(plane)
  plane
}

///|
fn diagnostics_overlay_clear_contents(
  world : @ecs.World,
  contents_entity : @core.Entity,
) -> Unit {
  guard (try! world.get_by_key(contents_entity, @hierarchy.ecs_key_children))
    is Some(children) else {
    return
  }
  for child in children.entities {
    try! world.despawn(child)
  }
}

///|
fn diagnostics_overlay_rebuild_entries(
  world : @ecs.World,
  overlay : DiagnosticsOverlay,
  window : DiagnosticsOverlayWindow,
  diagnostics_store : @diagnostic.DiagnosticsStore,
) -> Unit {
  diagnostics_overlay_clear_contents(world, window.contents_entity)
  for item in overlay.diagnostic_overlay_items {
    let row = world.spawn_empty()
    try! (world
    .entity_mut(row)
    .insert_component(@hierarchy.Parent::new(window.contents_entity))
    |> ignore)
    try! (world
    .entity_mut(row)
    .insert_component(
      @ui.Node::default()
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_justify_content(@ui.JustifyContent::SpaceBetween)
      .with_column_gap(@ui.Val::Px(10.0F)),
    )
    |> ignore)

    let label = world.spawn_empty()
    try! (world.entity_mut(label).insert_component(@hierarchy.Parent::new(row))
    |> ignore)
    try! (world.entity_mut(label).insert_component(@ui.Node::default())
    |> ignore)
    try! (world
    .entity_mut(label)
    .insert_component(@text.Text::new(item.path.as_str()))
    |> ignore)
    try! (world
    .entity_mut(label)
    .insert_component(@text.TextFont::default().with_font_size(10.0F))
    |> ignore)
    try! (world
    .entity_mut(label)
    .insert_component(@text.TextColor::new(@sprite.Color::white()))
    |> ignore)

    let value = world.spawn_empty()
    try! (world.entity_mut(value).insert_component(@hierarchy.Parent::new(row))
    |> ignore)
    try! (world.entity_mut(value).insert_component(@ui.Node::default())
    |> ignore)
    try! (world
    .entity_mut(value)
    .insert_component(
      @text.Text::new(
        diagnostics_overlay_measurement_text(item, diagnostics_store),
      ),
    )
    |> ignore)
    try! (world
    .entity_mut(value)
    .insert_component(@text.TextFont::default().with_font_size(10.0F))
    |> ignore)
    try! (world
    .entity_mut(value)
    .insert_component(@text.TextColor::new(@sprite.Color::white()))
    |> ignore)
  }
}

///|
fn diagnostics_overlay_build_plane_system(world : @ecs.World) -> Unit {
  let state_ref = try! world
    .get_resource_ref_mut(diagnostics_overlay_runtime_state_resource_key)
    .unwrap()
  ignore(diagnostics_overlay_ensure_plane(world, state_ref.val))
}

///|
fn diagnostics_overlay_build_windows_system(world : @ecs.World) -> Unit {
  guard (try! world.get_resource_ref_mut(
      diagnostics_overlay_runtime_state_resource_key,
    ))
    is Some(runtime_state) else {
    return
  }
  let plane = diagnostics_overlay_ensure_plane(world, runtime_state.val)
  let diagnostics_store = (try! world.get_resource(
    @diagnostic.DiagnosticsStore::resource(),
  )).unwrap_or(@diagnostic.DiagnosticsStore::default())
  let overlays : @ecs.QueryState[@ecs.Comp[DiagnosticsOverlay], @ecs.All] = world.query()
  let overlay_iter = overlays.iter(world)
  let mut window_index = 0
  while (try! overlay_iter.fetch_next()) is Some((overlay_entity, overlay_comp)) {
    if (try! world.get_by_key(
        overlay_entity, ecs_key_diagnostics_overlay_window,
      ))
      is Some(_) {
      continue
    }
    let overlay = overlay_comp.value()
    window_index = window_index + 1
    ignore(
      try
        world
        .entity_mut(overlay_entity)
        .insert_component(@hierarchy.Parent::new(plane))
      catch {
        _ => false
      } noraise {
        _ => true
      },
    )
    ignore(
      try
        world
        .entity_mut(overlay_entity)
        .insert_component(
          @ui.Node::default()
          .with_position_type(@ui.PositionType::Absolute)
          .with_display(@ui.Display::Flex)
          .with_flex_direction(@ui.FlexDirection::Column)
          .with_left(@ui.Val::Px(16.0F))
          .with_top(@ui.Val::Px(16.0F + Float::from_int(window_index) * 160.0F))
          .with_padding(@ui.UiRect::all(@ui.Val::Px(6.0F)))
          .with_row_gap(@ui.Val::Px(4.0F)),
        )
      catch {
        _ => false
      } noraise {
        _ => true
      },
    )
    ignore(
      try
        world
        .entity_mut(overlay_entity)
        .insert_component(
          @ui.BackgroundColor::new(
            @sprite.Color::new(0.05F, 0.05F, 0.05F, 0.75F),
          ),
        )
      catch {
        _ => false
      } noraise {
        _ => true
      },
    )

    let header = world.spawn_empty()
    try! (world
    .entity_mut(header)
    .insert_component(@hierarchy.Parent::new(overlay_entity))
    |> ignore)
    try! (world
    .entity_mut(header)
    .insert_component(
      @ui.Node::default()
      .with_display(@ui.Display::Flex)
      .with_padding(@ui.UiRect::all(@ui.Val::Px(4.0F)))
      .with_width(@ui.Val::Px(280.0F)),
    )
    |> ignore)
    try! (world
    .entity_mut(header)
    .insert_component(
      @ui.BackgroundColor::new(@sprite.Color::new(0.16F, 0.16F, 0.16F, 0.9F)),
    )
    |> ignore)
    try! (world
    .entity_mut(header)
    .insert_component(DiagnosticsOverlayHeader::{ overlay_entity, })
    |> ignore)

    let title = world.spawn_empty()
    try! (world
    .entity_mut(title)
    .insert_component(@hierarchy.Parent::new(header))
    |> ignore)
    try! (world.entity_mut(title).insert_component(@ui.Node::default())
    |> ignore)
    try! (world
    .entity_mut(title)
    .insert_component(@text.Text::new(overlay.title))
    |> ignore)
    try! (world
    .entity_mut(title)
    .insert_component(@text.TextFont::default().with_font_size(12.0F))
    |> ignore)
    try! (world
    .entity_mut(title)
    .insert_component(@text.TextColor::new(@sprite.Color::white()))
    |> ignore)
    try! (world
    .entity_mut(title)
    .insert_component(DiagnosticsOverlayHeader::{ overlay_entity, })
    |> ignore)

    let contents = world.spawn_empty()
    try! (world
    .entity_mut(contents)
    .insert_component(@hierarchy.Parent::new(overlay_entity))
    |> ignore)
    try! (world
    .entity_mut(contents)
    .insert_component(
      @ui.Node::default()
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_row_gap(@ui.Val::Px(3.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(4.0F))),
    )
    |> ignore)

    let window = DiagnosticsOverlayWindow::{
      contents_entity: contents,
      collapsed: false,
    }
    try! (world.entity_mut(overlay_entity).insert_component(window) |> ignore)
    diagnostics_overlay_rebuild_entries(
      world, overlay, window, diagnostics_store,
    )
  }
}

///|
fn diagnostics_overlay_rebuild_system(world : @ecs.World) -> Unit {
  guard (try! world.get_resource_ref_mut(
      diagnostics_overlay_runtime_state_resource_key,
    ))
    is Some(state_ref) else {
    return
  }
  guard (try! world.get_resource(@time.real_time_resource_key()))
    is Some(time_real) else {
    return
  }
  state_ref.val.timer = state_ref.val.timer.tick(time_real.delta())
  if !state_ref.val.timer.is_finished() {
    return
  }
  let diagnostics_store = (try! world.get_resource(
    @diagnostic.DiagnosticsStore::resource(),
  )).unwrap_or(@diagnostic.DiagnosticsStore::default())
  let overlays : @ecs.QueryState[
    (@ecs.Comp[DiagnosticsOverlay], @ecs.Comp[DiagnosticsOverlayWindow]),
    @ecs.All,
  ] = world.query()
  let overlay_iter = overlays.iter(world)
  while (try! overlay_iter.fetch_next())
        is Some((_entity, (overlay_comp, window_comp))) {
    let overlay = overlay_comp.value()
    let window = window_comp.value()
    diagnostics_overlay_rebuild_entries(
      world, overlay, window, diagnostics_store,
    )
  }
}

///|
fn diagnostics_overlay_pointer_down(
  pointer : @app.OnPointer[@app.PointerDown],
  headers : @ecs.Query[@ecs.Comp[DiagnosticsOverlayHeader], @ecs.All],
  overlays : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
  drag_state : @app.ResMut[DiagnosticsOverlayDragState],
) -> Unit {
  guard pointer.target() is Some(target) else { return }
  guard (try! headers.get(target)) is Some(header_comp) else { return }
  let header = header_comp.value()
  guard (try! overlays.get(header.overlay_entity)) is Some(overlay_node) else {
    return
  }
  let left = diagnostics_overlay_val_px(overlay_node.value().left)
  let top = diagnostics_overlay_val_px(overlay_node.value().top)
  drag_state.get_ref().val.active_overlay = Some(header.overlay_entity)
  drag_state.get_ref().val.pointer_id = Some(pointer.pointer())
  drag_state.get_ref().val.offset_x = pointer.position().x - left
  drag_state.get_ref().val.offset_y = pointer.position().y - top
}

///|
fn diagnostics_overlay_pointer_move(
  pointer : @app.OnPointer[@app.PointerMove],
  drag_state : @app.ResMut[DiagnosticsOverlayDragState],
  overlays : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
) -> Unit {
  guard drag_state.get_ref().val.active_overlay is Some(overlay_entity) else {
    return
  }
  guard drag_state.get_ref().val.pointer_id is Some(pointer_id) else { return }
  guard pointer.pointer() == pointer_id else { return }
  guard (try! overlays.get(overlay_entity)) is Some(overlay_node) else {
    return
  }
  let x = pointer.position().x - drag_state.get_ref().val.offset_x
  let y = pointer.position().y - drag_state.get_ref().val.offset_y
  overlay_node.set(
    overlay_node.value().with_left(@ui.Val::Px(x)).with_top(@ui.Val::Px(y)),
  )
}

///|
fn diagnostics_overlay_pointer_up(
  pointer : @app.OnPointer[@app.PointerUp],
  drag_state : @app.ResMut[DiagnosticsOverlayDragState],
) -> Unit {
  guard drag_state.get_ref().val.pointer_id is Some(pointer_id) else { return }
  guard pointer.pointer() == pointer_id else { return }
  drag_state.get_ref().val.active_overlay = None
  drag_state.get_ref().val.pointer_id = None
}

///|
fn diagnostics_overlay_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  headers : @ecs.Query[@ecs.Comp[DiagnosticsOverlayHeader], @ecs.All],
  windows : @ecs.Query[@ecs.Mut[DiagnosticsOverlayWindow], @ecs.All],
  nodes : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
) -> Unit {
  guard pointer.target() is Some(target) else { return }
  guard (try! headers.get(target)) is Some(header_comp) else { return }
  let header = header_comp.value()
  guard (try! windows.get(header.overlay_entity)) is Some(window_mut) else {
    return
  }
  let collapsed = !window_mut.get_ref().val.collapsed
  window_mut.get_ref().val.collapsed = collapsed
  let contents_entity = window_mut.get_ref().val.contents_entity
  guard (try! nodes.get(contents_entity)) is Some(contents_node) else { return }
  contents_node.set(
    contents_node
    .value()
    .with_display(if collapsed { @ui.Display::None } else { @ui.Display::Flex }),
  )
}

///|
pub fn diagnostics_overlay_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  diagnostics_overlay_plugin_with(app, DiagnosticsOverlayPlugin::default())
}

///|
pub fn diagnostics_overlay_plugin_with(
  app : @app.App[@ecs.World],
  plugin : DiagnosticsOverlayPlugin,
) -> @app.App[@ecs.World] {
  let marker = diagnostics_overlay_plugin_marker_key()
  if app.contains_resource(marker) {
    return app
  }
  let mut app_ = app
    .insert_world_resource(marker, true)
    .insert_world_resource(diagnostics_overlay_runtime_state_resource_key, DiagnosticsOverlayRuntimeState::{
      ..DiagnosticsOverlayRuntimeState::default(),
      timer: @time.Timer::from_seconds(
        if plugin.refresh_interval_seconds <= 0.0F {
          1.0F
        } else {
          plugin.refresh_interval_seconds
        },
        @time.Repeating,
      ),
    })
    .insert_world_resource(
      diagnostics_overlay_drag_state_resource_key,
      DiagnosticsOverlayDragState::default(),
    )
    .add_startup_system(diagnostics_overlay_build_plane_system)
    .add_system(diagnostics_overlay_build_windows_system)
    .add_system(diagnostics_overlay_rebuild_system)
  app_ = app_.add_pointer_observer4(diagnostics_overlay_pointer_down)
  app_ = app_.add_pointer_observer3(diagnostics_overlay_pointer_move)
  app_ = app_.add_pointer_observer2(diagnostics_overlay_pointer_up)
  app_.add_pointer_observer4(diagnostics_overlay_pointer_click)
}
