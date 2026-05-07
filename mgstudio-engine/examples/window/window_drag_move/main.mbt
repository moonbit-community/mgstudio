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
pub(all) enum LeftClickAction {
  Nothing
  Move
  Resize
} derive(Eq, Debug)

///|
struct ResizeDir {
  mut index : Int
}

///|
struct ExampleText {} derive(Eq, Debug)

///|
let left_click_action_key : @ecs.ResourceKey[LeftClickAction] = @ecs.register_resource(
  debug_name="examples.window.window_drag_move.LeftClickAction",
)

///|
let resize_dir_key : @ecs.ResourceKey[ResizeDir] = @ecs.register_resource(
  debug_name="examples.window.window_drag_move.ResizeDir",
)

///|
let example_text_key : @ecs.ComponentKey[ExampleText] = @ecs.register_component(
  debug_name="examples.window.window_drag_move.ExampleText",
)

///|
impl @app.Resource for LeftClickAction with resource() {
  left_click_action_key
}

///|
impl @app.Resource for ResizeDir with resource() {
  resize_dir_key
}

///|
fn direction_by_index(index : Int) -> @math.CompassOctant {
  match index {
    0 => @math.CompassOctant::North
    1 => @math.CompassOctant::NorthEast
    2 => @math.CompassOctant::East
    3 => @math.CompassOctant::SouthEast
    4 => @math.CompassOctant::South
    5 => @math.CompassOctant::SouthWest
    6 => @math.CompassOctant::West
    _ => @math.CompassOctant::NorthWest
  }
}

///|
fn cycle_left_click_action(action : LeftClickAction) -> LeftClickAction {
  match action {
    Move => Resize
    Resize => Nothing
    Nothing => Move
  }
}

///|
fn instruction_text(
  action : LeftClickAction,
  direction : @math.CompassOctant,
) -> String {
  "Demonstrate drag move and drag resize without window decorations.\n\nControls:\nA - change left click action [\{to_repr(action).to_string()}]\nS / D - change resize direction [\{to_repr(direction).to_string()}]\n"
}

///|
fn find_instruction_text_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref(None)
  try! world
  .query_entities_filtered(@ecs.With::new(example_text_key))
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn refresh_instruction_text(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(left_click_action_key)) is Some(action) else {
    return
  }
  guard (try! world.get_resource(resize_dir_key)) is Some(direction) else {
    return
  }
  guard find_instruction_text_entity(world) is Some(entity) else { return }
  guard (try! world.get_by_key(entity, @text.ecs_key_text)) is Some(text_value) else {
    return
  }
  text_value.content = instruction_text(
    action,
    direction_by_index(direction.index),
  )
  ignore(try! world.replace(entity, @text.ecs_key_text, text_value))
}

///|
fn setup(world : @ecs.World) -> Unit {
  @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(1).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  let camera_tick = world.read_sequence()
  ignore(camera_tick)
  try! world.set_by_key(
    overlay_camera,
    @ui.IsDefaultUiCamera::component(),
    @ui.IsDefaultUiCamera::default(),
  )

  let content = instruction_text(
    LeftClickAction::Move,
    @math.CompassOctant::NorthWest,
  )
  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(0.0F))
    .with_left(@ui.Val::Px(0.0F))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(5.0F))),
  )
  try! world.set_by_key(
    root,
    @ui.GlobalZIndex::component(),
    @ui.GlobalZIndex::new(2147483647),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(0.0F))
    .with_left(@ui.Val::Px(0.0F))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(5.0F))),
  )
  try! world.set_by_key(
    root,
    @ui.GlobalZIndex::component(),
    @ui.GlobalZIndex::new(2147483647),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::new(0.0F, 0.0F, 0.0F, 0.75F)),
  )
  try! world.set_by_key(
    root,
    @ui.ecs_key_ui_target_camera,
    @ui.UiTargetCamera::new(overlay_camera),
  )
  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default(),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  try! world.set_by_key(text_entity, example_text_key, ExampleText::{  })
}

///|
fn handle_input(
  input : @input.ButtonInput[@window.KeyCode],
  action : @app.ResMut[LeftClickAction],
  direction : @app.ResMut[ResizeDir],
) -> Unit {
  guard @app.current_world() is Some(world) else { return }
  let mut changed = false
  if input.just_pressed(KeyA) {
    action.set(cycle_left_click_action(action.get()))
    changed = true
  }
  if input.just_pressed(KeyS) {
    direction.modify(fn(value) {
      let current = value.index
      value.index = if current <= 0 { 7 } else { current - 1 }
    })
    changed = true
  }
  if input.just_pressed(KeyD) {
    direction.modify(fn(value) { value.index = (value.index + 1) % 8 })
    changed = true
  }
  if changed {
    refresh_instruction_text(world)
  }
}

///|
fn move_or_resize_windows(
  input : @input.ButtonInput[@window.MouseButton],
  action : @app.Res[LeftClickAction],
  direction : @app.Res[ResizeDir],
) -> Unit {
  if !input.just_pressed(Left) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  let window_query : @ecs.Query[@ecs.Mut[@window.Window], @ecs.All] = @ecs.query(
    world,
  )
  try! world
  .query_entities_filtered(@ecs.With::new(@window.ecs_key_window))
  .view(fn(_query_entity, entity) {
    ignore(
      if (window_query.get(entity) catch { _ => None }) is Some(window_mut) {
        window_mut.modify(fn(value) {
          match action.get() {
            Nothing => ()
            Move => value.start_drag_move()
            Resize =>
              value.start_drag_resize(direction_by_index(direction.get().index))
          }
        })
      },
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(ResizeDir::{ index: 7 })
  .insert_resource(LeftClickAction::Move)
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(
        {
          let window = @window.Window::default()
          window.decorations = false
          window
        },
      ),
      primary_cursor_options: Some(@window.CursorOptions::default()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param3(handle_input)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(move_or_resize_windows)),
  )
  .run()
}
