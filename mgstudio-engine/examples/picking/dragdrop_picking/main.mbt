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
struct DropArea {}

///|
let ecs_key_drop_area : @ecs.ComponentKey[DropArea] = @ecs.register_component(
  debug_name="examples.picking.dragdrop.drop_area",
)

///|
impl @ecs.Component for DropArea with component() {
  ecs_key_drop_area
}

///|
struct DraggableButton {}

///|
let ecs_key_draggable_button : @ecs.ComponentKey[DraggableButton] = @ecs.register_component(
  debug_name="examples.picking.dragdrop.draggable_button",
)

///|
impl @ecs.Component for DraggableButton with component() {
  ecs_key_draggable_button
}

///|
struct GhostPreview {}

///|
let ecs_key_ghost_preview : @ecs.ComponentKey[GhostPreview] = @ecs.register_component(
  debug_name="examples.picking.dragdrop.ghost_preview",
)

///|
impl @ecs.Component for GhostPreview with component() {
  ecs_key_ghost_preview
}

///|
struct DragState {
  mut active : Bool
  mut drop_hovered : Bool
  drop_area : @core.Entity
  mut ghost : @core.Entity?
}

///|
fn DragState::new(drop_area : @core.Entity) -> DragState {
  { active: false, drop_hovered: false, drop_area, ghost: None }
}

///|
let ecs_res_key_drag_state : @ecs.ResourceKey[DragState] = @ecs.register_resource(
  debug_name="examples.picking.dragdrop.state",
)

///|
impl @app.Resource for DragState with resource() {
  ecs_res_key_drag_state
}

///|
fn dragdrop_node_style(
  left : Float,
  top : Float,
  width : Float,
  height : Float,
) -> @ui.Node {
  @ui.Node::default()
  .with_position_type(@ui.PositionType::Absolute)
  .with_left(@ui.Val::Px(left))
  .with_top(@ui.Val::Px(top))
  .with_width(@ui.Val::Px(width))
  .with_height(@ui.Val::Px(height))
  .with_justify_content(@ui.JustifyContent::Center)
  .with_align_items(@ui.AlignItems::Center)
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      @sprite.Camera2dBundle::new(
        @sprite.Camera::default(),
        @transform.Transform::identity(),
      ),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.08F, 0.09F)),
    ),
  )
  let drop_area = commands.spawn(
    (
      DropArea::{  },
      @ui.Button::default(),
      dragdrop_node_style(300.0F, 150.0F, 500.0F, 500.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.4F, 0.1F)),
    ),
  )
  commands.entity(drop_area).insert_component(@hierarchy.Parent::new(root))
  let drop_text = commands.spawn(
    (
      @text.Text::new("Drop here"),
      @text.TextColor::new(@sprite.Color::black()),
      @text.TextFont::from_font_size(@text.FontSize::Px(44.0F)),
    ),
  )
  commands.entity(drop_text).insert_component(@hierarchy.Parent::new(drop_area))

  let button = commands.spawn(
    (
      DraggableButton::{  },
      @ui.Button::default(),
      dragdrop_node_style(40.0F, 40.0F, 180.0F, 56.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
    ),
  )
  commands.entity(button).insert_component(@hierarchy.Parent::new(root))
  let button_text = commands.spawn(
    (
      @text.Text::new("Drag from me"),
      @text.TextColor::new(@sprite.Color::white()),
      @text.TextFont::from_font_size(@text.FontSize::Px(24.0F)),
    ),
  )
  commands.entity(button_text).insert_component(@hierarchy.Parent::new(button))

  commands.insert_resource(DragState::new(drop_area))
}

///|
fn on_drag_start(
  pointer : @app.OnPointer[@app.PointerDown],
  commands : @app.Commands,
  drag_state : @app.ResMut[DragState],
  draggables : @ecs.Query[@ecs.Comp[DraggableButton], @ecs.All],
) -> Unit {
  guard pointer.target() is Some(target) else { return }
  guard (try! draggables.get(target)) is Some(_) else { return }
  let state = drag_state.get_ref()
  state.val.active = true
  state.val.drop_hovered = false
  if state.val.ghost is Some(ghost) {
    commands.entity(ghost).despawn()
  }
  let ghost = commands.spawn(
    (
      GhostPreview::{  },
      dragdrop_node_style(
        pointer.position().x,
        pointer.position().y,
        30.0F,
        30.0F,
      ),
      @ui.BackgroundColor::new(@sprite.Color::new(1.0F, 1.0F, 0.6F, 0.5F)),
    ),
  )
  state.val.ghost = Some(ghost)
}

///|
fn on_drag_move(
  pointer : @app.OnPointer[@app.PointerMove],
  drag_state : @app.ResMut[DragState],
  ghost_nodes : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.All],
) -> Unit {
  let state = drag_state.get_ref()
  guard state.val.active else { return }
  state.val.drop_hovered = pointer.target() == Some(state.val.drop_area)
  if state.val.ghost is Some(ghost) &&
    (try! ghost_nodes.get(ghost)) is Some(node) {
    let next = node
      .value()
      .with_left(@ui.Val::Px(pointer.position().x - 15.0F))
      .with_top(@ui.Val::Px(pointer.position().y - 15.0F))
    node.get_ref().val = next
  }
}

///|
fn on_drag_end(
  pointer : @app.OnPointer[@app.PointerUp],
  commands : @app.Commands,
  drag_state : @app.ResMut[DragState],
) -> Unit {
  let state = drag_state.get_ref()
  guard state.val.active else { return }
  if state.val.drop_hovered {
    ignore(
      commands.spawn(
        (
          dragdrop_node_style(
            pointer.position().x - 12.0F,
            pointer.position().y - 12.0F,
            24.0F,
            24.0F,
          ),
          @ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 1.0F, 0.6F)),
        ),
      ),
    )
  }
  if state.val.ghost is Some(ghost) {
    commands.entity(ghost).despawn()
  }
  state.val.active = false
  state.val.drop_hovered = false
  state.val.ghost = None
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param(setup)
  .add_pointer_observer4(fn(pointer, commands, drag_state, draggables) {
    on_drag_start(pointer, commands, drag_state, draggables)
  })
  .add_pointer_observer3(fn(pointer, drag_state, ghost_nodes) {
    on_drag_move(pointer, drag_state, ghost_nodes)
  })
  .add_pointer_observer3(fn(pointer, commands, drag_state) {
    on_drag_end(pointer, commands, drag_state)
  })
  .run()
}
