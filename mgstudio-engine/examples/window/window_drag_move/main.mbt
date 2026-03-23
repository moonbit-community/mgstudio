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
/// Port of `bevy/examples/window/window_drag_move.rs`.

///|
pub(all) enum LeftClickAction {
  Nothing
  Move
  Resize
} derive(Eq, Show)

///|
struct ResizeDir {
  mut index : Int
}

///|
struct ExampleText {} derive(Eq, Show)

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
  "Demonstrate drag move and drag resize without window decorations.\n\n" +
  "Controls:\n" +
  "A - change left click action [" +
  action.to_string() +
  "]\n" +
  "S / D - change resize direction [" +
  direction.to_string() +
  "]\n"
}

///|
fn find_instruction_text_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(@ecs.With::new(example_text_key))
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
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
  let text_store = world.component(@text.ecs_key_text)
  guard text_store.get(entity) is Some(text_value) else { return }
  text_value.content = instruction_text(
    action,
    direction_by_index(direction.index),
  )
  ignore(text_store.set(entity, text_value))
}

///|
fn setup(world : @ecs.World) -> Unit {
  @pbr.Camera3dBundle::new(
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
  world
  .component(@ui.IsDefaultUiCamera::component())
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default())

  let content = instruction_text(
    LeftClickAction::Move,
    @math.CompassOctant::NorthWest,
  )
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default())
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(0.0F))
    .with_left(@ui.Val::Px(0.0F))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(5.0F))),
  )
  world
  .component(@ui.GlobalZIndex::component())
  .insert(root, @ui.GlobalZIndex::new(2147483647))
  world
  .component(@ui.ecs_key_background_color)
  .insert(
    root,
    @ui.BackgroundColor::new(@sprite.Color::new(0.0F, 0.0F, 0.0F, 0.75F)),
  )
  world
  .component(@ui.ecs_key_ui_target_camera)
  .insert(root, @ui.UiTargetCamera::new(overlay_camera))
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root))
  world
  .component(@text.ecs_key_text)
  .insert(text_entity, @text.Text::new(content))
  world
  .component(@text.ecs_key_text_font)
  .insert(text_entity, @text.TextFont::default())
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()))
  world
  .component(@text.ecs_key_text_layout)
  .insert(text_entity, @text.TextLayout::new_with_justify(@text.Justify::Left))
  world.component(example_text_key).insert(text_entity, ExampleText::{  })
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
    action.get_ref().val = cycle_left_click_action(action.get_ref().val)
    changed = true
  }
  if input.just_pressed(KeyS) {
    let current = direction.get_ref().val.index
    direction.get_ref().val.index = if current <= 0 { 7 } else { current - 1 }
    changed = true
  }
  if input.just_pressed(KeyD) {
    direction.get_ref().val.index = (direction.get_ref().val.index + 1) % 8
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
  let window_query = world.query1(@window.ecs_key_window)
  world
  .query_entities_filtered(@ecs.With::new(@window.ecs_key_window))
  .view(fn(entity) {
    ignore(
      try! window_query.with_mut(entity, fn(window_mut) {
        let window_ref = window_mut.get_ref()
        match action.get() {
          Nothing => ()
          Move => window_ref.val.start_drag_move()
          Resize =>
            window_ref.val.start_drag_resize(
              direction_by_index(direction.get().index),
            )
        }
      }),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(ResizeDir::{ index: 7 })
  .insert_resource(LeftClickAction::Move)
  .add_plugin_group(fn() {
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
    })
  })
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param3(handle_input)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(move_or_resize_windows)),
  )
  .run()
}
