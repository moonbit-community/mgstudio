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
/// Minimal, Bevy-aligned UI MVP.
///
/// Baseline: Bevy v0.15.3 (see docs/BEVY_BASELINE.md).
///
/// MVP limitations:
/// - right/bottom are ignored
/// - rendering uses 2D sprites + a shared 1x1 white texture
/// - layout is a very small subset of Bevy UI:
///   - `PositionType::Absolute` supports left/top + px/percent sizing
///   - `PositionType::Relative` supports a minimal row layout using `justify_content`/`align_items`
///   - `Val::Auto` only resolves to measured size for `UiText` nodes; otherwise it is `0`

///|
pub(all) enum Val {
  Auto
  Px(Float)
  Percent(Float)
}

///|
pub struct UiSize {
  width : Val
  height : Val
}

///|
pub fn UiSize::new(width : Val, height : Val) -> UiSize {
  UiSize::{ width, height }
}

///|
pub fn UiSize::default() -> UiSize {
  UiSize::new(Val::Auto, Val::Auto)
}

///|
pub struct UiRect {
  left : Val
  top : Val
  right : Val
  bottom : Val
}

///|
pub fn UiRect::new(left : Val, top : Val, right : Val, bottom : Val) -> UiRect {
  UiRect::{ left, top, right, bottom }
}

///|
pub fn UiRect::default() -> UiRect {
  UiRect::new(Val::Auto, Val::Auto, Val::Auto, Val::Auto)
}

///| Bevy-aligned position type (subset).
pub(all) enum PositionType {
  Relative
  Absolute
} derive(Eq, Show)

///| Bevy-aligned justify content (subset).
pub(all) enum JustifyContent {
  FlexStart
  Center
} derive(Eq, Show)

///| Bevy-aligned align items (subset).
pub(all) enum AlignItems {
  FlexStart
  Center
} derive(Eq, Show)

///| The style of a UI node (MVP subset).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Style {
  position : UiRect
  size : UiSize
  z_index : Int
  position_type : PositionType
  justify_content : JustifyContent
  align_items : AlignItems
}

///|
pub fn Style::new(position : UiRect, size : UiSize, z_index : Int) -> Style {
  Style::{
    position,
    size,
    z_index,
    position_type: PositionType::Relative,
    justify_content: JustifyContent::FlexStart,
    align_items: AlignItems::FlexStart,
  }
}

///|
pub fn Style::default() -> Style {
  Style::new(UiRect::default(), UiSize::default(), 0)
}

///|
pub fn Style::with_position_type(
  self : Style,
  position_type : PositionType,
) -> Style {
  Style::{ ..self, position_type }
}

///|
pub fn Style::with_justify_content(
  self : Style,
  justify_content : JustifyContent,
) -> Style {
  Style::{ ..self, justify_content }
}

///|
pub fn Style::with_align_items(self : Style, align_items : AlignItems) -> Style {
  Style::{ ..self, align_items }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiRoot {}

///|
pub fn UiRoot::default() -> UiRoot {
  UiRoot::{  }
}

///| Computed layout rectangle in logical pixels, top-left origin (viewport space).
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiLayout {
  rect : @math.Rect
}

///|
pub fn UiLayout::new(rect : @math.Rect) -> UiLayout {
  UiLayout::{ rect }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct BackgroundColor {
  color : @render2d.Color
}

///|
pub fn BackgroundColor::new(color : @render2d.Color) -> BackgroundColor {
  BackgroundColor::{ color }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiImage {
  image : @asset.Handle[@asset.Image]
}

///|
pub fn UiImage::new(image : @asset.Handle[@asset.Image]) -> UiImage {
  UiImage::{ image }
}

///|
///| Bevy-aligned interaction state component.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub(all) enum Interaction {
  None
  Hovered
  Pressed
} derive(Eq, Show)

///| Bevy-aligned button marker component.
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Button {}

///|
pub fn Button::default() -> Button {
  Button::{  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ButtonColors {
  normal : @render2d.Color
  hovered : @render2d.Color
  pressed : @render2d.Color
}

///|
pub fn ButtonColors::new(
  normal : @render2d.Color,
  hovered : @render2d.Color,
  pressed : @render2d.Color,
) -> ButtonColors {
  ButtonColors::{ normal, hovered, pressed }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct UiText {
  handle : @text.TextHandle
}

///|
pub fn UiText::new(handle : @text.TextHandle) -> UiText {
  UiText::{ handle }
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct UiContext {
  mut white_texture : @asset.Handle[@asset.Image]
  mut viewport_origin : @math.Vec2
  mut viewport_size : @math.Vec2
  mut camera_entity : @core.Entity?
  mut camera_transform : @math.Transform
  mut camera_scale : Float
  mut pointer_pos : @math.Vec2?
  mut pointer_down : Bool
}

///|
pub fn UiContext::default() -> UiContext {
  UiContext::{
    white_texture: @asset.Handle::new(-1),
    viewport_origin: @math.Vec2::new(0.0F, 0.0F),
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    camera_entity: None,
    camera_transform: @math.Transform::identity(),
    camera_scale: 1.0F,
    pointer_pos: None,
    pointer_down: false,
  }
}

///| Public constructor (required because `UiContext` contains `mut` fields).
pub fn UiContext::new(
  white_texture : @asset.Handle[@asset.Image],
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
  camera_entity : @core.Entity?,
  camera_transform : @math.Transform,
  camera_scale : Float,
  pointer_pos : @math.Vec2?,
  pointer_down : Bool,
) -> UiContext {
  UiContext::{
    white_texture,
    viewport_origin,
    viewport_size,
    camera_entity,
    camera_transform,
    camera_scale,
    pointer_pos,
    pointer_down,
  }
}

///|
pub let ui_set_context : @app.SystemSet = @app.system_set("mgstudio.ui.context")

///|
pub let ui_set_layout : @app.SystemSet = @app.system_set("mgstudio.ui.layout")

///|
pub let ui_set_interaction : @app.SystemSet = @app.system_set(
  "mgstudio.ui.interaction",
)

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn safe_scale_factor(scale : Float) -> Float {
  if scale <= 0.0F { 1.0F } else { scale }
}

///|
fn safe_camera_scale(scale : Float) -> Float {
  if scale <= 0.0F { 1.0F } else { scale }
}

///| Resolve a UI `Val` against a parent size in pixels.
fn resolve_val(val : Val, parent_px : Float) -> Float {
  match val {
    Auto => 0.0F
    Px(v) => v
    Percent(p) => parent_px * (p / 100.0F)
  }
}

///|
fn resolve_val_with_auto(val : Val, parent_px : Float, auto_px : Float) -> Float {
  match val {
    Auto => auto_px
    Px(v) => v
    Percent(p) => parent_px * (p / 100.0F)
  }
}

///|
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///| Convert a window-space pointer into viewport-space coordinates.
///
/// Returns `None` if the pointer is outside the viewport bounds.
pub fn ui_pointer_pos_in_viewport(
  mouse_pos : @math.Vec2,
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
) -> @math.Vec2? {
  let pos_in_view = @math.Vec2::new(
    mouse_pos.x - viewport_origin.x,
    mouse_pos.y - viewport_origin.y,
  )
  if pos_in_view.x >= 0.0F &&
    pos_in_view.y >= 0.0F &&
    pos_in_view.x <= viewport_size.x &&
    pos_in_view.y <= viewport_size.y {
    Some(pos_in_view)
  } else {
    None
  }
}

///|
fn[W : HasRes_UiContext + @core.ChangeTickWorld] ensure_ui_context_resource(
  world : W,
) -> Ref[UiContext]? {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_UiContext::get_ui_context_resource(world)
  if !res.is_present() {
    res.insert(UiContext::default(), tick)
  }
  res.get_ref_mut(tick)
}

///|
fn create_white_texture_if_needed(ctx : Ref[UiContext]) -> Unit {
  // In unit tests we may pre-seed a dummy handle; avoid touching host APIs then.
  if ctx.val.white_texture.id() > 0 {
    return
  }
  let size = @math.UVec2::new(1, 1)
  let handle = @asset.asset_create_dynamic_texture(size, true)
  let rect = @math.URect::new(@math.UVec2::new(0, 0), @math.UVec2::new(1, 1))
  // moonbitlang/parser may not accept method calls on integer literals.
  let u : Int = 255
  let b : Byte = u.to_byte()
  let bytes = Bytes::from_array([b, b, b, b])
  @asset.asset_update_texture_region_rgba8(handle, rect, bytes)
  ctx.val.white_texture = handle
}

///|
fn clamp_viewport_to_window(
  viewport : @render2d.Viewport,
  win_w : Int,
  win_h : Int,
) -> @render2d.Viewport {
  let mut x = viewport.physical_position.x
  let mut y = viewport.physical_position.y
  let mut w = viewport.physical_size.x
  let mut h = viewport.physical_size.y

  if x < 0 { x = 0 }
  if y < 0 { y = 0 }
  if w < 0 { w = 0 }
  if h < 0 { h = 0 }

  let max_w = if win_w - x < 0 { 0 } else { win_w - x }
  let max_h = if win_h - y < 0 { 0 } else { win_h - y }
  if w > max_w { w = max_w }
  if h > max_h { h = max_h }

  @render2d.Viewport::new(@math.IVec2::new(x, y), @math.IVec2::new(w, h))
}

///|
pub fn[
  W :
    HasRes_UiContext +
    @render2d.Has_Camera2d +
    @render2d.Has_Camera +
    @render2d.Has_Projection +
    @render2d.Has_RenderTarget +
    @math.Has_Transform +
    @transform.Has_GlobalTransform +
    @core.ChangeTickWorld,
] ui_update_context_system(world : W) -> Unit {
  guard ensure_ui_context_resource(world) is Some(ctx) else { return }
  create_white_texture_if_needed(ctx)

  let win_w = @window.window_width()
  let win_h = @window.window_height()
  let sf = safe_scale_factor(@window.window_scale_factor())

  // Select a screen Camera2d with the smallest order (Bevy-like).
  let camera2d_store = @render2d.Has_Camera2d::get_camera2d_store(world)
  let camera_store = @render2d.Has_Camera::get_camera_store(world)
  let projection_store = @render2d.Has_Projection::get_projection_store(world)
  let target_store = @render2d.Has_RenderTarget::get_render_target_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let global_store = @transform.Has_GlobalTransform::get_global_transform_store(
    world,
  )

  let mut best_entity : @core.Entity? = None
  let mut best_order : Int = 0
  camera2d_store.for_each(fn(entity, _marker) {
    let target = match target_store.get(entity) {
      Some(t) => t
      None => @render2d.RenderTarget::Screen
    }
    if target is @render2d.Image(_) {
      return
    }
    let camera = match camera_store.get(entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    match best_entity {
      None => {
        best_entity = Some(entity)
        best_order = camera.order
      }
      Some(_) => {
        if camera.order < best_order {
          best_entity = Some(entity)
          best_order = camera.order
        }
      }
    }
  })

  let mut viewport_origin = @math.Vec2::new(0.0F, 0.0F)
  let mut viewport_size = @math.Vec2::new(
    int_to_float(win_w) / sf,
    int_to_float(win_h) / sf,
  )
  let mut camera_transform = @math.Transform::identity()
  let mut camera_scale = 1.0F

  if best_entity is Some(cam_entity) {
    let camera = match camera_store.get(cam_entity) {
      Some(v) => v
      None => @render2d.Camera::default()
    }
    let projection = match projection_store.get(cam_entity) {
      Some(@render2d.Orthographic(p)) => p
      _ => @render2d.OrthographicProjection::default_2d()
    }
    camera_scale = safe_camera_scale(projection.scale)
    camera_transform = match global_store.get(cam_entity) {
      Some(gt) => gt.to_transform_approx()
      None =>
        match transform_store.get(cam_entity) {
          Some(t) => t
          None => @math.Transform::identity()
        }
    }

    if camera.viewport is Some(vp0) {
      let vp = clamp_viewport_to_window(vp0, win_w, win_h)
      viewport_origin = @math.Vec2::new(
        int_to_float(vp.physical_position.x) / sf,
        int_to_float(vp.physical_position.y) / sf,
      )
      viewport_size = @math.Vec2::new(
        int_to_float(vp.physical_size.x) / sf,
        int_to_float(vp.physical_size.y) / sf,
      )
    }
  }

  // Pointer (window space -> viewport space).
  let pointer_pos = match @input.mouse_position() {
    Some(mouse) => ui_pointer_pos_in_viewport(mouse, viewport_origin, viewport_size)
    None => None
  }

  ctx.val.viewport_origin = viewport_origin
  ctx.val.viewport_size = viewport_size
  ctx.val.camera_entity = best_entity
  ctx.val.camera_transform = camera_transform
  ctx.val.camera_scale = camera_scale
  ctx.val.pointer_pos = pointer_pos
  ctx.val.pointer_down = @input.mouse_button_pressed(@window.MouseButton::Left)
}

///|
fn[
  W :
    @core.ChangeTickWorld +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility,
] ensure_visibility_defaults(
  world : W,
  entity : @core.Entity,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let vis_store = @visibility.Has_Visibility::get_visibility_store(world)
  if !vis_store.contains(entity) {
    vis_store.insert(entity, @visibility.Visibility::Inherited, tick)
  }
  let inherited_store = @visibility.Has_InheritedVisibility::get_inherited_visibility_store(
    world,
  )
  if !inherited_store.contains(entity) {
    inherited_store.insert(entity, @visibility.InheritedVisibility::new(true), tick)
  }
  let view_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  if !view_store.contains(entity) {
    view_store.insert(entity, @visibility.ViewVisibility::new(true), tick)
  }
}

///|
fn[W : @core.ChangeTickWorld + @render2d.Has_RenderLayers] ensure_layers_default(
  world : W,
  entity : @core.Entity,
) -> @render2d.RenderLayers {
  let store = @render2d.Has_RenderLayers::get_render_layers_store(world)
  match store.get(entity) {
    Some(v) => v
    None => {
      let tick = @core.ChangeTickWorld::read_change_tick(world)
      let layers = @render2d.RenderLayers::default()
      store.insert(entity, layers, tick)
      layers
    }
  }
}

///|
fn style_size(
  parent : @math.Rect,
  style : Style,
  auto_size : @math.Vec2,
) -> @math.Vec2 {
  let parent_size = parent.size()
  let w = resolve_val_with_auto(style.size.width, parent_size.x, auto_size.x)
  let h = resolve_val_with_auto(style.size.height, parent_size.y, auto_size.y)
  @math.Vec2::new(w, h)
}

///|
fn style_rect_absolute(
  parent : @math.Rect,
  style : Style,
  auto_size : @math.Vec2,
) -> @math.Rect {
  let parent_size = parent.size()
  let size = style_size(parent, style, auto_size)
  let x = resolve_val(style.position.left, parent_size.x)
  let y = resolve_val(style.position.top, parent_size.y)
  let min = @math.Vec2::new(parent.min.x + x, parent.min.y + y)
  let max = @math.Vec2::new(min.x + size.x, min.y + size.y)
  @math.Rect::new(min, max)
}

///|
fn ui_world_transform(
  ctx : UiContext,
  rect : @math.Rect,
  z_index : Int,
) -> @math.Transform {
  let viewport_w = ctx.viewport_size.x
  let viewport_h = ctx.viewport_size.y
  let cam_scale = safe_camera_scale(ctx.camera_scale)
  let cam_rot = ctx.camera_transform.rotation_z()
  let cam_pos = @math.Vec2::new(
    ctx.camera_transform.translation.x,
    ctx.camera_transform.translation.y,
  )

  let center = rect.center()
  let half_w = viewport_w / 2.0F
  let half_h = viewport_h / 2.0F
  // Viewport top-left origin -> viewport center origin, with +Y up.
  let center_px = @math.Vec2::new(center.x - half_w, half_h - center.y)
  let center_scaled = @math.Vec2::new(
    center_px.x * cam_scale,
    center_px.y * cam_scale,
  )
  let offset = rotate_vec2(center_scaled, cam_rot)
  let world_pos = @math.Vec2::new(cam_pos.x + offset.x, cam_pos.y + offset.y)

  let z = 10000.0F + Float::from_double(z_index.to_double())
  @math.Transform::from_xy_rotation_scale(
    world_pos,
    cam_rot,
    @math.Vec2::new(cam_scale, cam_scale),
    z=z,
  )
}

///|
fn button_color_for_state(
  colors : ButtonColors,
  state : Interaction?,
) -> @render2d.Color {
  match state {
    Some(s) =>
      match s {
        Interaction::Pressed => colors.pressed
        Interaction::Hovered => colors.hovered
        Interaction::None => colors.normal
      }
    None => colors.normal
  }
}

///|
pub fn[
  W :
    HasRes_UiContext +
    Has_UiRoot +
    Has_Style +
    Has_UiLayout +
    Has_BackgroundColor +
    Has_UiImage +
    Has_ButtonColors +
    Has_Interaction +
    Has_UiText +
    @hierarchy.Has_Children +
    @render2d.Has_Sprite +
    @render2d.Has_RenderLayers +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility +
    @math.Has_Transform +
    @core.ChangeTickWorld,
] ui_layout_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }
  guard ctx0.camera_entity is Some(_) else { return }

  let root_store = Has_UiRoot::get_ui_root_store(world)
  let style_store = Has_Style::get_style_store(world)
  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)

  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let bg_store = Has_BackgroundColor::get_background_color_store(world)
  let img_store = Has_UiImage::get_ui_image_store(world)
  let button_store = Has_ButtonColors::get_button_colors_store(world)
  let interaction_store = Has_Interaction::get_interaction_store(world)
  let ui_text_store = Has_UiText::get_ui_text_store(world)

  let transform_store = @math.Has_Transform::get_transform_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)

  let root_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(ctx0.viewport_size.x, ctx0.viewport_size.y),
  )

  fn should_draw_node(
    sprite_store : @core.ComponentStore[@render2d.Sprite],
    bg_store : @core.ComponentStore[BackgroundColor],
    img_store : @core.ComponentStore[UiImage],
    button_store : @core.ComponentStore[ButtonColors],
    entity : @core.Entity,
  ) -> Bool {
    sprite_store.contains(entity) ||
    bg_store.contains(entity) ||
    img_store.contains(entity) ||
    button_store.contains(entity)
  }

  fn auto_size_for_entity(entity : @core.Entity) -> @math.Vec2 {
    match ui_text_store.get(entity) {
      Some(text_node) =>
        match @text.text_get_layout_size(text_node.handle) {
          Some(sz) => sz
          None => @math.Vec2::new(0.0F, 0.0F)
        }
      None => @math.Vec2::new(0.0F, 0.0F)
    }
  }

  fn layout_subtree(
    entity : @core.Entity,
    parent_rect : @math.Rect,
    assigned_rect : @math.Rect?,
  ) -> Unit {
    let style_opt = style_store.get(entity)
    let self_rect = match (assigned_rect, style_opt) {
      (Some(r), _) => r
      (None, Some(style)) =>
        match style.position_type {
          PositionType::Absolute =>
            style_rect_absolute(parent_rect, style, auto_size_for_entity(entity))
          PositionType::Relative => parent_rect
        }
      (None, None) => parent_rect
    }
    // Container style defaults (mirrors Bevy defaults loosely; only the subset we implement matters).
    let self_style = match style_opt {
      Some(s) => s
      None => Style::default()
    }

    // Update UiLayout when this node has an explicit Style.
    if style_opt is Some(_) {
      let layout = UiLayout::new(self_rect)
      if layout_store.contains(entity) {
        layout_store.set(entity, layout, tick) |> ignore
      } else {
        layout_store.insert(entity, layout, tick)
      }
    }

    // Update render2d / transform for styled nodes.
    if style_opt is Some(style) {
      let transform = ui_world_transform(ctx0, self_rect, style.z_index)
      if transform_store.contains(entity) {
        transform_store.set(entity, transform, tick) |> ignore
      } else {
        transform_store.insert(entity, transform, tick)
      }
      let layers = ensure_layers_default(world, entity)
      ensure_visibility_defaults(world, entity)

      if should_draw_node(sprite_store, bg_store, img_store, button_store, entity) {
        let texture = match img_store.get(entity) {
          Some(v) => v.image
          None => ctx0.white_texture
        }
        let size = self_rect.size()
        let button_colors_opt = button_store.get(entity)
        let color = match button_colors_opt {
          Some(colors) => button_color_for_state(colors, interaction_store.get(entity))
          None =>
            match bg_store.get(entity) {
              Some(v) => v.color
              None => @render2d.Color::white()
            }
        }
        let sprite = @render2d.Sprite::from_image(texture)
          .with_color(color)
          .with_custom_size(Some(size))
        if sprite_store.contains(entity) {
          sprite_store.set(entity, sprite, tick) |> ignore
        } else {
          sprite_store.insert(entity, sprite, tick)
        }
      }

      // Sync text handles (state-based text pipeline) for label nodes.
      if ui_text_store.get(entity) is Some(text_node) {
        let text_node_size = self_rect.size()
        // Bevy UI parity: glyph positions are laid out in top-left origin (+Y down).
        // The text renderer uses `ui_node_size` to translate from node center to node top-left.
        @text.text_set_y_axis(text_node.handle, @text.YAxisOrientation::TopToBottom)
        @text.text_set_ui_node_size(text_node.handle, Some(text_node_size))
        @text.text_set_transform(text_node.handle, transform)
        @text.text_set_layers(text_node.handle, layers)
      }
    }

    // Traverse children.
    if children_store.get(entity) is Some(children) {
      // First pass: layout absolute-positioned children immediately; collect relative children
      // for a minimal row-layout (Bevy-like defaults).
      let relative_entities : Array[@core.Entity] = []
      let relative_sizes : Array[@math.Vec2] = []
      for child in children.entities {
        match style_store.get(child) {
          None => layout_subtree(child, self_rect, None)
          Some(child_style) =>
            match child_style.position_type {
              PositionType::Absolute => {
                let child_rect = style_rect_absolute(
                  self_rect,
                  child_style,
                  auto_size_for_entity(child),
                )
                layout_subtree(child, self_rect, Some(child_rect))
              }
              PositionType::Relative => {
                let child_size = style_size(
                  self_rect,
                  child_style,
                  auto_size_for_entity(child),
                )
                relative_entities.push(child)
                relative_sizes.push(child_size)
              }
            }
        }
      }

      if relative_entities.length() > 0 {
        let parent_size = self_rect.size()
        let mut total_w = 0.0F
        for i in 0..<relative_entities.length() {
          total_w = total_w + relative_sizes[i].x
        }
        let mut start_x = 0.0F
        match self_style.justify_content {
          JustifyContent::FlexStart => start_x = 0.0F
          JustifyContent::Center => {
            let dx = (parent_size.x - total_w) / 2.0F
            start_x = if dx < 0.0F { 0.0F } else { dx }
          }
        }
        let mut cursor_x = start_x
        for i in 0..<relative_entities.length() {
          let child = relative_entities[i]
          let child_size = relative_sizes[i]
          let mut y = 0.0F
          match self_style.align_items {
            AlignItems::FlexStart => y = 0.0F
            AlignItems::Center => {
              let dy = (parent_size.y - child_size.y) / 2.0F
              y = if dy < 0.0F { 0.0F } else { dy }
            }
          }
          let min = @math.Vec2::new(self_rect.min.x + cursor_x, self_rect.min.y + y)
          let max = @math.Vec2::new(min.x + child_size.x, min.y + child_size.y)
          let child_rect = @math.Rect::new(min, max)
          layout_subtree(child, self_rect, Some(child_rect))
          cursor_x = cursor_x + child_size.x
        }
      }
    }
  }

  let mut any_root = false
  root_store.for_each(fn(root, _marker) {
    any_root = true
    layout_subtree(root, root_rect, None)
  })
  any_root |> ignore
}

///|
pub fn[
  W :
    HasRes_UiContext +
    Has_UiLayout +
    Has_Button +
    Has_Interaction +
    Has_ButtonColors +
    @render2d.Has_Sprite +
    @core.ChangeTickWorld,
] ui_interaction_system(world : W) -> Unit {
  let res = HasRes_UiContext::get_ui_context_resource(world)
  guard res.get() is Some(ctx0) else { return }

  let layout_store = Has_UiLayout::get_ui_layout_store(world)
  let button_store = Has_Button::get_button_store(world)
  let state_store = Has_Interaction::get_interaction_store(world)
  let colors_store = Has_ButtonColors::get_button_colors_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)

  let pointer = ctx0.pointer_pos
  let down = ctx0.pointer_down

  button_store.for_each(fn(entity, _button) {
    guard layout_store.get(entity) is Some(layout) else { return }
    let mut new_value = Interaction::None
    if pointer is Some(p) && layout.rect.contains(p) {
      new_value = if down { Interaction::Pressed } else { Interaction::Hovered }
    }
    let prev = state_store.get(entity)
    let changed = match prev {
      Some(s) => s != new_value
      None => true
    }
    if changed {
      let next = new_value
      if state_store.contains(entity) {
        state_store.set(entity, next, tick) |> ignore
      } else {
        state_store.insert(entity, next, tick)
      }
    }

    // Convenience: if `ButtonColors` is present, keep the button sprite color in sync here.
    // Bevy's UI renderer reads `BackgroundColor` directly; our sprite-based UI uses this as an MVP.
    if colors_store.get(entity) is Some(colors) && sprite_store.get(entity) is Some(sprite0) {
      let desired = button_color_for_state(colors, state_store.get(entity))
      let sprite = sprite0.with_color(desired)
      sprite_store.set(entity, sprite, tick) |> ignore
    }
  })
}

///|
pub fn[
  W :
    HasRes_UiContext +
    Has_UiRoot +
    Has_Style +
    Has_UiLayout +
    Has_BackgroundColor +
    Has_UiImage +
    Has_ButtonColors +
    Has_Button +
    Has_Interaction +
    Has_UiText +
    @hierarchy.Has_Children +
    @render2d.Has_Camera2d +
    @render2d.Has_Camera +
    @render2d.Has_Projection +
    @render2d.Has_RenderTarget +
    @render2d.Has_RenderLayers +
    @render2d.Has_Sprite +
    @math.Has_Transform +
    @transform.Has_GlobalTransform +
    @visibility.Has_Visibility +
    @visibility.Has_InheritedVisibility +
    @visibility.Has_ViewVisibility +
    @core.ChangeTickWorld,
] ui_plugin(app : @app.App[W]) -> @app.App[W] {
  app
  .add_pre_update_system_config(
    @app.system(ui_update_context_system).in_set(ui_set_context),
  )
  .add_pre_update_system_config(
    @app.system(ui_layout_system).in_set(ui_set_layout),
  )
  .add_pre_update_system_config(
    @app.system(ui_interaction_system).in_set(ui_set_interaction),
  )
  .configure_set(@app.PreUpdate, ui_set_context, before=[ui_set_layout])
  .configure_set(
    @app.PreUpdate,
    ui_set_layout,
    after=[@transform.transform_set_update_children],
    before=[@transform.transform_set_propagate],
  )
  .configure_set(@app.PreUpdate, ui_set_interaction, after=[ui_set_layout])
}
