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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/popover.rs`.
pub(all) enum PopoverSide {
  Top
  Bottom
  Left
  Right
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PopoverSide::default() -> PopoverSide {
  PopoverSide::Bottom
}

///|
pub fn PopoverSide::mirror(self : PopoverSide) -> PopoverSide {
  match self {
    Top => Bottom
    Bottom => Top
    Left => Right
    Right => Left
  }
}

///|
pub(all) enum PopoverAlign {
  Start
  Center
  End
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PopoverAlign::default() -> PopoverAlign {
  PopoverAlign::Start
}

///|
pub struct PopoverPlacement {
  side : PopoverSide
  align : PopoverAlign
  gap : Float
} derive(ToJson, FromJson)

///|
pub fn PopoverPlacement::default() -> PopoverPlacement {
  PopoverPlacement::{
    side: PopoverSide::default(),
    align: PopoverAlign::default(),
    gap: 0.0F,
  }
}

///|
pub struct Popover {
  positions : Array[PopoverPlacement]
  window_margin : Float
} derive(ToJson, FromJson)

///|
pub fn Popover::default() -> Popover {
  Popover::{ positions: [PopoverPlacement::default()], window_margin: 0.0F }
}

///|
pub let ecs_key_popover : @ecs.ComponentKey[Popover] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Popover",
)

///|
pub impl @ecs.Component for Popover with component() {
  ecs_key_popover
}

///|
fn popover_rect_area(rect : @math.Rect) -> Float {
  let size = rect.size()
  if size.x <= 0.0F || size.y <= 0.0F {
    0.0F
  } else {
    size.x * size.y
  }
}

///|
fn popover_rect_intersect(a : @math.Rect, b : @math.Rect) -> @math.Rect {
  let min = @math.Vec2::new(a.min.x.max(b.min.x), a.min.y.max(b.min.y))
  let max = @math.Vec2::new(a.max.x.min(b.max.x), a.max.y.min(b.max.y))
  @math.Rect::new(min, max)
}

///|
fn popover_best_rect(
  popover_size : @math.Vec2,
  parent_rect : @math.Rect,
  window_rect : @math.Rect,
  positions : Array[PopoverPlacement],
) -> @math.Rect {
  let candidates = if positions.is_empty() {
    [PopoverPlacement::default()]
  } else {
    positions
  }
  let mut best_occluded = 1.0F / 0.0F
  let mut best_rect = @math.Rect::new(parent_rect.min, parent_rect.min)
  for placement in candidates {
    let mut min = parent_rect.min
    let mut max = parent_rect.min
    match placement.side {
      Top => {
        max = @math.Vec2::new(max.x, parent_rect.min.y - placement.gap)
        min = @math.Vec2::new(min.x, max.y - popover_size.y)
      }
      Bottom => {
        min = @math.Vec2::new(min.x, parent_rect.max.y + placement.gap)
        max = @math.Vec2::new(max.x, min.y + popover_size.y)
      }
      Left => {
        max = @math.Vec2::new(parent_rect.min.x - placement.gap, max.y)
        min = @math.Vec2::new(max.x - popover_size.x, min.y)
      }
      Right => {
        min = @math.Vec2::new(parent_rect.max.x + placement.gap, min.y)
        max = @math.Vec2::new(min.x + popover_size.x, max.y)
      }
    }
    match placement.align {
      Start =>
        match placement.side {
          Top | Bottom => {
            min = @math.Vec2::new(parent_rect.min.x, min.y)
            max = @math.Vec2::new(min.x + popover_size.x, max.y)
          }
          Left | Right => {
            min = @math.Vec2::new(min.x, parent_rect.min.y)
            max = @math.Vec2::new(max.x, min.y + popover_size.y)
          }
        }
      End =>
        match placement.side {
          Top | Bottom => {
            max = @math.Vec2::new(parent_rect.max.x, max.y)
            min = @math.Vec2::new(max.x - popover_size.x, min.y)
          }
          Left | Right => {
            max = @math.Vec2::new(max.x, parent_rect.max.y)
            min = @math.Vec2::new(min.x, max.y - popover_size.y)
          }
        }
      Center =>
        match placement.side {
          Top | Bottom => {
            let left = parent_rect.min.x +
              (parent_rect.size().x - popover_size.x) * 0.5F
            min = @math.Vec2::new(left, min.y)
            max = @math.Vec2::new(left + popover_size.x, max.y)
          }
          Left | Right => {
            let top = parent_rect.min.y +
              (parent_rect.size().y - popover_size.y) * 0.5F
            min = @math.Vec2::new(min.x, top)
            max = @math.Vec2::new(max.x, top + popover_size.y)
          }
        }
    }
    let candidate = @math.Rect::new(min, max)
    let clipped = popover_rect_intersect(candidate, window_rect)
    let occluded = popover_rect_area(candidate) - popover_rect_area(clipped)
    if occluded < best_occluded {
      best_occluded = occluded
      best_rect = candidate
    }
  }
  best_rect
}

///|
fn position_popover_system(world : @ecs.World) -> Unit {
  world.for_each_component(ecs_key_popover, fn(entity, popover) {
    guard (world.get_by_key(entity, @ui.ecs_key_node) catch {
        _ => (None : @ui.Node?)
      })
      is Some(node) else {
      return
    }
    guard (world.get_by_key(entity, @ui.ecs_key_ui_layout) catch {
        _ => (None : @ui.UiLayout?)
      })
      is Some(layout) else {
      return
    }
    guard (world.get_by_key(entity, @ui.ecs_key_computed_ui_render_target_info) catch {
        _ => (None : @ui.ComputedUiRenderTargetInfo?)
      })
      is Some(target_info) else {
      return
    }
    guard (world.get_by_key(entity, @hierarchy.ecs_key_parent) catch {
        _ => (None : @hierarchy.Parent?)
      })
      is Some(parent_comp) else {
      return
    }
    guard (world.get_by_key(parent_comp.entity(), @ui.ecs_key_ui_layout) catch {
        _ => (None : @ui.UiLayout?)
      })
      is Some(parent_layout) else {
      return
    }
    let window_size = target_info.logical_size()
    let margin = popover.window_margin
    let window_rect = @math.Rect::new(
      @math.Vec2::new(margin, margin),
      @math.Vec2::new(window_size.x - margin, window_size.y - margin),
    )
    let best_rect = popover_best_rect(
      layout.size(),
      parent_layout.rect(),
      window_rect,
      popover.positions,
    )
    let parent_rect = parent_layout.rect()
    let next_node = node
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(best_rect.min.x - parent_rect.min.x))
      .with_top(@ui.Val::Px(best_rect.min.y - parent_rect.min.y))
      .with_right(@ui.Val::Auto)
      .with_bottom(@ui.Val::Auto)
    if !(world.replace(entity, @ui.ecs_key_node, next_node) catch {
        _ => false
      }) {
      world.set_by_key(entity, @ui.ecs_key_node, next_node) catch {
        _ => ()
      }
    }
  })
}

///|
pub fn popover_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_post_update_system_config(
    @app.system(position_popover_system).in_set(@ui.ui_set_prepare),
  )
}
