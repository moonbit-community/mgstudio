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
struct ContextMenuState {
  mut menu : @core.Entity?
}

///|
let context_menu_state_resource_key : @ecs.ResourceKey[ContextMenuState] = @ecs.register_resource(
  debug_name="examples.usage.context_menu.ContextMenuState",
)

///|
pub impl @app.Resource for ContextMenuState with resource() {
  context_menu_state_resource_key
}

///|
fn close_existing_menu(
  commands : @app.Commands,
  state : @app.ResMut[ContextMenuState],
) -> Unit {
  if state.get().menu is Some(menu_entity) {
    commands.entity(menu_entity).despawn()
    state.modify(fn(value) { value.menu = None })
  }
}

///|
fn spawn_menu_item(
  commands : @app.Commands,
  menu_entity : @core.Entity,
  label : String,
  button_color : @sprite.Color,
  clear_color : @color.Color,
) -> Unit {
  let item = commands.spawn(
    (
      @hierarchy.Parent::new(menu_entity),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(180.0F))
      .with_height(@ui.Val::Px(34.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(6.0F)))
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(button_color),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(item),
      @text.Text::new(label),
      @text.TextFont::default().with_font_size(@text.FontSize::Px(18.0F)),
      @text.TextColor::new(@sprite.Color::white()),
    ),
  )
  |> ignore
  ignore(
    commands
    .entity(item)
    .observe_pointer3(fn(
      _pointer : @app.OnPointer[@app.PointerDown],
      commands : @app.Commands,
      state : @app.ResMut[ContextMenuState],
    ) {
      commands.insert_resource(@sprite.ClearColor::new(clear_color))
      close_existing_menu(commands, state)
    }),
  )
}

///|
fn open_context_menu(
  position : @math.Vec2,
  commands : @app.Commands,
  state : @app.ResMut[ContextMenuState],
) -> Unit {
  close_existing_menu(commands, state)

  let menu = commands.spawn(
    (
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(position.x))
      .with_top(@ui.Val::Px(position.y))
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
      @ui.BorderColor::new(@sprite.Color::black()),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.09F, 0.09F, 0.09F)),
    ),
  )
  state.modify(fn(value) { value.menu = Some(menu) })

  spawn_menu_item(
    commands,
    menu,
    "Fuchsia",
    @sprite.Color::srgb(0.68F, 0.2F, 0.66F),
    @color.Color::srgb(0.68F, 0.2F, 0.66F),
  )
  spawn_menu_item(
    commands,
    menu,
    "Gray",
    @sprite.Color::srgb(0.42F, 0.42F, 0.42F),
    @color.Color::srgb(0.42F, 0.42F, 0.42F),
  )
  spawn_menu_item(
    commands,
    menu,
    "Maroon",
    @sprite.Color::srgb(0.45F, 0.12F, 0.17F),
    @color.Color::srgb(0.45F, 0.12F, 0.17F),
  )
  spawn_menu_item(
    commands,
    menu,
    "Purple",
    @sprite.Color::srgb(0.33F, 0.18F, 0.6F),
    @color.Color::srgb(0.33F, 0.18F, 0.6F),
  )
  spawn_menu_item(
    commands,
    menu,
    "Teal",
    @sprite.Color::srgb(0.12F, 0.5F, 0.5F),
    @color.Color::srgb(0.12F, 0.5F, 0.5F),
  )
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(ContextMenuState::{ menu: None })
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
    ),
  )
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(260.0F))
      .with_height(@ui.Val::Px(68.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(4.0F)))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BorderColor::new(@sprite.Color::black()),
      @ui.BackgroundColor::new(@sprite.Color::black()),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(button),
      @text.Text::new("Open Context Menu"),
      @text.TextFont::default().with_font_size(@text.FontSize::Px(28.0F)),
      @text.TextColor::new(@sprite.Color::white()),
    ),
  )
  |> ignore

  ignore(
    commands
    .entity(button)
    .observe_pointer3(fn(
      pointer : @app.OnPointer[@app.PointerDown],
      commands : @app.Commands,
      state : @app.ResMut[ContextMenuState],
    ) {
      open_context_menu(pointer.position(), commands, state)
    }),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_startup_system_param(setup)
  .run()
}
