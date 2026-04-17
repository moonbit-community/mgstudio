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
priv struct WindowRuntime {
  window : HostWindow
  mut created_sent : Bool
  mut close_requested_sent : Bool
  mut last_applied_title : String
  last_applied_name : String?
  mut last_applied_width : Int
  mut last_applied_height : Int
  mut last_applied_position : WindowPosition
  mut last_applied_mode : WindowMode
  mut last_applied_visible : Bool
  last_applied_skip_taskbar : Bool
  last_applied_clip_children : Bool
  mut last_applied_resizable : Bool
  mut last_applied_resize_constraints : WindowResizeConstraints
  mut last_applied_enabled_buttons : EnabledButtons
  mut last_applied_decorations : Bool
  last_applied_transparent : Bool
  last_applied_canvas : String?
  mut last_applied_focused : Bool
  mut last_applied_window_level : WindowLevel
  mut last_applied_window_theme : WindowTheme?
  mut last_applied_prefers_home_indicator_hidden : Bool
  mut last_applied_prefers_status_bar_hidden : Bool
  mut last_applied_preferred_screen_edges_deferring_system_gestures : ScreenEdge
  mut last_applied_ime_enabled : Bool
  mut last_applied_ime_position : @math.Vec2
  mut last_applied_cursor_visible : Bool
  mut last_applied_cursor_grab_mode : CursorGrabMode
  mut last_applied_cursor_icon : CursorIcon?
  mut last_observed_width : Int
  mut last_observed_height : Int
  mut last_observed_position_x : Int
  mut last_observed_position_y : Int
  mut last_observed_scale_factor : Float
}

///|
let ecs_key_window_runtime : @ecs.ComponentKey[WindowRuntime] = @ecs.register_component(
  debug_name="mgstudio_window::WindowRuntime",
)

///|
impl @ecs.Component for WindowRuntime with component() {
  ecs_key_window_runtime
}

///|
priv struct WindowPluginMarker {}

///|
fn window_plugin_marker_key() -> @ecs.ResourceKey[WindowPluginMarker] {
  @ecs.register_resource(debug_name="mgstudio_window::WindowPluginMarker")
}

///|
fn[T] window_remove_component(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> Unit {
  ignore(
    try world.remove_by_key(entity, key) catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
fn window_component(world : @ecs.World, entity : @core.Entity) -> Window? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_runtime_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> WindowRuntime? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_cursor_options_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorOptions? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_cursor_icon_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorIcon? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_closing_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> ClosingWindow? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_set_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : Window,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_set_runtime_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : WindowRuntime,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_set_primary_window_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(PrimaryWindow::{  }) |> ignore)
}

///|
fn window_set_cursor_options_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : CursorOptions,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_set_cursor_icon_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : CursorIcon,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_raw_handle_holder_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> RawHandleWrapperHolder? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn window_set_raw_handle_wrapper_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : RawHandleWrapper,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_set_raw_handle_holder_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : RawHandleWrapperHolder,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(value) |> ignore)
}

///|
fn window_set_closing_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  try! (world.entity_mut(entity).insert_component(ClosingWindow::{  }) |> ignore)
}

///|
fn window_update_component(
  world : @ecs.World,
  entity : @core.Entity,
  update : (Window) -> Window,
) -> Bool {
  try {
    let entity_mut = world.entity_mut(entity)
    let window = entity_mut.get_mut(key=ecs_key_window)
    match window {
      Some(window) => {
        window.set(update(window.value()))
        true
      }
      None => false
    }
  } catch {
    _ => false
  }
}

///|
fn window_primary_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_primary_window)),
  )
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
pub fn window_entity_for_ref(
  world : @ecs.World,
  window_ref : WindowRef,
) -> @core.Entity? {
  match window_ref {
    Primary => window_primary_entity(world)
    Entity(entity) =>
      if window_component(world, entity) is Some(_) {
        Some(entity)
      } else {
        None
      }
  }
}

///|
pub fn window_entity_for_host(
  world : @ecs.World,
  host_window : HostWindow,
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! world
  .query_entities_filtered(@ecs.With::new(ecs_key_window_runtime))
  .view(fn(_query_entity, entity) {
    if result.val is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, ecs_key_window_runtime)) is Some(runtime) {
      if runtime.window == host_window {
        result.val = Some(entity)
      }
    }
  })
  result.val
}

///|
pub struct WindowHostEntry {
  entity : @core.Entity
  host_window : HostWindow
}

///|
pub fn WindowHostEntry::new(
  entity : @core.Entity,
  host_window : HostWindow,
) -> WindowHostEntry {
  WindowHostEntry::{ entity, host_window }
}

///|
pub struct WindowModeChangeRequest {
  entity : @core.Entity
  host_window : HostWindow
  mode : WindowMode
}

///|
pub fn WindowModeChangeRequest::new(
  entity : @core.Entity,
  host_window : HostWindow,
  mode : WindowMode,
) -> WindowModeChangeRequest {
  WindowModeChangeRequest::{ entity, host_window, mode }
}

///|
pub fn window_host_window_for_ref(
  world : @ecs.World,
  window_ref : WindowRef,
) -> HostWindow? {
  guard window_entity_for_ref(world, window_ref) is Some(entity) else {
    return None
  }
  guard window_runtime_component(world, entity) is Some(runtime) else {
    return None
  }
  Some(runtime.window)
}

///|
pub fn window_host_entries(world : @ecs.World) -> Array[WindowHostEntry] {
  let entries : Array[WindowHostEntry] = []
  try! world
  .query_entities_filtered(@ecs.With::new(ecs_key_window_runtime))
  .view(fn(_query_entity, entity) {
    if (try! world.get_by_key(entity, ecs_key_window_runtime)) is Some(runtime) {
      entries.push(WindowHostEntry::new(entity, runtime.window))
    }
  })
  entries
}

///|
fn window_physical_width_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  if window_runtime_component(world, entity) is Some(runtime) {
    return runtime.last_observed_width
  }
  if window_component(world, entity) is Some(window) {
    return window.physical_width()
  }
  0
}

///|
fn window_physical_height_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> Int {
  if window_runtime_component(world, entity) is Some(runtime) {
    return runtime.last_observed_height
  }
  if window_component(world, entity) is Some(window) {
    return window.physical_height()
  }
  0
}

///|
fn window_scale_factor_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> Float {
  if window_component(world, entity) is Some(window) {
    if window.resolution.scale_factor_override() is Some(_) {
      return window.scale_factor()
    }
  }
  if window_runtime_component(world, entity) is Some(runtime) {
    return runtime.last_observed_scale_factor
  }
  if window_component(world, entity) is Some(window) {
    return window.scale_factor()
  }
  1.0F
}

///|
pub fn window_physical_width_for(
  world : @ecs.World,
  window_ref : WindowRef,
) -> Int {
  guard window_entity_for_ref(world, window_ref) is Some(entity) else {
    return 0
  }
  window_physical_width_for_entity(world, entity)
}

///|
pub fn window_physical_height_for(
  world : @ecs.World,
  window_ref : WindowRef,
) -> Int {
  guard window_entity_for_ref(world, window_ref) is Some(entity) else {
    return 0
  }
  window_physical_height_for_entity(world, entity)
}

///|
pub fn window_scale_factor_for(
  world : @ecs.World,
  window_ref : WindowRef,
) -> Float {
  guard window_entity_for_ref(world, window_ref) is Some(entity) else {
    return 1.0F
  }
  window_scale_factor_for_entity(world, entity)
}

///|
fn window_resolution_scale_factor_or_default(
  resolution : WindowResolution,
) -> Float {
  let scale_factor = resolution.scale_factor()
  if scale_factor <= 0.0F {
    1.0F
  } else {
    scale_factor
  }
}

///|
fn window_resolution_logical_width(resolution : WindowResolution) -> Float {
  Float::from_int(resolution.physical_width()) /
  window_resolution_scale_factor_or_default(resolution)
}

///|
fn window_resolution_logical_height(resolution : WindowResolution) -> Float {
  Float::from_int(resolution.physical_height()) /
  window_resolution_scale_factor_or_default(resolution)
}

///|
fn window_requested_logical_width(resolution : WindowResolution) -> Int {
  let width = window_resolution_logical_width(resolution).to_int()
  if width <= 0 {
    1
  } else {
    width
  }
}

///|
fn window_requested_logical_height(resolution : WindowResolution) -> Int {
  let height = window_resolution_logical_height(resolution).to_int()
  if height <= 0 {
    1
  } else {
    height
  }
}

///|
fn window_uses_physical_request_on_create(
  resolution : WindowResolution,
) -> Bool {
  resolution.scale_factor_override() is Some(_)
}

///|
fn window_current_cursor_options(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorOptions {
  match window_cursor_options_component(world, entity) {
    Some(options) => options
    None => CursorOptions::default()
  }
}

///|
fn window_current_cursor_icon(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorIcon? {
  window_cursor_icon_component(world, entity)
}

///|
fn window_resolution_matches_runtime(
  resolution : WindowResolution,
  runtime : WindowRuntime,
) -> Bool {
  resolution.physical_width() == runtime.last_applied_width &&
  resolution.physical_height() == runtime.last_applied_height
}

///|
fn window_vec2_eq(a : @math.Vec2, b : @math.Vec2) -> Bool {
  a.x == b.x && a.y == b.y
}

///|
fn window_resize_constraints_has_finite_max(
  constraints : WindowResizeConstraints,
) -> Bool {
  constraints.max_width < @float.infinity &&
  constraints.max_height < @float.infinity
}

///|
fn window_apply_position(
  window : HostWindow,
  position : WindowPosition,
  resolution : WindowResolution,
) -> Unit {
  host_window_set_position_from(window, position, resolution)
}

///|
fn window_apply_ime_settings(
  window : HostWindow,
  ime_enabled : Bool,
  ime_position : @math.Vec2,
) -> Unit {
  host_window_set_ime_allowed(window, allowed=ime_enabled)
  host_window_set_ime_cursor_area(
    window,
    x=ime_position.x.to_int(),
    y=ime_position.y.to_int(),
    width=1,
    height=1,
  )
}

///|
fn window_runtime_close_host_window(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if window_runtime_component(world, entity) is Some(runtime) {
    host_window_request_close(runtime.window)
  }
  window_emit_window_closed(world, WindowClosed::{ window: entity })
  window_emit_window_destroyed(world, WindowDestroyed::{ window: entity })
}

///|
fn window_runtime_on_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  let deferred_world = world.world()
  window_runtime_close_host_window(deferred_world, context.entity)
  window_remove_component(
    deferred_world,
    context.entity,
    ecs_key_window_runtime,
  )
  window_remove_component(
    deferred_world,
    context.entity,
    ecs_key_closing_window,
  )
}

///|
fn window_register_component_hooks() -> Unit {
  let window_hooks = @ecs.register_component_hooks_for_key(ecs_key_window)
  ignore(try! window_hooks.on_remove(window_runtime_on_remove))
}

///|
fn init {
  window_register_component_hooks()
}

///|
fn window_create_runtime_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> HostWindow? {
  if window_runtime_component(world, entity) is Some(runtime) {
    return Some(runtime.window)
  }
  guard window_component(world, entity) is Some(window) else { return None }
  let checked_constraints = window.resize_constraints.check_constraints()
  let max_width = if window_resize_constraints_has_finite_max(
      checked_constraints,
    ) {
    Some(checked_constraints.max_width)
  } else {
    None
  }
  let max_height = if window_resize_constraints_has_finite_max(
      checked_constraints,
    ) {
    Some(checked_constraints.max_height)
  } else {
    None
  }
  let host_window = host_window_create(
    logical_width=window_requested_logical_width(window.resolution),
    logical_height=window_requested_logical_height(window.resolution),
    physical_width=window.physical_width(),
    physical_height=window.physical_height(),
    use_physical_size_on_create=window_uses_physical_request_on_create(
      window.resolution,
    ),
    title=window.title,
    name=window.name,
    visible=window.visible,
    resizable=window.resizable,
    decorations=window.decorations,
    transparent=window.transparent,
    focused=window.focused,
    close_button_enabled=window.enabled_buttons.close,
    minimize_button_enabled=window.enabled_buttons.minimize,
    maximize_button_enabled=window.enabled_buttons.maximize,
    min_inner_width=checked_constraints.min_width,
    min_inner_height=checked_constraints.min_height,
    max_inner_width=max_width,
    max_inner_height=max_height,
    movable_by_window_background=window.movable_by_window_background,
    fullsize_content_view=window.fullsize_content_view,
    has_shadow=window.has_shadow,
    titlebar_shown=window.titlebar_shown,
    titlebar_transparent=window.titlebar_transparent,
    titlebar_show_title=window.titlebar_show_title,
    titlebar_show_buttons=window.titlebar_show_buttons,
    borderless_game=window.borderless_game,
    skip_taskbar=window.skip_taskbar,
    clip_children=window.clip_children,
  )
  let cursor_options = window_current_cursor_options(world, entity)
  let cursor_icon = window_current_cursor_icon(world, entity)
  let raw_handle_wrapper = RawHandleWrapper::new(
    WindowWrapper::new(host_window),
  )
  host_window_set_visible(host_window, visible=window.visible)
  host_window_set_size(
    host_window,
    width=window.physical_width(),
    height=window.physical_height(),
  )
  window_apply_position(host_window, window.position, window.resolution)
  host_window_set_resizable(host_window, resizable=window.resizable)
  host_window_set_resize_constraints(host_window, window.resize_constraints)
  host_window_set_enabled_buttons(host_window, window.enabled_buttons)
  host_window_set_decorations(host_window, decorations=window.decorations)
  host_window_set_window_level(host_window, level=window.window_level)
  host_window_set_theme(host_window, theme=window.window_theme)
  host_window_set_prefers_home_indicator_hidden(
    host_window,
    hidden=window.prefers_home_indicator_hidden,
  )
  host_window_set_prefers_status_bar_hidden(
    host_window,
    hidden=window.prefers_status_bar_hidden,
  )
  host_window_set_preferred_screen_edges_deferring_system_gestures(
    host_window,
    edges=window.preferred_screen_edges_deferring_system_gestures,
  )
  window_apply_ime_settings(
    host_window,
    window.ime_enabled,
    window.ime_position,
  )
  host_window_set_cursor_visible(host_window, visible=cursor_options.visible)
  host_window_set_cursor_grab_mode(host_window, mode=cursor_options.grab_mode)
  if cursor_icon is Some(cursor_icon0) {
    host_window_set_cursor_icon(host_window, icon=cursor_icon0)
  }
  let observed_width = host_window_get_width(host_window)
  let observed_height = host_window_get_height(host_window)
  let observed_position_x = host_window_get_position_x(host_window)
  let observed_position_y = host_window_get_position_y(host_window)
  let observed_scale_factor = host_window_get_scale_factor(host_window)
  let runtime = WindowRuntime::{
    window: host_window,
    created_sent: false,
    close_requested_sent: false,
    last_applied_title: window.title,
    last_applied_name: window.name,
    last_applied_width: window.physical_width(),
    last_applied_height: window.physical_height(),
    last_applied_position: window.position,
    last_applied_mode: WindowMode::Windowed,
    last_applied_visible: window.visible,
    last_applied_skip_taskbar: window.skip_taskbar,
    last_applied_clip_children: window.clip_children,
    last_applied_resizable: window.resizable,
    last_applied_resize_constraints: window.resize_constraints,
    last_applied_enabled_buttons: window.enabled_buttons,
    last_applied_decorations: window.decorations,
    last_applied_transparent: window.transparent,
    last_applied_canvas: window.canvas,
    last_applied_focused: window.focused,
    last_applied_window_level: window.window_level,
    last_applied_window_theme: window.window_theme,
    last_applied_prefers_home_indicator_hidden: window.prefers_home_indicator_hidden,
    last_applied_prefers_status_bar_hidden: window.prefers_status_bar_hidden,
    last_applied_preferred_screen_edges_deferring_system_gestures: window.preferred_screen_edges_deferring_system_gestures,
    last_applied_ime_enabled: window.ime_enabled,
    last_applied_ime_position: window.ime_position,
    last_applied_cursor_visible: cursor_options.visible,
    last_applied_cursor_grab_mode: cursor_options.grab_mode,
    last_applied_cursor_icon: cursor_icon,
    last_observed_width: observed_width,
    last_observed_height: observed_height,
    last_observed_position_x: observed_position_x,
    last_observed_position_y: observed_position_y,
    last_observed_scale_factor: if observed_scale_factor <= 0.0F {
      1.0F
    } else {
      observed_scale_factor
    },
  }
  window_set_runtime_component(world, entity, runtime)
  window_set_raw_handle_wrapper_component(world, entity, raw_handle_wrapper)
  if window_raw_handle_holder_component(world, entity) is Some(holder) {
    holder.handle.val = Some(raw_handle_wrapper)
  }
  Some(host_window)
}

///|
fn window_sync_requested_window_state(
  world : @ecs.World,
  entity : @core.Entity,
  runtime_ref : Ref[WindowRuntime],
) -> Unit {
  guard window_component(world, entity) is Some(window) else { return }
  let host_window = runtime_ref.val.window
  let mut restore_name = false
  let mut restore_transparent = false
  let mut restore_canvas = false
  let mut restore_skip_taskbar = false
  let mut restore_clip_children = false
  if window.title != runtime_ref.val.last_applied_title {
    host_window_set_title(host_window, title=window.title)
    runtime_ref.val.last_applied_title = window.title
  }
  if window.name != runtime_ref.val.last_applied_name {
    restore_name = true
    host_debug_string(
      value="mgstudio_winit: modifying window name after initialization is unsupported",
    )
  }
  if !window_resolution_matches_runtime(window.resolution, runtime_ref.val) {
    host_window_set_size(
      host_window,
      width=window.physical_width(),
      height=window.physical_height(),
    )
    runtime_ref.val.last_applied_width = window.physical_width()
    runtime_ref.val.last_applied_height = window.physical_height()
  }
  if window.position != runtime_ref.val.last_applied_position {
    window_apply_position(host_window, window.position, window.resolution)
    runtime_ref.val.last_applied_position = window.position
  }
  if window.visible != runtime_ref.val.last_applied_visible {
    host_window_set_visible(host_window, visible=window.visible)
    runtime_ref.val.last_applied_visible = window.visible
  }
  if window.skip_taskbar != runtime_ref.val.last_applied_skip_taskbar {
    restore_skip_taskbar = true
    host_debug_string(
      value="mgstudio_winit: modifying skip_taskbar after window creation is unsupported",
    )
  }
  if window.clip_children != runtime_ref.val.last_applied_clip_children {
    restore_clip_children = true
    host_debug_string(
      value="mgstudio_winit: modifying clip_children after window creation is unsupported",
    )
  }
  if window.resizable != runtime_ref.val.last_applied_resizable {
    host_window_set_resizable(host_window, resizable=window.resizable)
    runtime_ref.val.last_applied_resizable = window.resizable
  }
  if window.resize_constraints !=
    runtime_ref.val.last_applied_resize_constraints {
    host_window_set_resize_constraints(host_window, window.resize_constraints)
    runtime_ref.val.last_applied_resize_constraints = window.resize_constraints
  }
  if window.enabled_buttons != runtime_ref.val.last_applied_enabled_buttons {
    host_window_set_enabled_buttons(host_window, window.enabled_buttons)
    runtime_ref.val.last_applied_enabled_buttons = window.enabled_buttons
  }
  if window.decorations != runtime_ref.val.last_applied_decorations {
    host_window_set_decorations(host_window, decorations=window.decorations)
    runtime_ref.val.last_applied_decorations = window.decorations
  }
  if window.transparent != runtime_ref.val.last_applied_transparent {
    restore_transparent = true
    host_debug_string(
      value="mgstudio_winit: transparency changes after window creation are unsupported",
    )
  }
  if window.canvas != runtime_ref.val.last_applied_canvas {
    restore_canvas = true
    host_debug_string(
      value="mgstudio_winit: modifying window canvas after initialization is unsupported",
    )
  }
  if window.focused != runtime_ref.val.last_applied_focused {
    if window.focused {
      host_window_focus(host_window)
    }
    runtime_ref.val.last_applied_focused = window.focused
  }
  if window.window_level != runtime_ref.val.last_applied_window_level {
    host_window_set_window_level(host_window, level=window.window_level)
    runtime_ref.val.last_applied_window_level = window.window_level
  }
  if window.window_theme != runtime_ref.val.last_applied_window_theme {
    host_window_set_theme(host_window, theme=window.window_theme)
    runtime_ref.val.last_applied_window_theme = window.window_theme
  }
  if window.prefers_home_indicator_hidden !=
    runtime_ref.val.last_applied_prefers_home_indicator_hidden {
    host_window_set_prefers_home_indicator_hidden(
      host_window,
      hidden=window.prefers_home_indicator_hidden,
    )
    runtime_ref.val.last_applied_prefers_home_indicator_hidden = window.prefers_home_indicator_hidden
  }
  if window.prefers_status_bar_hidden !=
    runtime_ref.val.last_applied_prefers_status_bar_hidden {
    host_window_set_prefers_status_bar_hidden(
      host_window,
      hidden=window.prefers_status_bar_hidden,
    )
    runtime_ref.val.last_applied_prefers_status_bar_hidden = window.prefers_status_bar_hidden
  }
  if window.preferred_screen_edges_deferring_system_gestures !=
    runtime_ref.val.last_applied_preferred_screen_edges_deferring_system_gestures {
    host_window_set_preferred_screen_edges_deferring_system_gestures(
      host_window,
      edges=window.preferred_screen_edges_deferring_system_gestures,
    )
    runtime_ref.val.last_applied_preferred_screen_edges_deferring_system_gestures
    = window.preferred_screen_edges_deferring_system_gestures
  }
  if window.ime_enabled != runtime_ref.val.last_applied_ime_enabled ||
    !window_vec2_eq(
      window.ime_position,
      runtime_ref.val.last_applied_ime_position,
    ) {
    window_apply_ime_settings(
      host_window,
      window.ime_enabled,
      window.ime_position,
    )
    runtime_ref.val.last_applied_ime_enabled = window.ime_enabled
    runtime_ref.val.last_applied_ime_position = window.ime_position
  }
  let requested_maximize = window.maximize_request
  let requested_minimize = window.minimize_request
  if requested_maximize is Some(maximized) {
    host_window_set_maximized(host_window, maximized~)
  }
  if requested_minimize is Some(minimized) {
    host_window_set_minimized(host_window, minimized~)
  }
  let requested_drag_move = window.drag_move_request
  let requested_drag_resize = window.drag_resize_request
  if requested_drag_move {
    host_window_drag_move(host_window) |> ignore
  }
  if requested_drag_resize is Some(direction) {
    host_window_drag_resize(host_window, direction) |> ignore
  }
  if requested_drag_move ||
    requested_drag_resize is Some(_) ||
    requested_maximize is Some(_) ||
    requested_minimize is Some(_) ||
    restore_name ||
    restore_transparent ||
    restore_canvas ||
    restore_skip_taskbar ||
    restore_clip_children {
    let cached_name = runtime_ref.val.last_applied_name
    let cached_transparent = runtime_ref.val.last_applied_transparent
    let cached_canvas = runtime_ref.val.last_applied_canvas
    let cached_skip_taskbar = runtime_ref.val.last_applied_skip_taskbar
    let cached_clip_children = runtime_ref.val.last_applied_clip_children
    ignore(
      window_update_component(world, entity, fn(current) {
        let next : Window = current
        if requested_drag_move || requested_drag_resize is Some(_) {
          next.drag_move_request = false
          next.drag_resize_request = None
        }
        if requested_maximize is Some(_) {
          next.maximize_request = None
        }
        if requested_minimize is Some(_) {
          next.minimize_request = None
        }
        if restore_name {
          next.name = cached_name
        }
        if restore_transparent {
          next.transparent = cached_transparent
        }
        if restore_canvas {
          next.canvas = cached_canvas
        }
        if restore_skip_taskbar {
          next.skip_taskbar = cached_skip_taskbar
        }
        if restore_clip_children {
          next.clip_children = cached_clip_children
        }
        next
      }),
    )
  }
}

///|
fn window_sync_requested_cursor_state(
  world : @ecs.World,
  entity : @core.Entity,
  runtime_ref : Ref[WindowRuntime],
) -> Unit {
  let host_window = runtime_ref.val.window
  let cursor_options = window_current_cursor_options(world, entity)
  if cursor_options.visible != runtime_ref.val.last_applied_cursor_visible {
    host_window_set_cursor_visible(host_window, visible=cursor_options.visible)
    runtime_ref.val.last_applied_cursor_visible = cursor_options.visible
  }
  if cursor_options.grab_mode != runtime_ref.val.last_applied_cursor_grab_mode {
    host_window_set_cursor_grab_mode(host_window, mode=cursor_options.grab_mode)
    runtime_ref.val.last_applied_cursor_grab_mode = cursor_options.grab_mode
  }
  let cursor_icon = window_current_cursor_icon(world, entity)
  if !window_cursor_icon_option_eq(
      cursor_icon,
      runtime_ref.val.last_applied_cursor_icon,
    ) {
    if cursor_icon is Some(cursor_icon0) {
      host_window_set_cursor_icon(host_window, icon=cursor_icon0)
    } else {
      host_window_set_cursor_icon(host_window, icon=CursorIcon::default())
    }
    runtime_ref.val.last_applied_cursor_icon = cursor_icon
  }
}

///|
fn window_cursor_icon_option_eq(lhs : CursorIcon?, rhs : CursorIcon?) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(System(a)), Some(System(b))) => a == b
    (Some(Custom(_)), Some(Custom(_))) => true
    _ => false
  }
}

///|
fn window_sync_observed_state(
  world : @ecs.World,
  entity : @core.Entity,
  runtime_ref : Ref[WindowRuntime],
) -> Unit {
  let host_window = runtime_ref.val.window
  let observed_width = host_window_get_width(host_window)
  let observed_height = host_window_get_height(host_window)
  let observed_position_x = host_window_get_position_x(host_window)
  let observed_position_y = host_window_get_position_y(host_window)
  let scale_factor0 = host_window_get_scale_factor(host_window)
  let observed_focused = host_window_get_focused(host_window)
  let observed_scale_factor = if scale_factor0 <= 0.0F {
    1.0F
  } else {
    scale_factor0
  }
  if !runtime_ref.val.created_sent {
    window_emit_window_created(world, WindowCreated::{ window: entity })
    runtime_ref.val.created_sent = true
  }
  if observed_width != runtime_ref.val.last_observed_width ||
    observed_height != runtime_ref.val.last_observed_height {
    window_emit_window_resized(world, WindowResized::{
      window: entity,
      width: Float::from_int(observed_width) / observed_scale_factor,
      height: Float::from_int(observed_height) / observed_scale_factor,
    })
    runtime_ref.val.last_observed_width = observed_width
    runtime_ref.val.last_observed_height = observed_height
  }
  if observed_position_x != runtime_ref.val.last_observed_position_x ||
    observed_position_y != runtime_ref.val.last_observed_position_y {
    window_emit_window_moved(world, WindowMoved::{
      window: entity,
      x: observed_position_x,
      y: observed_position_y,
    })
    runtime_ref.val.last_observed_position_x = observed_position_x
    runtime_ref.val.last_observed_position_y = observed_position_y
  }
  if observed_scale_factor != runtime_ref.val.last_observed_scale_factor {
    window_emit_window_backend_scale_factor_changed(world, WindowBackendScaleFactorChanged::{
      window: entity,
      scale_factor: observed_scale_factor,
    })
    runtime_ref.val.last_observed_scale_factor = observed_scale_factor
  }
  if window_component(world, entity) is Some(window) {
    let old_scale_factor = window.scale_factor()
    let next_scale_factor = match window.resolution.scale_factor_override() {
      Some(scale_factor_override) =>
        if scale_factor_override <= 0.0F {
          1.0F
        } else {
          scale_factor_override
        }
      None => observed_scale_factor
    }
    if old_scale_factor != next_scale_factor {
      if world.contains_message(ecs_key_window_scale_factor_changed) {
        window_emit_window_scale_factor_changed(world, WindowScaleFactorChanged::{
          window: entity,
          scale_factor: next_scale_factor,
        })
      }
    }
    if window.focused != observed_focused {
      window_emit_window_focused(world, WindowFocused::{
        window: entity,
        focused: observed_focused,
      })
    }
  }
  if host_window_should_close(host_window) &&
    !runtime_ref.val.close_requested_sent {
    window_emit_window_close_requested(world, WindowCloseRequested::{
      window: entity,
    })
    runtime_ref.val.close_requested_sent = true
  }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.resolution.set_physical_resolution(observed_width, observed_height)
      next.resolution.set_scale_factor(observed_scale_factor)
      next.position = WindowPosition::new(
        observed_position_x, observed_position_y,
      )
      next.focused = observed_focused
      next
    }),
  )
}

///|
fn window_runtime_entities_without_host(
  world : @ecs.World,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  try! world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.Without::new(ecs_key_window_runtime)),
  )
  .view(fn(_query_entity, entity) { entities.push(entity) })
  entities
}

///|
fn window_runtime_entities_with_host(world : @ecs.World) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  try! world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_window_runtime)),
  )
  .view(fn(_query_entity, entity) { entities.push(entity) })
  entities
}

///|
pub fn window_ensure_primary_host(world : @ecs.World) -> HostWindow? {
  guard window_primary_entity(world) is Some(entity) else { return None }
  window_create_runtime_for_entity(world, entity)
}

///|
fn window_primary_runtime(world : @ecs.World) -> WindowRuntime? {
  guard window_primary_entity(world) is Some(entity) else { return None }
  window_runtime_component(world, entity)
}

///|
fn window_primary_window(world : @ecs.World) -> Window? {
  guard window_primary_entity(world) is Some(entity) else { return None }
  window_component(world, entity)
}

///|
pub fn window_poll_host_events(world : @ecs.World) -> Unit {
  for entity in window_runtime_entities_with_host(world) {
    if window_runtime_component(world, entity) is Some(runtime) {
      host_window_poll_events(runtime.window)
    }
  }
}

///|
pub fn window_request_close_all_hosts(world : @ecs.World) -> Unit {
  for entity in window_runtime_entities_with_host(world) {
    if window_runtime_component(world, entity) is Some(runtime) {
      host_window_request_close(runtime.window)
    }
  }
}

///|
fn window_primary_physical_width(world : @ecs.World) -> Int {
  window_physical_width_for(world, WindowRef::Primary)
}

///|
fn window_primary_physical_height(world : @ecs.World) -> Int {
  window_physical_height_for(world, WindowRef::Primary)
}

///|
fn window_primary_scale_factor(world : @ecs.World) -> Float {
  window_scale_factor_for(world, WindowRef::Primary)
}

///|
fn window_primary_position_x(world : @ecs.World) -> Int {
  if window_primary_runtime(world) is Some(runtime) {
    return runtime.last_observed_position_x
  }
  if window_primary_window(world) is Some(window) {
    match window.position {
      Automatic => 0
      Centered(_) => 0
      At(x, _y) => x
    }
  } else {
    0
  }
}

///|
fn window_primary_position_y(world : @ecs.World) -> Int {
  if window_primary_runtime(world) is Some(runtime) {
    return runtime.last_observed_position_y
  }
  if window_primary_window(world) is Some(window) {
    match window.position {
      Automatic => 0
      Centered(_) => 0
      At(_x, y) => y
    }
  } else {
    0
  }
}

///|
fn window_emit_window_event(world : @ecs.World, event : WindowEvent) -> Unit {
  if world.contains_message(ecs_key_window_event) {
    ignore(world.send_message(ecs_key_window_event, event))
  }
}

///|
fn window_emit_window_created(
  world : @ecs.World,
  event : WindowCreated,
) -> Unit {
  if world.contains_message(ecs_key_window_created) {
    ignore(world.send_message(ecs_key_window_created, event))
  }
  window_emit_window_event(world, WindowEvent::WindowCreated(event))
}

///|
fn window_emit_window_close_requested(
  world : @ecs.World,
  event : WindowCloseRequested,
) -> Unit {
  if world.contains_message(ecs_key_window_close_requested) {
    ignore(world.send_message(ecs_key_window_close_requested, event))
  }
  window_emit_window_event(world, WindowEvent::WindowCloseRequested(event))
}

///|
fn window_emit_window_closing(
  world : @ecs.World,
  event : WindowClosing,
) -> Unit {
  if world.contains_message(ecs_key_window_closing) {
    ignore(world.send_message(ecs_key_window_closing, event))
  }
}

///|
fn window_emit_window_closed(world : @ecs.World, event : WindowClosed) -> Unit {
  if world.contains_message(ecs_key_window_closed) {
    ignore(world.send_message(ecs_key_window_closed, event))
  }
}

///|
fn window_emit_window_destroyed(
  world : @ecs.World,
  event : WindowDestroyed,
) -> Unit {
  if world.contains_message(ecs_key_window_destroyed) {
    ignore(world.send_message(ecs_key_window_destroyed, event))
  }
  window_emit_window_event(world, WindowEvent::WindowDestroyed(event))
}

///|
fn window_emit_window_resized(
  world : @ecs.World,
  event : WindowResized,
) -> Unit {
  if world.contains_message(ecs_key_window_resized) {
    ignore(world.send_message(ecs_key_window_resized, event))
  }
  window_emit_window_event(world, WindowEvent::WindowResized(event))
}

///|
fn window_emit_window_moved(world : @ecs.World, event : WindowMoved) -> Unit {
  if world.contains_message(ecs_key_window_moved) {
    ignore(world.send_message(ecs_key_window_moved, event))
  }
  window_emit_window_event(world, WindowEvent::WindowMoved(event))
}

///|
fn window_emit_window_scale_factor_changed(
  world : @ecs.World,
  event : WindowScaleFactorChanged,
) -> Unit {
  if world.contains_message(ecs_key_window_scale_factor_changed) {
    ignore(world.send_message(ecs_key_window_scale_factor_changed, event))
  }
  window_emit_window_event(world, WindowEvent::WindowScaleFactorChanged(event))
}

///|
fn window_emit_window_backend_scale_factor_changed(
  world : @ecs.World,
  event : WindowBackendScaleFactorChanged,
) -> Unit {
  if world.contains_message(ecs_key_window_backend_scale_factor_changed) {
    ignore(
      world.send_message(ecs_key_window_backend_scale_factor_changed, event),
    )
  }
  window_emit_window_event(
    world,
    WindowEvent::WindowBackendScaleFactorChanged(event),
  )
}

///|
fn window_emit_window_focused(
  world : @ecs.World,
  event : WindowFocused,
) -> Unit {
  if world.contains_message(ecs_key_window_focused) {
    ignore(world.send_message(ecs_key_window_focused, event))
  }
  window_emit_window_event(world, WindowEvent::WindowFocused(event))
}

///|
pub fn window_emit_cursor_moved(
  world : @ecs.World,
  event : CursorMoved,
) -> Unit {
  if world.contains_message(ecs_key_cursor_moved) {
    ignore(world.send_message(ecs_key_cursor_moved, event))
  }
  window_emit_window_event(world, WindowEvent::CursorMoved(event))
}

///|
pub fn window_emit_cursor_entered(
  world : @ecs.World,
  event : CursorEntered,
) -> Unit {
  if world.contains_message(ecs_key_cursor_entered) {
    ignore(world.send_message(ecs_key_cursor_entered, event))
  }
  window_emit_window_event(world, WindowEvent::CursorEntered(event))
}

///|
pub fn window_emit_cursor_left(world : @ecs.World, event : CursorLeft) -> Unit {
  if world.contains_message(ecs_key_cursor_left) {
    ignore(world.send_message(ecs_key_cursor_left, event))
  }
  window_emit_window_event(world, WindowEvent::CursorLeft(event))
}

///|
pub fn window_emit_file_drag_and_drop(
  world : @ecs.World,
  event : FileDragAndDrop,
) -> Unit {
  if world.contains_message(ecs_key_file_drag_and_drop) {
    ignore(world.send_message(ecs_key_file_drag_and_drop, event))
  }
  window_emit_window_event(world, WindowEvent::FileDragAndDrop(event))
}

///|
pub fn window_emit_ime(world : @ecs.World, event : Ime) -> Unit {
  if world.contains_message(ecs_key_ime) {
    ignore(world.send_message(ecs_key_ime, event))
  }
  window_emit_window_event(world, WindowEvent::Ime(event))
}

///|
pub fn window_emit_mouse_button_input(
  world : @ecs.World,
  event : MouseButtonInput,
) -> Unit {
  if world.contains_message(ecs_key_mouse_button_input) {
    ignore(world.send_message(ecs_key_mouse_button_input, event))
  }
  window_emit_window_event(world, WindowEvent::MouseButtonInput(event))
}

///|
pub fn window_emit_mouse_motion(
  world : @ecs.World,
  event : MouseMotion,
) -> Unit {
  if world.contains_message(ecs_key_mouse_motion) {
    ignore(world.send_message(ecs_key_mouse_motion, event))
  }
  window_emit_window_event(world, WindowEvent::MouseMotion(event))
}

///|
pub fn window_emit_mouse_wheel(world : @ecs.World, event : MouseWheel) -> Unit {
  if world.contains_message(ecs_key_mouse_wheel) {
    ignore(world.send_message(ecs_key_mouse_wheel, event))
  }
  window_emit_window_event(world, WindowEvent::MouseWheel(event))
}

///|
pub fn window_emit_pinch_gesture(
  world : @ecs.World,
  event : PinchGesture,
) -> Unit {
  if world.contains_message(ecs_key_pinch_gesture) {
    ignore(world.send_message(ecs_key_pinch_gesture, event))
  }
  window_emit_window_event(world, WindowEvent::PinchGesture(event))
}

///|
pub fn window_emit_rotation_gesture(
  world : @ecs.World,
  event : RotationGesture,
) -> Unit {
  if world.contains_message(ecs_key_rotation_gesture) {
    ignore(world.send_message(ecs_key_rotation_gesture, event))
  }
  window_emit_window_event(world, WindowEvent::RotationGesture(event))
}

///|
pub fn window_emit_double_tap_gesture(
  world : @ecs.World,
  event : DoubleTapGesture,
) -> Unit {
  if world.contains_message(ecs_key_double_tap_gesture) {
    ignore(world.send_message(ecs_key_double_tap_gesture, event))
  }
  window_emit_window_event(world, WindowEvent::DoubleTapGesture(event))
}

///|
pub fn window_emit_pan_gesture(world : @ecs.World, event : PanGesture) -> Unit {
  if world.contains_message(ecs_key_pan_gesture) {
    ignore(world.send_message(ecs_key_pan_gesture, event))
  }
  window_emit_window_event(world, WindowEvent::PanGesture(event))
}

///|
pub fn window_emit_touch_input(world : @ecs.World, event : TouchInput) -> Unit {
  if world.contains_message(ecs_key_touch_input) {
    ignore(world.send_message(ecs_key_touch_input, event))
  }
  window_emit_window_event(world, WindowEvent::TouchInput(event))
}

///|
pub fn window_emit_keyboard_input(
  world : @ecs.World,
  event : KeyboardInput,
) -> Unit {
  if world.contains_message(ecs_key_keyboard_input) {
    ignore(world.send_message(ecs_key_keyboard_input, event))
  }
  window_emit_window_event(world, WindowEvent::KeyboardInput(event))
}

///|
pub fn window_emit_keyboard_focus_lost(
  world : @ecs.World,
  event : KeyboardFocusLost,
) -> Unit {
  if world.contains_message(ecs_key_keyboard_focus_lost) {
    ignore(world.send_message(ecs_key_keyboard_focus_lost, event))
  }
  window_emit_window_event(world, WindowEvent::KeyboardFocusLost(event))
}

///|
fn window_emit_window_occluded(
  world : @ecs.World,
  event : WindowOccluded,
) -> Unit {
  if world.contains_message(ecs_key_window_occluded) {
    ignore(world.send_message(ecs_key_window_occluded, event))
  }
  window_emit_window_event(world, WindowEvent::WindowOccluded(event))
}

///|
fn window_emit_window_theme_changed(
  world : @ecs.World,
  event : WindowThemeChanged,
) -> Unit {
  if world.contains_message(ecs_key_window_theme_changed) {
    ignore(world.send_message(ecs_key_window_theme_changed, event))
  }
  window_emit_window_event(world, WindowEvent::WindowThemeChanged(event))
}

///|
fn window_emit_app_lifecycle(
  world : @ecs.World,
  lifecycle : AppLifecycle,
) -> Unit {
  if world.contains_message(ecs_key_app_lifecycle) {
    ignore(world.send_message(ecs_key_app_lifecycle, lifecycle))
  }
  window_emit_window_event(world, WindowEvent::AppLifecycle(lifecycle))
}

///|
fn window_theme_from_host(theme : Int) -> WindowTheme? {
  match theme {
    1 => Some(WindowTheme::Light)
    2 => Some(WindowTheme::Dark)
    _ => None
  }
}

///|
fn app_lifecycle_from_host(kind : Int) -> AppLifecycle? {
  match kind {
    0 => Some(AppLifecycle::Idle)
    1 => Some(AppLifecycle::Running)
    2 => Some(AppLifecycle::WillSuspend)
    3 => Some(AppLifecycle::Suspended)
    4 => Some(AppLifecycle::WillResume)
    _ => None
  }
}

///|
fn window_emit_native_theme_events(world : @ecs.World) -> Unit {
  let count = host_window_theme_event_count()
  for i in 0..<count {
    let host_window = host_window_theme_event_window(index=i)
    if host_window < 0 {
      continue
    }
    guard window_entity_for_host(world, host_window) is Some(window_entity) else {
      continue
    }
    guard window_theme_from_host(host_window_theme_event_theme(index=i))
      is Some(theme) else {
      continue
    }
    window_emit_window_theme_changed(world, WindowThemeChanged::{
      window: window_entity,
      theme,
    })
  }
}

///|
fn window_emit_native_occluded_events(world : @ecs.World) -> Unit {
  let count = host_window_occluded_event_count()
  for i in 0..<count {
    let host_window = host_window_occluded_event_window(index=i)
    if host_window < 0 {
      continue
    }
    guard window_entity_for_host(world, host_window) is Some(window_entity) else {
      continue
    }
    window_emit_window_occluded(world, WindowOccluded::{
      window: window_entity,
      occluded: host_window_occluded_event_occluded(index=i),
    })
  }
}

///|
fn window_emit_native_app_lifecycle_events(world : @ecs.World) -> Unit {
  let count = host_app_lifecycle_event_count()
  for i in 0..<count {
    if app_lifecycle_from_host(host_app_lifecycle_event_kind(index=i))
      is Some(lifecycle) {
      window_emit_app_lifecycle(world, lifecycle)
    }
  }
}

///|
pub fn window_backend_sync_system(world : @ecs.World) -> Unit {
  window_backend_create_windows_system(world)
  window_backend_prepare_system(world)
  window_backend_apply_requested_system(world)
}

///|
pub fn window_backend_create_windows_system(world : @ecs.World) -> Unit {
  for entity in window_runtime_entities_without_host(world) {
    window_create_runtime_for_entity(world, entity) |> ignore
  }
}

///|
pub fn window_backend_prepare_system(world : @ecs.World) -> Unit {
  window_emit_native_theme_events(world)
  window_emit_native_occluded_events(world)
  window_emit_native_app_lifecycle_events(world)
  let runtime_query : @ecs.Query[@ecs.Mut[WindowRuntime], @ecs.All] = @ecs.query(
    world,
  )
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      if (runtime_query.get(entity) catch { _ => None }) is Some(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        window_sync_observed_state(world, entity, runtime_ref)
      },
    )
  }
}

///|
pub fn window_backend_apply_requested_system(world : @ecs.World) -> Unit {
  window_backend_apply_changed_windows_system(world)
  window_backend_apply_changed_cursor_options_system(world)
}

///|
pub fn window_backend_apply_changed_windows_system(world : @ecs.World) -> Unit {
  let runtime_query : @ecs.Query[@ecs.Mut[WindowRuntime], @ecs.All] = @ecs.query(
    world,
  )
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      if (runtime_query.get(entity) catch { _ => None }) is Some(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        window_sync_requested_window_state(world, entity, runtime_ref)
      },
    )
  }
}

///|
pub fn window_take_changed_mode_requests(
  world : @ecs.World,
) -> Array[WindowModeChangeRequest] {
  let requests : Array[WindowModeChangeRequest] = []
  let runtime_query : @ecs.Query[@ecs.Mut[WindowRuntime], @ecs.All] = @ecs.query(
    world,
  )
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      if (runtime_query.get(entity) catch { _ => None }) is Some(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        if window_component(world, entity) is Some(window) {
          if window.mode != runtime_ref.val.last_applied_mode {
            requests.push(
              WindowModeChangeRequest::new(
                entity,
                runtime_ref.val.window,
                window.mode,
              ),
            )
            runtime_ref.val.last_applied_mode = window.mode
          }
        }
      },
    )
  }
  requests
}

///|
pub fn window_backend_apply_changed_cursor_options_system(
  world : @ecs.World,
) -> Unit {
  let runtime_query : @ecs.Query[@ecs.Mut[WindowRuntime], @ecs.All] = @ecs.query(
    world,
  )
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      if (runtime_query.get(entity) catch { _ => None }) is Some(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        window_sync_requested_cursor_state(world, entity, runtime_ref)
      },
    )
  }
}

///|
fn window_spawn_primary_window_entity(
  world : @ecs.World,
  window : Window,
  cursor_options : CursorOptions?,
) -> Unit {
  if window_primary_entity(world) is Some(_) {
    return
  }
  let entity = world.spawn()
  window_set_component(world, entity, window)
  window_set_primary_window_component(world, entity)
  window_set_raw_handle_holder_component(
    world,
    entity,
    RawHandleWrapperHolder::new(),
  )
  if cursor_options is Some(cursor_options0) {
    window_set_cursor_options_component(world, entity, cursor_options0)
  }
}
