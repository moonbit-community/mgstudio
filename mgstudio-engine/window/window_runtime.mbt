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
  mut last_applied_width : Int
  mut last_applied_height : Int
  mut last_applied_position : WindowPosition
  mut last_applied_mode : WindowMode
  mut last_applied_visible : Bool
  mut last_applied_resizable : Bool
  mut last_applied_enabled_buttons : EnabledButtons
  mut last_applied_decorations : Bool
  mut last_applied_transparent : Bool
  mut last_applied_window_level : WindowLevel
  mut last_applied_window_theme : WindowTheme?
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
  debug_name="bevy_window::WindowRuntime",
)

///|
impl @ecs.Component for WindowRuntime with component() {
  ecs_key_window_runtime
}

///|
priv struct WindowPluginMarker {}

///|
fn window_plugin_marker_key() -> @ecs.ResourceKey[WindowPluginMarker] {
  @ecs.register_resource(debug_name="bevy_window::WindowPluginMarker")
}

///|
fn[T] window_remove_component(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> Unit {
  ignore(
    try world.remove(entity, key) catch {
      _ => false
    } noraise {
      value => value
    },
  )
}

///|
fn window_component(world : @ecs.World, entity : @core.Entity) -> Window? {
  try world.get_component(entity) catch {
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
  try world.get_component(entity) catch {
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
  try world.get_component(entity) catch {
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
  try world.get_component(entity) catch {
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
  try world.get_component(entity) catch {
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
  try! world.set_component(entity, value)
}

///|
fn window_set_runtime_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : WindowRuntime,
) -> Unit {
  try! world.set_component(entity, value)
}

///|
fn window_set_primary_window_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  try! world.set_component(entity, PrimaryWindow::{  })
}

///|
fn window_set_cursor_options_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : CursorOptions,
) -> Unit {
  try! world.set_component(entity, value)
}

///|
fn window_set_cursor_icon_component(
  world : @ecs.World,
  entity : @core.Entity,
  value : CursorIcon,
) -> Unit {
  try! world.set_component(entity, value)
}

///|
fn window_set_closing_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  try! world.set_component(entity, ClosingWindow::{  })
}

///|
fn window_update_component(
  world : @ecs.World,
  entity : @core.Entity,
  update : (Window) -> Window,
) -> Bool {
  try world.update_component(entity, update) catch {
    _ => false
  } noraise {
    value => value
  }
}

///|
fn window_primary_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_primary_window)),
  )
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
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
  let runtime_store = world.component(ecs_key_window_runtime)
  world
  .query_entities_filtered(@ecs.With::new(ecs_key_window_runtime))
  .view(fn(entity) {
    if result.val is Some(_) {
      return
    }
    if runtime_store.get(entity) is Some(runtime) {
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
  let runtime_store = world.component(ecs_key_window_runtime)
  world
  .query_entities_filtered(@ecs.With::new(ecs_key_window_runtime))
  .view(fn(entity) {
    if runtime_store.get(entity) is Some(runtime) {
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
fn window_apply_position(
  window : HostWindow,
  position : WindowPosition,
) -> Unit {
  match position {
    Automatic => ()
    At(x, y) => host_window_set_position(window, x~, y~)
  }
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
  world : @ecs.World,
  entity : @core.Entity,
  _payload : @any.Any,
) -> Unit {
  window_runtime_close_host_window(world, entity)
  window_remove_component(world, entity, ecs_key_window_runtime)
  window_remove_component(world, entity, ecs_key_closing_window)
}

///|
fn window_runtime_on_despawn(
  _world : @ecs.World,
  _entity : @core.Entity,
  _payload : @any.Any,
) -> Unit {
  ()
}

///|
fn window_register_component_hooks() -> Unit {
  try! @ecs.register_component_hooks(
    ecs_key_window,
    @ecs.ComponentHooks::new(
      on_remove=Some(window_runtime_on_remove),
      on_despawn=Some(window_runtime_on_despawn),
    ),
  )
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
  let host_window = host_window_create(
    logical_width=window_requested_logical_width(window.resolution),
    logical_height=window_requested_logical_height(window.resolution),
    physical_width=window.physical_width(),
    physical_height=window.physical_height(),
    use_physical_size_on_create=window_uses_physical_request_on_create(
      window.resolution,
    ),
    title=window.title,
    visible=window.visible,
    resizable=window.resizable,
    decorations=window.decorations,
  )
  let cursor_options = window_current_cursor_options(world, entity)
  let cursor_icon = window_current_cursor_icon(world, entity)
  host_window_set_visible(host_window, visible=window.visible)
  window_apply_position(host_window, window.position)
  host_window_set_mode(host_window, mode=window.mode)
  host_window_set_resizable(host_window, resizable=window.resizable)
  host_window_set_enabled_buttons(host_window, window.enabled_buttons)
  host_window_set_decorations(host_window, decorations=window.decorations)
  host_window_set_transparent(host_window, transparent=window.transparent)
  host_window_set_window_level(host_window, level=window.window_level)
  host_window_set_theme(host_window, theme=window.window_theme)
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
    last_applied_width: window.physical_width(),
    last_applied_height: window.physical_height(),
    last_applied_position: window.position,
    last_applied_mode: window.mode,
    last_applied_visible: window.visible,
    last_applied_resizable: window.resizable,
    last_applied_enabled_buttons: window.enabled_buttons,
    last_applied_decorations: window.decorations,
    last_applied_transparent: window.transparent,
    last_applied_window_level: window.window_level,
    last_applied_window_theme: window.window_theme,
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
  Some(host_window)
}

///|
fn window_sync_requested_state(
  world : @ecs.World,
  entity : @core.Entity,
  runtime_ref : Ref[WindowRuntime],
) -> Unit {
  guard window_component(world, entity) is Some(window) else { return }
  let host_window = runtime_ref.val.window
  if window.title != runtime_ref.val.last_applied_title {
    host_window_set_title(host_window, title=window.title)
    runtime_ref.val.last_applied_title = window.title
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
    window_apply_position(host_window, window.position)
    runtime_ref.val.last_applied_position = window.position
  }
  if window.mode != runtime_ref.val.last_applied_mode {
    host_window_set_mode(host_window, mode=window.mode)
    runtime_ref.val.last_applied_mode = window.mode
  }
  if window.visible != runtime_ref.val.last_applied_visible {
    host_window_set_visible(host_window, visible=window.visible)
    runtime_ref.val.last_applied_visible = window.visible
  }
  if window.resizable != runtime_ref.val.last_applied_resizable {
    host_window_set_resizable(host_window, resizable=window.resizable)
    runtime_ref.val.last_applied_resizable = window.resizable
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
    host_window_set_transparent(host_window, transparent=window.transparent)
    runtime_ref.val.last_applied_transparent = window.transparent
  }
  if window.window_level != runtime_ref.val.last_applied_window_level {
    host_window_set_window_level(host_window, level=window.window_level)
    runtime_ref.val.last_applied_window_level = window.window_level
  }
  if window.window_theme != runtime_ref.val.last_applied_window_theme {
    host_window_set_theme(host_window, theme=window.window_theme)
    runtime_ref.val.last_applied_window_theme = window.window_theme
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
  if cursor_icon != runtime_ref.val.last_applied_cursor_icon {
    if cursor_icon is Some(cursor_icon0) {
      host_window_set_cursor_icon(host_window, icon=cursor_icon0)
    } else {
      host_window_set_cursor_icon(host_window, icon=CursorIcon::default())
    }
    runtime_ref.val.last_applied_cursor_icon = cursor_icon
  }
  let requested_drag_move = window.drag_move_request
  let requested_drag_resize = window.drag_resize_request
  if requested_drag_move {
    host_window_drag_move(host_window) |> ignore
  }
  if requested_drag_resize is Some(direction) {
    host_window_drag_resize(host_window, direction) |> ignore
  }
  if requested_drag_move || requested_drag_resize is Some(_) {
    ignore(
      window_update_component(world, entity, fn(current) {
        let next : Window = current
        next.drag_move_request = false
        next.drag_resize_request = None
        next
      }),
    )
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
  world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.Without::new(ecs_key_window_runtime)),
  )
  .view(fn(entity) { entities.push(entity) })
  entities
}

///|
fn window_runtime_entities_with_host(world : @ecs.World) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_window_runtime)),
  )
  .view(fn(entity) { entities.push(entity) })
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
  window_backend_prepare_system(world)
  window_backend_apply_requested_system(world)
}

///|
pub fn window_backend_prepare_system(world : @ecs.World) -> Unit {
  for entity in window_runtime_entities_without_host(world) {
    window_create_runtime_for_entity(world, entity) |> ignore
  }
  window_emit_native_theme_events(world)
  window_emit_native_occluded_events(world)
  window_emit_native_app_lifecycle_events(world)
  let runtime_query = world.query1(ecs_key_window_runtime)
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      try! runtime_query.with_mut(entity, fn(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        window_sync_observed_state(world, entity, runtime_ref)
      }),
    )
  }
}

///|
pub fn window_backend_apply_requested_system(world : @ecs.World) -> Unit {
  let runtime_query = world.query1(ecs_key_window_runtime)
  for entity in window_runtime_entities_with_host(world) {
    ignore(
      try! runtime_query.with_mut(entity, fn(runtime_mut) {
        let runtime_ref = runtime_mut.get_ref()
        window_sync_requested_state(world, entity, runtime_ref)
      }),
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
  if cursor_options is Some(cursor_options0) {
    window_set_cursor_options_component(world, entity, cursor_options0)
  }
}

///|
pub fn window_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  window_plugin_with(app, WindowPlugin::default())
}

///|
pub impl @app.PluginReplacement for WindowPlugin with replacement_id(_self) {
  WINDOW_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for WindowPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    window_plugin_with(app, self)
  }
}

///|
pub fn window_plugin_with(
  app : @app.App[@ecs.World],
  plugin : WindowPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(window_plugin_marker_key()) {
    next = next
      .insert_world_resource(window_plugin_marker_key(), WindowPluginMarker::{

      })
      .add_message(ecs_key_window_event)
      .add_message(ecs_key_window_resized)
      .add_message(ecs_key_window_created)
      .add_message(ecs_key_cursor_moved)
      .add_message(ecs_key_cursor_entered)
      .add_message(ecs_key_cursor_left)
      .add_message(ecs_key_window_backend_scale_factor_changed)
      .add_message(ecs_key_window_close_requested)
      .add_message(ecs_key_window_closing)
      .add_message(ecs_key_window_closed)
      .add_message(ecs_key_window_destroyed)
      .add_message(ecs_key_window_focused)
      .add_message(ecs_key_window_occluded)
      .add_message(ecs_key_window_scale_factor_changed)
      .add_message(ecs_key_file_drag_and_drop)
      .add_message(ecs_key_window_moved)
      .add_message(ecs_key_window_theme_changed)
      .add_message(ecs_key_app_lifecycle)
      .add_message(ecs_key_request_redraw)
      .add_message(ecs_key_ime)
      .add_systems(@app.First, @app.system(screenshot_clear_system))
    if plugin.close_when_requested {
      next = next.add_systems(
        @app.Update,
        @app.system(@app.system_param2(close_when_requested)),
      )
    }
    match plugin.exit_condition {
      OnPrimaryClosed =>
        next = next.add_systems(
          @app.PostUpdate,
          @app.system(@app.system_param2(exit_on_primary_closed)),
        )
      OnAllClosed =>
        next = next.add_systems(
          @app.PostUpdate,
          @app.system(@app.system_param2(exit_on_all_closed)),
        )
      DontExit => ()
    }
  }
  if plugin.primary_window is Some(primary_window) {
    window_spawn_primary_window_entity(
      next.world(),
      primary_window,
      plugin.primary_cursor_options,
    )
  }
  next
}

///|
pub fn close_when_requested(
  requested : @ecs.MessageReader[WindowCloseRequested],
  closing : @ecs.EntityQuery[@ecs.With[ClosingWindow]],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let closing_entities : Array[@core.Entity] = []
  closing.view(fn(entity) { closing_entities.push(entity) })
  for entity in closing_entities {
    try! world.despawn(entity)
  }
  let events = try requested.read() catch {
    _ => []
  } noraise {
    value => value
  }
  for event in events {
    if !world.is_alive(event.window) {
      continue
    }
    let is_already_closing = match
      window_closing_component(world, event.window) {
      Some(_) => true
      None => false
    }
    if !is_already_closing {
      window_emit_window_closing(world, WindowClosing::{ window: event.window })
      window_set_closing_component(world, event.window)
    }
  }
}

///|
pub fn exit_on_all_closed(
  app_exit : @ecs.MessageWriter[@app.AppExit],
  windows : @ecs.EntityQuery[@ecs.With[Window]],
) -> Unit {
  if windows.count() == 0 {
    ignore(app_exit.write(@app.AppExit::Success))
  }
}

///|
pub fn exit_on_primary_closed(
  app_exit : @ecs.MessageWriter[@app.AppExit],
  windows : @ecs.EntityQuery[(@ecs.With[Window], @ecs.With[PrimaryWindow])],
) -> Unit {
  if windows.count() == 0 {
    ignore(app_exit.write(@app.AppExit::Success))
  }
}
