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
/// UI-render API boundary aligned with Bevy crate responsibilities.
/// Runtime implementation lives in `Milky2018/mgstudio/ui_render`.

///|
pub(all) enum UiAntiAlias {
  Off
  On
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct BoxShadowSamples {
  samples : Int
} derive(ToJson, FromJson)

///|
pub fn BoxShadowSamples::new(samples : Int) -> BoxShadowSamples {
  let safe = if samples < 0 { 0 } else { samples }
  BoxShadowSamples::{ samples: safe }
}

///|
pub fn BoxShadowSamples::default() -> BoxShadowSamples {
  BoxShadowSamples::new(4)
}

///|
pub let ecs_key_ui_anti_alias : @ecs.ComponentKey[UiAntiAlias] = @ecs.register_component(
  debug_name="ui.ui_anti_alias",
)

///|
pub let ecs_key_ui_box_shadow_samples : @ecs.ComponentKey[BoxShadowSamples] = @ecs.register_component(
  debug_name="ui.ui_box_shadow_samples",
)

///|
pub impl @ecs.Component for UiAntiAlias with component() {
  ecs_key_ui_anti_alias
}

///|
pub impl @ecs.Component for BoxShadowSamples with component() {
  ecs_key_ui_box_shadow_samples
}

///|
pub let ui_render_set_extract : @app.SystemSet = @app.system_set(
  "bevy.ui.render.extract",
)

///|
const UI_DRAW_FLAG_TEXTURED : Int = 1

///|
const UI_DRAW_FLAG_ANTIALIAS : Int = 4

///|
const UI_DRAW_FLAG_BORDER_LEFT : Int = 256

///|
const UI_DRAW_FLAG_BORDER_TOP : Int = 512

///|
const UI_DRAW_FLAG_BORDER_RIGHT : Int = 1024

///|
const UI_DRAW_FLAG_BORDER_BOTTOM : Int = 2048

///|
const UI_STACK_Z_BASE : Float = 10000.0F

///|
const UI_STACK_Z_STEP : Float = 10.0F

///|
const UI_STACK_Z_BACKGROUND : Float = 0.0F

///|
const UI_STACK_Z_SHADOW : Float = -1.0F

///|
const UI_STACK_Z_CONTENT : Float = 1.0F

///|
const UI_STACK_Z_BORDER : Float = 2.0F

///|
const UI_STACK_Z_OUTLINE : Float = 4.0F

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn safe_scale_factor(scale : Float) -> Float {
  if scale <= 0.0F {
    1.0F
  } else {
    scale
  }
}

///|
fn ui_draw_border_flags(
  left : Float,
  top : Float,
  right : Float,
  bottom : Float,
) -> Int {
  let mut flags = 0
  if left > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_LEFT
  }
  if top > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_TOP
  }
  if right > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_RIGHT
  }
  if bottom > 0.0F {
    flags = flags | UI_DRAW_FLAG_BORDER_BOTTOM
  }
  flags
}

///|
fn ensure_ui_scale_resource(world : @ecs.World) -> @ui.UiScale {
  let res = @ui.get_ui_scale_resource(world)
  match res.get() {
    Some(value) => value
    None => {
      let value = @ui.UiScale::new(1.0F)
      res.insert(value)
      value
    }
  }
}

///|
priv struct UiResolvedCameraState {
  camera_entity : @core.Entity?
  viewport_size : @math.Vec2
  render_target_info : @ui.ComputedUiRenderTargetInfo?
}

///|
fn ui_resolved_camera_state_default() -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity: None,
    viewport_size: @math.Vec2::new(0.0F, 0.0F),
    render_target_info: None,
  }
}

///|
fn ui_resolved_camera_state_from_legacy(
  ctx : @ui.UiContext,
) -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity: ctx.camera_entity,
    viewport_size: ctx.viewport_size,
    render_target_info: None,
  }
}

///|
fn ui_resolved_camera_state_from_computed(
  camera_entity : @core.Entity?,
  render_target_info : @ui.ComputedUiRenderTargetInfo,
) -> UiResolvedCameraState {
  UiResolvedCameraState::{
    camera_entity,
    viewport_size: render_target_info.logical_size(),
    render_target_info: Some(render_target_info),
  }
}

///|
fn ui_entity_resolved_camera_state(
  world : @ecs.World,
  entity : @core.Entity,
  legacy_ctx : @ui.UiContext?,
) -> UiResolvedCameraState {
  match
    (try! world.get_by_key(entity, @ui.ecs_key_computed_ui_render_target_info)) {
    Some(render_target_info) =>
      ui_resolved_camera_state_from_computed(
        match
          (try! world.get_by_key(entity, @ui.ecs_key_computed_ui_target_camera)) {
          Some(value) => value.get()
          None => None
        },
        render_target_info,
      )
    None =>
      match legacy_ctx {
        Some(ctx) => ui_resolved_camera_state_from_legacy(ctx)
        None => ui_resolved_camera_state_default()
      }
  }
}

///|
fn clamp_stretch_value(v : Float) -> Float {
  if v < 0.001F {
    0.001F
  } else {
    v
  }
}

///|
fn min3(a : Float, b : Float, c : Float) -> Float {
  let ab = if a < b { a } else { b }
  if ab < c {
    ab
  } else {
    c
  }
}

///|
fn compute_tiled_axis(
  tile : Bool,
  image_extent : Float,
  target_extent : Float,
  stretch_value : Float,
) -> Float {
  if tile {
    let denom = image_extent * clamp_stretch_value(stretch_value)
    if denom == 0.0F {
      1.0F
    } else {
      target_extent / denom
    }
  } else {
    1.0F
  }
}

///|
fn compute_tiled_subaxis(
  image_extent : Float,
  target_extent : Float,
  mode : @ui.SliceScaleMode,
) -> Float {
  match mode {
    @ui.SliceScaleMode::Stretch => 1.0F
    @ui.SliceScaleMode::Tile(stretch_value) => {
      let denom = image_extent * clamp_stretch_value(stretch_value)
      if denom == 0.0F {
        1.0F
      } else {
        target_extent / denom
      }
    }
  }
}

///|
fn compute_texture_slices(
  image_size : @math.Vec2,
  target_size : @math.Vec2,
  mode : @ui.NodeImageMode,
) -> (@math.Vec4, @math.Vec4, @math.Vec4) {
  match mode {
    @ui.NodeImageMode::Sliced(slicer) => {
      let denom_x = if image_size.x == 0.0F { 1.0F } else { image_size.x }
      let denom_y = if image_size.y == 0.0F { 1.0F } else { image_size.y }
      let tdenom_x = if target_size.x == 0.0F { 1.0F } else { target_size.x }
      let tdenom_y = if target_size.y == 0.0F { 1.0F } else { target_size.y }
      let min_coeff = min3(
        target_size.x / denom_x,
        target_size.y / denom_y,
        slicer.max_corner_scale,
      )
      let slices = @math.Vec4::new(
        slicer.border.left / denom_x,
        slicer.border.top / denom_y,
        1.0F - slicer.border.right / denom_x,
        1.0F - slicer.border.bottom / denom_y,
      )
      let border = @math.Vec4::new(
        slicer.border.left / tdenom_x * min_coeff,
        slicer.border.top / tdenom_y * min_coeff,
        1.0F - slicer.border.right / tdenom_x * min_coeff,
        1.0F - slicer.border.bottom / tdenom_y * min_coeff,
      )
      let image_side_width = denom_x * (slices.z - slices.x)
      let image_side_height = denom_y * (slices.w - slices.y)
      let target_side_width = tdenom_x * (border.z - border.x)
      let target_side_height = tdenom_y * (border.w - border.y)
      let repeat_side_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.sides_scale_mode,
      )
      let repeat_side_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.sides_scale_mode,
      )
      let repeat_center_x = compute_tiled_subaxis(
        image_side_width,
        target_side_width,
        slicer.center_scale_mode,
      )
      let repeat_center_y = compute_tiled_subaxis(
        image_side_height,
        target_side_height,
        slicer.center_scale_mode,
      )
      (
        slices,
        border,
        @math.Vec4::new(
          repeat_side_x, repeat_side_y, repeat_center_x, repeat_center_y,
        ),
      )
    }
    @ui.NodeImageMode::Tiled(tile_x, tile_y, stretch_value) => {
      let rx = compute_tiled_axis(
        tile_x,
        image_size.x,
        target_size.x,
        stretch_value,
      )
      let ry = compute_tiled_axis(
        tile_y,
        image_size.y,
        target_size.y,
        stretch_value,
      )
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, rx, ry),
      )
    }
    _ =>
      (
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
        @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
      )
  }
}

///|
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn button_color_for_state(
  colors : @ui.ButtonColors,
  state : @ui.Interaction?,
) -> @sprite.Color {
  match state {
    Some(s) =>
      match s {
        @ui.Interaction::Pressed => colors.pressed
        @ui.Interaction::Hovered => colors.hovered
        @ui.Interaction::None => colors.normal
      }
    None => colors.normal
  }
}

///|
fn vec2_add(a : @math.Vec2, b : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(a.x + b.x, a.y + b.y)
}

///|
fn ui_uv_from_image_rects(
  image_size : @math.Vec2,
  atlas_rect : @math.Rect?,
  rect : @math.Rect?,
  flip_x : Bool,
  flip_y : Bool,
) -> (@math.Vec2, @math.Vec2) {
  let denom_x = image_size.x
  let denom_y = image_size.y
  if denom_x <= 0.0F || denom_y <= 0.0F {
    return (@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 1.0F))
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(denom_x, denom_y),
  )
  let texture_rect = match (atlas_rect, rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = vec2_add(r.min, ar.min)
      let max = vec2_add(r.max, ar.min)
      @math.Rect::new(min, max)
    }
  }
  let mut uv_min = @math.Vec2::new(
    texture_rect.min.x / denom_x,
    texture_rect.min.y / denom_y,
  )
  let mut uv_max = @math.Vec2::new(
    texture_rect.max.x / denom_x,
    texture_rect.max.y / denom_y,
  )
  if flip_x {
    let tmp = uv_min.x
    uv_min = @math.Vec2::new(uv_max.x, uv_min.y)
    uv_max = @math.Vec2::new(tmp, uv_max.y)
  }
  if flip_y {
    let tmp = uv_min.y
    uv_min = @math.Vec2::new(uv_min.x, uv_max.y)
    uv_max = @math.Vec2::new(uv_max.x, tmp)
  }
  (uv_min, uv_max)
}

///|
pub fn ui_render_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let res = @ui.get_ui_context_resource(source_world)
  guard res.get() is Some(ctx0) else { return }
  let legacy_ctx = Some(ctx0)
  let stack_res = @ui.get_ui_stack_resource(source_world)
  guard stack_res.get() is Some(stack0) else { return }
  @sprite_render.render2d_clear_overlay_ui_rects(world)
  @sprite_render.render2d_clear_overlay_ui_box_shadows(world)
  @sprite_render.render2d_clear_overlay_ui_texture_slices(world)
  fn clamp_nonneg(v : Float) -> Float {
    if v < 0.0F {
      0.0F
    } else {
      v
    }
  }

  fn resolve_axis(
    val : @ui.Val,
    node_axis : Float,
    viewport_size : @math.Vec2,
  ) -> Float {
    match val {
      @ui.Val::Auto => 0.0F
      @ui.Val::Px(px) => px
      @ui.Val::Percent(p) => node_axis * (p / 100.0F)
      @ui.Val::Vw(p) => viewport_size.x * (p / 100.0F)
      @ui.Val::Vh(p) => viewport_size.y * (p / 100.0F)
      @ui.Val::VMin(p) => {
        let m = if viewport_size.x < viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
      @ui.Val::VMax(p) => {
        let m = if viewport_size.x > viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
    }
  }

  fn resolve_radius_single(
    val : @ui.Val,
    node_size : @math.Vec2,
    viewport_size : @math.Vec2,
  ) -> Float {
    let min_elem = if node_size.x < node_size.y {
      node_size.x
    } else {
      node_size.y
    }
    let raw = match val {
      @ui.Val::Auto => 0.0F
      @ui.Val::Px(px) => px
      @ui.Val::Percent(p) => min_elem * (p / 100.0F)
      @ui.Val::Vw(p) => viewport_size.x * (p / 100.0F)
      @ui.Val::Vh(p) => viewport_size.y * (p / 100.0F)
      @ui.Val::VMin(p) => {
        let m = if viewport_size.x < viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
      @ui.Val::VMax(p) => {
        let m = if viewport_size.x > viewport_size.y {
          viewport_size.x
        } else {
          viewport_size.y
        }
        m * (p / 100.0F)
      }
    }
    let clamped = clamp_nonneg(raw)
    let max_r = 0.5F * min_elem
    if clamped > max_r {
      max_r
    } else {
      clamped
    }
  }

  fn clamp_radius_nonneg(radius : Float, node_size : @math.Vec2) -> Float {
    let clamped = clamp_nonneg(radius)
    let min_elem = if node_size.x < node_size.y {
      node_size.x
    } else {
      node_size.y
    }
    let max_r = 0.5F * min_elem
    if clamped > max_r {
      max_r
    } else {
      clamped
    }
  }

  fn transform_with_z(
    t : @transform.Transform,
    z : Float,
  ) -> @transform.Transform {
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(t.translation.x, t.translation.y),
      t.rotation_z(),
      @math.Vec2::new(t.scale.x, t.scale.y),
      z~,
    )
  }

  let ui_scale = ensure_ui_scale_resource(source_world)
  let ui_scale_value = if ui_scale.value <= 0.0F {
    1.0F
  } else {
    ui_scale.value
  }
  let legacy_px_per_ui = safe_scale_factor(@window.window_scale_factor()) /
    ui_scale_value
  let uv_min = @math.Vec2::new(0.0F, 0.0F)
  let uv_max = @math.Vec2::new(1.0F, 1.0F)
  for i in 0..<stack0.uinodes.length() {
    let entity = stack0.uinodes[i]
    if (try! source_world.get_by_key(
        entity, @visibility.ecs_key_view_visibility,
      ))
      is Some(vv) &&
      !vv.is_visible() {
      continue
    }
    guard (try! source_world.get_by_key(entity, @ui.ecs_key_ui_layout))
      is Some(layout) else {
      continue
    }
    guard (try! source_world.get_by_key(entity, @ui.ecs_key_node)) is Some(node) else {
      continue
    }
    guard (try! source_world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(t0) else {
      continue
    }
    let entity_ctx = ui_entity_resolved_camera_state(
      source_world, entity, legacy_ctx,
    )
    let viewport_size = entity_ctx.viewport_size
    let shadow_samples = match entity_ctx.camera_entity {
      Some(camera_entity) =>
        match
          (
            try! source_world.get_by_key(
              camera_entity, ecs_key_ui_box_shadow_samples,
            ) : BoxShadowSamples?) {
          Some(v) => v.samples
          None => BoxShadowSamples::default().samples
        }
      None => BoxShadowSamples::default().samples
    }
    let rect = layout.rect
    let size = rect.size()
    if size.x <= 0.0F || size.y <= 0.0F {
      continue
    }
    let layers = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let scissor = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_scissor_rect)) {
      Some(v) => Some(v.rect)
      None => None
    }
    let scale_x = t0.scale.x
    let scale_y = t0.scale.y
    let draw_scale = @math.Vec2::new(scale_x * size.x, scale_y * size.y)
    let scale_min = if scale_x < scale_y { scale_x } else { scale_y }
    let border_left = clamp_nonneg(
        resolve_axis(node.border.left, size.x, viewport_size),
      ) *
      scale_x
    let border_right = clamp_nonneg(
        resolve_axis(node.border.right, size.x, viewport_size),
      ) *
      scale_x
    let border_top = clamp_nonneg(
        resolve_axis(node.border.top, size.y, viewport_size),
      ) *
      scale_y
    let border_bottom = clamp_nonneg(
        resolve_axis(node.border.bottom, size.y, viewport_size),
      ) *
      scale_y
    let border = @sprite.UiBorderRect::new(
      border_left, border_top, border_right, border_bottom,
    )
    let radius = match
      (try! source_world.get_by_key(entity, @ui.ecs_key_border_radius)) {
      Some(r) => {
        let tl = resolve_radius_single(r.top_left, size, viewport_size) *
          scale_min
        let tr = resolve_radius_single(r.top_right, size, viewport_size) *
          scale_min
        let br = resolve_radius_single(r.bottom_right, size, viewport_size) *
          scale_min
        let bl = resolve_radius_single(r.bottom_left, size, viewport_size) *
          scale_min
        @sprite.UiCornerRadii::new(tl, tr, br, bl)
      }
      None => @sprite.UiCornerRadii::zero()
    }
    let mut flags = 0
    let aa_enabled = match
      (
        try! source_world.get_by_key(entity, ecs_key_ui_anti_alias) :
        UiAntiAlias?) {
      Some(UiAntiAlias::Off) => false
      _ => true
    }
    if aa_enabled {
      flags = flags | UI_DRAW_FLAG_ANTIALIAS
    }
    let border_flags = ui_draw_border_flags(
      border_left, border_top, border_right, border_bottom,
    )
    let z_base = UI_STACK_Z_BASE + int_to_float(i) * UI_STACK_Z_STEP

    // BoxShadow (behind background/content/border/text).
    match (try! source_world.get_by_key(entity, @ui.ecs_key_box_shadow)) {
      Some(shadow) =>
        if shadow.color.a > 0.0F {
          let spread_x = resolve_axis(
            shadow.spread_radius,
            size.x,
            viewport_size,
          )
          let spread_ratio = (spread_x + size.x) / size.x
          let spread_y = size.y * spread_ratio - size.y
          let shadow_size = @math.Vec2::new(
            size.x + spread_x,
            size.y + spread_y,
          )
          if shadow_size.x > 0.0F && shadow_size.y > 0.0F {
            let blur = clamp_nonneg(
              resolve_axis(shadow.blur_radius, size.x, viewport_size),
            )
            let bounds = @math.Vec2::new(
              shadow_size.x + 6.0F * blur,
              shadow_size.y + 6.0F * blur,
            )
            if bounds.x > 0.0F && bounds.y > 0.0F {
              let offset_x = resolve_axis(
                shadow.x_offset,
                size.x,
                viewport_size,
              )
              let offset_y = resolve_axis(
                shadow.y_offset,
                size.y,
                viewport_size,
              )
              // UI uses +Y down; world uses +Y up.
              let offset_local = @math.Vec2::new(
                offset_x * scale_x,
                -offset_y * scale_y,
              )
              let offset_world = rotate_vec2(offset_local, t0.rotation_z())
              let t_shadow = @transform.Transform::from_xy_rotation_scale(
                @math.Vec2::new(
                  t0.translation.x + offset_world.x,
                  t0.translation.y + offset_world.y,
                ),
                t0.rotation_z(),
                @math.Vec2::new(t0.scale.x, t0.scale.y),
                z=z_base + UI_STACK_Z_SHADOW,
              )
              let radius_shadow = match
                (try! source_world.get_by_key(entity, @ui.ecs_key_border_radius)) {
                Some(r) => {
                  let tl = resolve_radius_single(
                      r.top_left,
                      size,
                      viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let tr = resolve_radius_single(
                      r.top_right,
                      size,
                      viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let br = resolve_radius_single(
                      r.bottom_right,
                      size,
                      viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  let bl = resolve_radius_single(
                      r.bottom_left,
                      size,
                      viewport_size,
                    ) *
                    spread_ratio *
                    scale_min
                  @sprite.UiCornerRadii::new(tl, tr, br, bl)
                }
                None => @sprite.UiCornerRadii::zero()
              }
              let draw_scale_shadow = @math.Vec2::new(
                scale_x * bounds.x,
                scale_y * bounds.y,
              )
              let size_shadow_world = @math.Vec2::new(
                scale_x * shadow_size.x,
                scale_y * shadow_size.y,
              )
              @sprite_render.render2d_push_ui_box_shadow_scissor(
                world,
                entity,
                entity_ctx.camera_entity,
                ctx0.white_texture,
                t_shadow,
                draw_scale_shadow,
                shadow.color,
                layers,
                scissor,
                size_shadow_world,
                radius_shadow,
                blur * scale_min,
                shadow_samples,
              )
            }
          }
        }
      None => ()
    }

    // Background color.
    let bg_color_opt = match
      (try! source_world.get_by_key(entity, @ui.ecs_key_button_colors)) {
      Some(colors) =>
        Some(
          button_color_for_state(
            colors,
            try! source_world.get_by_key(entity, @ui.ecs_key_interaction),
          ),
        )
      None =>
        match
          (try! source_world.get_by_key(entity, @ui.ecs_key_background_color)) {
          Some(v) => Some(v.color)
          None => None
        }
    }
    match bg_color_opt {
      Some(color) =>
        if color.a > 0.0F {
          let t_bg = transform_with_z(t0, z_base + UI_STACK_Z_BACKGROUND)
          @sprite_render.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            ctx0.white_texture,
            t_bg,
            draw_scale,
            uv_min,
            uv_max,
            color,
            layers,
            scissor,
            flags,
            radius,
            border,
          )
        }
      None => ()
    }

    // Image content (Bevy `ImageNode`, with `UiImage` compatibility).
    let image_info = match
      (try! source_world.get_by_key(entity, @ui.ecs_key_image_node)) {
      Some(img) =>
        Some(
          (
            img.image,
            img.color,
            img.texture_atlas,
            img.rect,
            img.flip_x,
            img.flip_y,
            Some(img.image_mode),
          ),
        )
      None =>
        match (try! source_world.get_by_key(entity, @ui.ecs_key_ui_image)) {
          Some(img) =>
            Some(
              (
                img.image,
                img.color,
                img.texture_atlas,
                img.rect,
                img.flip_x,
                img.flip_y,
                None,
              ),
            )
          None => None
        }
    }
    match image_info {
      Some(info) => {
        let texture = info.0
        let color = info.1
        let texture_atlas = info.2
        let rect = info.3
        let flip_x = info.4
        let flip_y = info.5
        let mode = match info.6 {
          Some(m) => m
          None => @ui.NodeImageMode::Stretch
        }
        let mut image_width = @asset.asset_texture_width(texture)
        let mut image_height = @asset.asset_texture_height(texture)
        if image_width <= 0 || image_height <= 0 {
          // Avoid division by zero for not-yet-loaded textures.
          image_width = 1
          image_height = 1
        }
        let image_size = @math.Vec2::new(
          Float::from_double(image_width.to_double()),
          Float::from_double(image_height.to_double()),
        )
        let atlas_rect = match texture_atlas {
          Some(atlas) =>
            match @asset.asset_get_texture_atlas_layout(atlas.layout) {
              Some(layout_value) =>
                if atlas.index >= 0 &&
                  atlas.index < layout_value.textures.length() {
                  Some(layout_value.textures[atlas.index].as_rect())
                } else {
                  None
                }
              None => None
            }
          None => None
        }
        let pair = ui_uv_from_image_rects(
          image_size, atlas_rect, rect, flip_x, flip_y,
        )
        let uv_min_img = pair.0
        let uv_max_img = pair.1
        let t_content = transform_with_z(t0, z_base + UI_STACK_Z_CONTENT)
        if color.a > 0.0F && @ui.NodeImageMode::uses_slices(mode) {
          // `size` is in logical UI units. Convert to physical pixels before
          // computing slice/tiling parameters to match Bevy.
          let px_per_ui = match entity_ctx.render_target_info {
            Some(render_target_info) => render_target_info.scale_factor()
            None => legacy_px_per_ui
          }
          let target_size = @math.Vec2::new(
            size.x * px_per_ui,
            size.y * px_per_ui,
          )
          // Image slicing uses the size of the selected texture region (atlas/rect).
          let image_rect = @math.Rect::new(
            @math.Vec2::new(0.0F, 0.0F),
            @math.Vec2::new(image_size.x, image_size.y),
          )
          let texture_rect = match (atlas_rect, rect) {
            (None, None) => image_rect
            (None, Some(r)) => r
            (Some(ar), None) => ar
            (Some(ar), Some(r)) => {
              let min = vec2_add(r.min, ar.min)
              let max = vec2_add(r.max, ar.min)
              @math.Rect::new(min, max)
            }
          }
          let region_size = texture_rect.size()
          let (texture_slices, target_slices, repeat) = compute_texture_slices(
            region_size, target_size, mode,
          )
          let atlas_rect_uv = @math.Vec4::new(
            uv_min_img.x,
            uv_min_img.y,
            uv_max_img.x,
            uv_max_img.y,
          )
          @sprite_render.render2d_push_ui_texture_slice_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            texture,
            t_content,
            draw_scale,
            color,
            layers,
            scissor,
            texture_slices,
            target_slices,
            repeat,
            atlas_rect_uv,
          )
        } else if color.a > 0.0F {
          @sprite_render.render2d_push_ui_rect_uv_scissor(
            world,
            entity,
            entity_ctx.camera_entity,
            texture,
            t_content,
            draw_scale,
            uv_min_img,
            uv_max_img,
            color,
            layers,
            scissor,
            flags | UI_DRAW_FLAG_TEXTURED,
            radius,
            border,
          )
        }
      }
      None => ()
    }

    // Border.
    let has_border = border_left > 0.0F ||
      border_right > 0.0F ||
      border_top > 0.0F ||
      border_bottom > 0.0F
    if has_border &&
      (try! source_world.get_by_key(entity, @ui.ecs_key_border_color))
      is Some(bc) &&
      bc.color.a > 0.0F {
      let t_border = transform_with_z(t0, z_base + UI_STACK_Z_BORDER)
      @sprite_render.render2d_push_ui_rect_uv_scissor(
        world,
        entity,
        entity_ctx.camera_entity,
        ctx0.white_texture,
        t_border,
        draw_scale,
        uv_min,
        uv_max,
        bc.color,
        layers,
        scissor,
        flags | border_flags,
        radius,
        border,
      )
    }

    // Outline.
    match (try! source_world.get_by_key(entity, @ui.ecs_key_outline)) {
      Some(outline) =>
        if outline.color.a > 0.0F {
          let outline_width = clamp_nonneg(
            resolve_axis(outline.width, size.x, viewport_size),
          )
          if outline_width > 0.0F {
            let outline_offset = resolve_axis(
              outline.offset,
              size.x,
              viewport_size,
            )
            let outer = outline_offset + outline_width
            let outline_size = @math.Vec2::new(
              size.x + 2.0F * outer,
              size.y + 2.0F * outer,
            )
            if outline_size.x > 0.0F && outline_size.y > 0.0F {
              let t_outline = transform_with_z(t0, z_base + UI_STACK_Z_OUTLINE)
              let outline_draw_scale = @math.Vec2::new(
                scale_x * outline_size.x,
                scale_y * outline_size.y,
              )
              let outline_border = @sprite.UiBorderRect::new(
                outline_width * scale_x,
                outline_width * scale_y,
                outline_width * scale_x,
                outline_width * scale_y,
              )
              let outline_radius = match
                (try! source_world.get_by_key(entity, @ui.ecs_key_border_radius)) {
                Some(r) => {
                  let tl = clamp_radius_nonneg(
                      resolve_radius_single(r.top_left, size, viewport_size) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let tr = clamp_radius_nonneg(
                      resolve_radius_single(r.top_right, size, viewport_size) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let br = clamp_radius_nonneg(
                      resolve_radius_single(r.bottom_right, size, viewport_size) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  let bl = clamp_radius_nonneg(
                      resolve_radius_single(r.bottom_left, size, viewport_size) +
                      outer,
                      outline_size,
                    ) *
                    scale_min
                  @sprite.UiCornerRadii::new(tl, tr, br, bl)
                }
                None =>
                  @sprite.UiCornerRadii::new(
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                    clamp_radius_nonneg(outer, outline_size) * scale_min,
                  )
              }
              @sprite_render.render2d_push_ui_rect_uv_scissor(
                world,
                entity,
                entity_ctx.camera_entity,
                ctx0.white_texture,
                t_outline,
                outline_draw_scale,
                uv_min,
                uv_max,
                outline.color,
                layers,
                scissor,
                flags |
                ui_draw_border_flags(
                  outline_border.left,
                  outline_border.top,
                  outline_border.right,
                  outline_border.bottom,
                ),
                outline_radius,
                outline_border,
              )
            }
          }
        }
      None => ()
    }
  }
}

///|
fn ui_render_extract_system_in_render_app(world : @ecs.World) -> Unit {
  ui_render_extract_system(world)
}

///|
pub fn ui_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @render.with_render_app(app, fn(render_app) {
    render_app
    .add_systems(
      @app.PostUpdate,
      @app.system(ui_render_extract_system_in_render_app).in_set(
        ui_render_set_extract,
      ),
    )
    .configure_set(@app.PostUpdate, ui_render_set_extract, before=[
      @sprite_render.render2d_set_extract,
    ])
  })
}
