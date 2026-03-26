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
const GRID_WIDTH : Int = 60

///|
const GRID_HEIGHT : Int = 40

///|
const TILE_SIZE : Float = 100.0F

///|
const UI_SCALE_FACTOR : Float = 0.5F

///|
struct ScrollableNode {}

///|
let scrollable_node_key : @ecs.ComponentKey[ScrollableNode] = @ecs.register_component(
  debug_name="examples.ui.scroll_and_overflow.drag_to_scroll.ScrollableNode",
)

///|
pub impl @ecs.Component for ScrollableNode with component() {
  scrollable_node_key
}

///|
struct ScrollDragState {
  mut active_entity : @core.Entity?
  mut start_pointer : @math.Vec2
  mut start_offset_x : Float
  mut start_offset_y : Float
}

///|
let scroll_drag_state_key : @ecs.ResourceKey[ScrollDragState] = @ecs.register_resource(
  debug_name="examples.ui.scroll_and_overflow.drag_to_scroll.ScrollDragState",
)

///|
pub impl @app.Resource for ScrollDragState with resource() {
  scroll_drag_state_key
}

///|
pub impl Default for ScrollDragState with default() {
  {
    active_entity: None,
    start_pointer: @math.Vec2::zero(),
    start_offset_x: 0.0F,
    start_offset_y: 0.0F,
  }
}

///|
fn tile_color(x : Int, y : Int) -> @sprite.Color {
  if (x + y) % 2 == 0 {
    @sprite.Color::black()
  } else {
    let hue = Float::from_int(x) / Float::from_int(GRID_WIDTH) * 270.0F +
      Float::from_int(y) / Float::from_int(GRID_HEIGHT) * 90.0F
    @sprite.Color::hsl(hue, 1.0F, 0.5F)
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  commands.queue(fn(world : @ecs.World) {
    world.insert_resource(
      @ui.ecs_key_ui_scale,
      @ui.UiScale::new(UI_SCALE_FACTOR),
    )
    world.insert_resource(scroll_drag_state_key, ScrollDragState::default())
  })

  let scroll_area = commands.spawn(
    (
      @ui.UiRoot::default(),
      ScrollableNode::{  },
      @ui.RelativeCursorPosition::default(),
      @ui.ScrollPosition::new(0.0F, 0.0F),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_overflow(
        @ui.Overflow::new(@ui.OverflowAxis::Scroll, @ui.OverflowAxis::Scroll),
      ),
    ),
  )

  let grid = commands.spawn(
    (
      @hierarchy.Parent::new(scroll_area),
      @ui.Node::{
        ..@ui.Node::default(),
        display: @ui.Display::Grid,
        grid_template_rows: [
          @ui.RepeatedGridTrack::new(
            @ui.GridTrackRepetition::Count(GRID_HEIGHT),
            [@ui.GridTrack::Px(TILE_SIZE)],
          ),
        ],
        grid_template_columns: [
          @ui.RepeatedGridTrack::new(
            @ui.GridTrackRepetition::Count(GRID_WIDTH),
            [@ui.GridTrack::Px(TILE_SIZE)],
          ),
        ],
      },
    ),
  )

  for y in 0..<GRID_HEIGHT {
    for x in 0..<GRID_WIDTH {
      commands.spawn(
        (
          @hierarchy.Parent::new(grid),
          @ui.Node::{
            ..@ui.Node::default(),
            grid_row: @ui.GridPlacement::start(y + 1),
            grid_column: @ui.GridPlacement::start(x + 1),
          },
          @ui.BackgroundColor::new(tile_color(x, y)),
        ),
      )
      |> ignore
    }
  }
}

///|
fn start_drag(
  pointer : @app.OnPointer[@app.PointerDown],
  drag_state : @app.ResMut[ScrollDragState],
  scroll_nodes : @ecs.Query[
    (
      (@core.Entity, @ecs.Comp[ScrollableNode]),
      (@ecs.Comp[@ui.RelativeCursorPosition], @ecs.Comp[@ui.ScrollPosition]),
    ),
    @ecs.All,
  ],
) -> Unit raise {
  let state = drag_state.get_ref()
  state.val.active_entity = None
  let pointer_position = pointer.position()
  scroll_nodes.view(fn(_entity, data) {
    let ((entity, _marker), (relative_cursor_position, scroll_position)) = data
    if state.val.active_entity is Some(_) {
      return
    }
    if !relative_cursor_position.value().cursor_over() {
      return
    }
    state.val.active_entity = Some(entity)
    state.val.start_pointer = pointer_position
    state.val.start_offset_x = scroll_position.value().offset_x
    state.val.start_offset_y = scroll_position.value().offset_y
  })
}

///|
fn update_drag(
  pointer : @app.OnPointer[@app.PointerMove],
  drag_state : @app.ResMut[ScrollDragState],
  scroll_positions : @ecs.Query[@ecs.Mut[@ui.ScrollPosition], @ecs.All],
) -> Unit raise {
  let state = drag_state.get_ref()
  guard state.val.active_entity is Some(entity) else { return }
  guard scroll_positions.get(entity) is Some(scroll_position) else {
    state.val.active_entity = None
    return
  }

  let pointer_position = pointer.position()
  let delta_x = (pointer_position.x - state.val.start_pointer.x) /
    UI_SCALE_FACTOR
  let delta_y = (pointer_position.y - state.val.start_pointer.y) /
    UI_SCALE_FACTOR
  let next_x = (state.val.start_offset_x - delta_x).max(0.0F)
  let next_y = (state.val.start_offset_y - delta_y).max(0.0F)
  scroll_position.set(@ui.ScrollPosition::new(next_x, next_y))
}

///|
fn end_drag(drag_state : @app.ResMut[ScrollDragState]) -> Unit raise {
  if @app.current_world() is Some(world) {
    let entity_query : @ecs.QueryState[@core.Entity, @ecs.All] = world.query()
    ignore(entity_query.single(world))
  }
  drag_state.get_ref().val.active_entity = None
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param(setup)
  .add_pointer_observer3(start_drag)
  .add_pointer_observer3(update_drag)
  .add_pointer_observer2(fn(
    _pointer : @app.OnPointer[@app.PointerUp],
    drag_state : @app.ResMut[ScrollDragState],
  ) raise {
    end_drag(drag_state)
  })
  .run()
}
