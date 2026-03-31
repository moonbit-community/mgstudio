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
const COLUMNS : Int = 10

///|
const ROWS : Int = 10

///|
const TILE_SIZE : Float = 40.0F

///|
struct DragState {
  mut active : @core.Entity?
  mut hovered : @core.Entity?
  mut start_position : @math.Vec2
}

///|
fn DragState::default() -> DragState {
  { active: None, hovered: None, start_position: @math.Vec2::new(0.0F, 0.0F) }
}

///|
let drag_state_resource_key : @ecs.ResourceKey[DragState] = @ecs.register_resource(
  debug_name="examples.ui.ui_drag_and_drop.DragState",
)

///|
pub impl @app.Resource for DragState with resource() {
  drag_state_resource_key
}

///|
fn tile_color_a() -> @sprite.Color {
  @sprite.Color::srgb(0.2F, 0.2F, 0.8F)
}

///|
fn tile_color_b() -> @sprite.Color {
  @sprite.Color::srgb(0.8F, 0.2F, 0.2F)
}

///|
fn tile_hover_color_a() -> @sprite.Color {
  @sprite.Color::srgb(0.3F, 0.3F, 0.92F)
}

///|
fn tile_hover_color_b() -> @sprite.Color {
  @sprite.Color::srgb(0.92F, 0.3F, 0.3F)
}

///|
fn tile_border_color_a() -> @sprite.Color {
  @sprite.Color::srgb(0.16F, 0.16F, 0.66F)
}

///|
fn tile_border_color_b() -> @sprite.Color {
  @sprite.Color::srgb(0.66F, 0.16F, 0.16F)
}

///|
fn tile_hover_border_color_a() -> @sprite.Color {
  @sprite.Color::srgb(0.25F, 0.25F, 0.82F)
}

///|
fn tile_hover_border_color_b() -> @sprite.Color {
  @sprite.Color::srgb(0.82F, 0.25F, 0.25F)
}

///|
fn tile_node(column : Int, row : Int) -> @ui.Node {
  @ui.Node::{
    ..@ui.Node::default(),
    width: @ui.Val::Px(TILE_SIZE),
    height: @ui.Val::Px(TILE_SIZE),
    border: @ui.UiRect::all(@ui.Val::Px(4.0F)),
    grid_row: @ui.GridPlacement::start(row + 1),
    grid_column: @ui.GridPlacement::start(column + 1),
    align_items: @ui.AlignItems::Center,
    justify_content: @ui.JustifyContent::Center,
  }
}

///|
fn label_font(font : @asset.Handle[@asset.Font]) -> @text.TextFont {
  @text.TextFont::default()
  .with_font(font)
  .with_font_size(@text.FontSize::Px(16.0F))
}

///|
fn set_tile_colors(
  entity : @core.Entity,
  background : @sprite.Color,
  border : @sprite.Color,
  query : @ecs.Query[
    (@ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
    @ecs.All,
  ],
) -> Unit {
  if (try! query.get(entity)) is Some((background_color, border_color)) {
    background_color.set(@ui.BackgroundColor::new(background))
    border_color.set(@ui.BorderColor::new(border))
  }
}

///|
fn begin_drag(
  entity : @core.Entity,
  position : @math.Vec2,
  drag_state : @app.ResMut[DragState],
  visuals : @ecs.Query[
    (@ecs.Mut[@ui.Outline], @ecs.Mut[@ui.GlobalZIndex]),
    @ecs.All,
  ],
) -> Unit {
  let state_ref = drag_state.get_ref()
  state_ref.val.active = Some(entity)
  state_ref.val.hovered = Some(entity)
  state_ref.val.start_position = position
  if (try! visuals.get(entity)) is Some((outline, global_z)) {
    outline.set(
      @ui.Outline::new(
        @ui.Val::Px(2.0F),
        @ui.Val::Px(0.0F),
        @sprite.Color::white(),
      ),
    )
    global_z.set(@ui.GlobalZIndex::new(1))
  }
}

///|
fn drag_active_tile(
  pointer : @app.OnPointer[@app.PointerMove],
  drag_state : @app.ResMut[DragState],
  transforms : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.All],
) -> Unit {
  let state_ref = drag_state.get_ref()
  guard state_ref.val.active is Some(active) else { return }
  if (try! transforms.get(active)) is Some(transform) {
    let current = pointer.position()
    let start = state_ref.val.start_position
    let delta_x = current.x - start.x
    let delta_y = current.y - start.y
    let transform_ref = transform.get_ref()
    let z = transform_ref.val.translation.z
    transform_ref.val.translation = @math.Vec3::new(delta_x, delta_y, z)
  }
}

///|
fn release_active_tile(
  _pointer : @app.OnPointer[@app.PointerUp],
  drag_state : @app.ResMut[DragState],
  visuals : @ecs.Query[
    (
      @ecs.Mut[@transform.Transform],
      @ecs.Mut[@ui.Outline],
      @ecs.Mut[@ui.GlobalZIndex],
    ),
    @ecs.All,
  ],
  nodes : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
) -> Unit {
  let state_ref = drag_state.get_ref()
  guard state_ref.val.active is Some(active) else { return }

  if (try! visuals.get(active)) is Some((transform, outline, global_z)) {
    let transform_ref = transform.get_ref()
    let z = transform_ref.val.translation.z
    transform_ref.val.translation = @math.Vec3::new(0.0F, 0.0F, z)
    outline.set(@ui.Outline::default())
    global_z.set(@ui.GlobalZIndex::new(0))
  }

  if state_ref.val.hovered is Some(hovered) &&
    hovered != active &&
    (try! nodes.get(active)) is Some(active_node) &&
    (try! nodes.get(hovered)) is Some(hovered_node) {
    let active_value = active_node.value()
    let hovered_value = hovered_node.value()
    active_node.set(@ui.Node::{
      ..active_value,
      grid_row: hovered_value.grid_row,
      grid_column: hovered_value.grid_column,
    })
    hovered_node.set(@ui.Node::{
      ..hovered_value,
      grid_row: active_value.grid_row,
      grid_column: active_value.grid_column,
    })
  }

  state_ref.val.active = None
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(DragState::default())
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.4F, 0.4F, 0.4F)),
    ),
  )

  let board = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default().with_display(@ui.Display::Grid),
    ),
  )

  for column in 0..<COLUMNS {
    for row in 0..<ROWS {
      let index = column + row * COLUMNS
      let is_even = (row % 2 + column) % 2 == 0
      let tile_color = if is_even { tile_color_a() } else { tile_color_b() }
      let tile_hover_color = if is_even {
        tile_hover_color_a()
      } else {
        tile_hover_color_b()
      }
      let tile_border_color = if is_even {
        tile_border_color_a()
      } else {
        tile_border_color_b()
      }
      let tile_hover_border_color = if is_even {
        tile_hover_border_color_a()
      } else {
        tile_hover_border_color_b()
      }

      let tile = commands.spawn(
        (
          @hierarchy.Parent::new(board),
          tile_node(column, row),
          @transform.Transform::identity(),
          @ui.Outline::default(),
          @ui.GlobalZIndex::new(0),
          @ui.BorderColor::new(tile_border_color),
          @ui.BackgroundColor::new(tile_color),
        ),
      )
      commands.spawn(
        (
          @hierarchy.Parent::new(tile),
          @text.Text::new(index.to_string()),
          label_font(font),
          @text.TextColor::new(@sprite.Color::white()),
        ),
      )
      |> ignore

      let tile_commands = commands.entity(tile)
      ignore(
        tile_commands
        .observe_pointer3(fn(
          _pointer : @app.OnPointer[@app.PointerEnter],
          drag_state : @app.ResMut[DragState],
          colors : @ecs.Query[
            (@ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
            @ecs.All,
          ],
        ) {
          drag_state.get_ref().val.hovered = Some(tile)
          set_tile_colors(
            tile, tile_hover_color, tile_hover_border_color, colors,
          )
        })
        .observe_pointer3(fn(
          _pointer : @app.OnPointer[@app.PointerLeave],
          drag_state : @app.ResMut[DragState],
          colors : @ecs.Query[
            (@ecs.Mut[@ui.BackgroundColor], @ecs.Mut[@ui.BorderColor]),
            @ecs.All,
          ],
        ) {
          let state_ref = drag_state.get_ref()
          if state_ref.val.hovered is Some(hovered) && hovered == tile {
            state_ref.val.hovered = None
          }
          set_tile_colors(tile, tile_color, tile_border_color, colors)
        })
        .observe_pointer3(fn(
          pointer : @app.OnPointer[@app.PointerDown],
          drag_state : @app.ResMut[DragState],
          visuals : @ecs.Query[
            (@ecs.Mut[@ui.Outline], @ecs.Mut[@ui.GlobalZIndex]),
            @ecs.All,
          ],
        ) {
          begin_drag(tile, pointer.position(), drag_state, visuals)
        }),
      )
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param2(setup)
  .add_pointer_observer3(drag_active_tile)
  .add_pointer_observer4(release_active_tile)
  .run()
}
