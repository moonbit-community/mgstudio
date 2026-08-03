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
priv enum UiOverlayDrawKind {
  Sprite(Int)
  SpriteSliceBatch(Int)
  Rect(Int)
  BoxShadow(Int)
  TextureSlice(Int)
}

///|
priv struct UiOverlayDrawItem {
  kind : UiOverlayDrawKind
  z : Float
  tie : Int
}

///|
fn ui_overlay_cmp_int(lhs : Int, rhs : Int) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
fn ui_overlay_cmp_float(lhs : Float, rhs : Float) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
fn ui_overlay_sort_items(items : Array[UiOverlayDrawItem]) -> Unit {
  items.sort_by(fn(lhs, rhs) {
    let cz = ui_overlay_cmp_float(lhs.z, rhs.z)
    if cz != 0 {
      return cz
    }
    ui_overlay_cmp_int(lhs.tie, rhs.tie)
  })
}

///|
fn ui_overlay_item_position(
  transform : @transform.Transform,
  anchor_offset : @math.Vec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    transform.translation.x + anchor_offset.x,
    transform.translation.y + anchor_offset.y,
  )
}

///|
fn ui_overlay_int_from_f32_floor_nonneg(value : Float) -> Int {
  if value <= 0.0F {
    0
  } else {
    value.to_int()
  }
}

///|
fn ui_overlay_physical_scissor_for_camera(
  rect : @math.Rect,
  viewport_x : Int,
  viewport_y : Int,
  viewport_w : Int,
  viewport_h : Int,
  scale_factor : Float,
) -> (Int, Int, Int, Int) {
  let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let min_x = ui_overlay_int_from_f32_floor_nonneg(rect.min.x * sf)
  let min_y = ui_overlay_int_from_f32_floor_nonneg(rect.min.y * sf)
  let mut max_x = ui_overlay_int_from_f32_floor_nonneg(rect.max.x * sf)
  let mut max_y = ui_overlay_int_from_f32_floor_nonneg(rect.max.y * sf)
  if max_x < min_x {
    max_x = min_x
  }
  if max_y < min_y {
    max_y = min_y
  }
  let mut x = viewport_x + min_x
  let mut y = viewport_y + min_y
  let mut w = max_x - min_x
  let mut h = max_y - min_y
  if x < viewport_x {
    let dx = viewport_x - x
    x = viewport_x
    w = w - dx
  }
  if y < viewport_y {
    let dy = viewport_y - y
    y = viewport_y
    h = h - dy
  }
  let max_w = viewport_w - (x - viewport_x)
  let max_h = viewport_h - (y - viewport_y)
  if w > max_w {
    w = max_w
  }
  if h > max_h {
    h = max_h
  }
  if w < 0 {
    w = 0
  }
  if h < 0 {
    h = 0
  }
  (x, y, w, h)
}

///|
// Bevy source: `bevy/crates/bevy_ui_render/src/lib.rs`.
//
// UI nodes route to a camera through `UiTargetCamera` / the default UI camera
// only; Bevy never consults `RenderLayers` for UI. Filtering by the camera's
// layers here hid every UI node from a camera with non-default layers, such as
// the transform gizmo's overlay camera, which is the highest-order camera on
// the primary window and therefore exactly the one the default UI camera
// selection picks (ISS-478).
fn ui_overlay_items_for_camera(
  nodes : @ui_render_runtime.ExtractedUiNodes,
  camera_entity : @core.Entity,
) -> Array[UiOverlayDrawItem] {
  let items : Array[UiOverlayDrawItem] = []
  let mut tie = 0
  for i in 0..<nodes.sprites.length() {
    let sprite = nodes.sprites[i]
    if @ui_render_runtime.ui_overlay_matches_camera(
        sprite.extracted_camera_entity,
        camera_entity,
      ) {
      items.push({
        kind: Sprite(i),
        z: sprite.payload.transform.translation.z,
        tie,
      })
      tie = tie + 1
    }
  }
  for i in 0..<nodes.sprite_slice_batches.length() {
    let batch = nodes.sprite_slice_batches[i]
    if @ui_render_runtime.ui_overlay_matches_camera(
        batch.extracted_camera_entity,
        camera_entity,
      ) {
      items.push({ kind: SpriteSliceBatch(i), z: batch.payload.z, tie })
      tie = tie + 1
    }
  }
  for i in 0..<nodes.rects.length() {
    let rect = nodes.rects[i]
    if @ui_render_runtime.ui_overlay_matches_camera(
        rect.extracted_camera_entity,
        camera_entity,
      ) {
      items.push({ kind: Rect(i), z: rect.payload.transform.translation.z, tie })
      tie = tie + 1
    }
  }
  for i in 0..<nodes.box_shadows.length() {
    let shadow = nodes.box_shadows[i]
    if @ui_render_runtime.ui_overlay_matches_camera(
        shadow.extracted_camera_entity,
        camera_entity,
      ) {
      items.push({
        kind: BoxShadow(i),
        z: shadow.payload.transform.translation.z,
        tie,
      })
      tie = tie + 1
    }
  }
  for i in 0..<nodes.texture_slices.length() {
    let slice = nodes.texture_slices[i]
    if @ui_render_runtime.ui_overlay_matches_camera(
        slice.extracted_camera_entity,
        camera_entity,
      ) {
      items.push({
        kind: TextureSlice(i),
        z: slice.payload.transform.translation.z,
        tie,
      })
      tie = tie + 1
    }
  }
  ui_overlay_sort_items(items)
  items
}

///|
pub fn draw_extracted_ui_overlay_for_camera(
  world : @ecs.World,
  camera_entity : @core.Entity,
  target_id : Int,
  width_logical : Int,
  height_logical : Int,
  clear : @color.Color,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  viewport_depth_min : Float,
  viewport_depth_max : Float,
  scale_factor : Float,
) -> Unit {
  if width_logical <= 0 ||
    height_logical <= 0 ||
    viewport_width <= 0 ||
    viewport_height <= 0 {
    return
  }
  let nodes = @ui_render_runtime.extracted_ui_nodes_or_empty(world)
  let items = ui_overlay_items_for_camera(nodes, camera_entity)
  if items.length() == 0 {
    return
  }
  @render.host_gpu_begin_pass(
    target_id~,
    width=width_logical,
    height=height_logical,
    clear_r=clear.r,
    clear_g=clear.g,
    clear_b=clear.b,
    clear_a=clear.a,
    camera_x=0.0F,
    camera_y=0.0F,
    camera_rotation=0.0F,
    camera_scale=1.0F,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled=0,
  )
  let mut scissor_active = false
  fn apply_scissor(rect_opt : @math.Rect?) -> Unit {
    match rect_opt {
      None =>
        if scissor_active {
          @render.host_gpu_clear_scissor()
          scissor_active = false
        }
      Some(rect) => {
        let (sx, sy, sw, sh) = ui_overlay_physical_scissor_for_camera(
          rect, viewport_x, viewport_y, viewport_width, viewport_height, scale_factor,
        )
        @render.host_gpu_set_scissor(x=sx, y=sy, width=sw, height=sh)
        scissor_active = true
      }
    }
  }
  for item in items {
    match item.kind {
      Sprite(i) => {
        let sprite = nodes.sprites[i].payload
        apply_scissor(sprite.scissor)
        @render.host_gpu_draw_sprite_uv(
          texture_id=sprite.texture.id(),
          x=sprite.transform.translation.x + sprite.anchor_offset.x,
          y=sprite.transform.translation.y + sprite.anchor_offset.y,
          rotation=sprite.transform.rotation_z(),
          scale_x=sprite.draw_scale.x,
          scale_y=sprite.draw_scale.y,
          color_r=sprite.color.r,
          color_g=sprite.color.g,
          color_b=sprite.color.b,
          color_a=sprite.color.a,
          uv_min_x=sprite.uv_min.x,
          uv_min_y=sprite.uv_min.y,
          uv_max_x=sprite.uv_max.x,
          uv_max_y=sprite.uv_max.y,
        )
      }
      SpriteSliceBatch(i) => {
        let batch = nodes.sprite_slice_batches[i].payload
        apply_scissor(batch.scissor)
        @render.host_gpu_draw_sprite_uv_slices(
          texture_id=batch.texture.id(),
          rotation=batch.rotation,
          scale_x=batch.draw_scale.x,
          scale_y=batch.draw_scale.y,
          color_r=batch.color.r,
          color_g=batch.color.g,
          color_b=batch.color.b,
          color_a=batch.color.a,
          slices_xy_uv=batch.slices_xy_uv,
        )
      }
      Rect(i) => {
        let rect = nodes.rects[i].payload
        apply_scissor(rect.scissor)
        let transform = rect.transform
        let pos = ui_overlay_item_position(transform, rect.anchor_offset)
        @render.host_gpu_draw_ui_rect(
          texture_id=rect.texture.id(),
          x=pos.x,
          y=pos.y,
          rotation=transform.rotation_z(),
          scale_x=rect.draw_scale.x,
          scale_y=rect.draw_scale.y,
          color_r=rect.color.r,
          color_g=rect.color.g,
          color_b=rect.color.b,
          color_a=rect.color.a,
          uv_min_x=rect.uv_min.x,
          uv_min_y=rect.uv_min.y,
          uv_max_x=rect.uv_max.x,
          uv_max_y=rect.uv_max.y,
          flags=rect.flags,
          radius_tl=rect.radius.top_left,
          radius_tr=rect.radius.top_right,
          radius_br=rect.radius.bottom_right,
          radius_bl=rect.radius.bottom_left,
          border_left=rect.border.left,
          border_top=rect.border.top,
          border_right=rect.border.right,
          border_bottom=rect.border.bottom,
        )
      }
      BoxShadow(i) => {
        let shadow = nodes.box_shadows[i].payload
        apply_scissor(shadow.scissor)
        let transform = shadow.transform
        let pos = ui_overlay_item_position(transform, shadow.anchor_offset)
        @render.host_gpu_draw_ui_box_shadow(
          texture_id=shadow.texture.id(),
          x=pos.x,
          y=pos.y,
          rotation=transform.rotation_z(),
          scale_x=shadow.draw_scale.x,
          scale_y=shadow.draw_scale.y,
          color_r=shadow.color.r,
          color_g=shadow.color.g,
          color_b=shadow.color.b,
          color_a=shadow.color.a,
          size_x=shadow.size.x,
          size_y=shadow.size.y,
          radius_tl=shadow.radius.top_left,
          radius_tr=shadow.radius.top_right,
          radius_br=shadow.radius.bottom_right,
          radius_bl=shadow.radius.bottom_left,
          blur=shadow.blur,
          samples=shadow.samples,
        )
      }
      TextureSlice(i) => {
        let slice = nodes.texture_slices[i].payload
        apply_scissor(slice.scissor)
        let transform = slice.transform
        let pos = ui_overlay_item_position(transform, slice.anchor_offset)
        @render.host_gpu_draw_ui_texture_slice(
          texture_id=slice.texture.id(),
          x=pos.x,
          y=pos.y,
          rotation=transform.rotation_z(),
          scale_x=slice.draw_scale.x,
          scale_y=slice.draw_scale.y,
          color_r=slice.color.r,
          color_g=slice.color.g,
          color_b=slice.color.b,
          color_a=slice.color.a,
          texture_slice_l=slice.texture_slices.x,
          texture_slice_t=slice.texture_slices.y,
          texture_slice_r=slice.texture_slices.z,
          texture_slice_b=slice.texture_slices.w,
          target_slice_l=slice.target_slices.x,
          target_slice_t=slice.target_slices.y,
          target_slice_r=slice.target_slices.z,
          target_slice_b=slice.target_slices.w,
          repeat_side_x=slice.repeat.x,
          repeat_side_y=slice.repeat.y,
          repeat_center_x=slice.repeat.z,
          repeat_center_y=slice.repeat.w,
          atlas_l=slice.atlas_rect.x,
          atlas_t=slice.atlas_rect.y,
          atlas_r=slice.atlas_rect.z,
          atlas_b=slice.atlas_rect.w,
        )
      }
    }
  }
  if scissor_active {
    @render.host_gpu_clear_scissor()
  }
  @render.host_gpu_end_pass()
}
