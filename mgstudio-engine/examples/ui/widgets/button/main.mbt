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
fn normal_button_color() -> @sprite.Color {
  @sprite.Color::new(0.15F, 0.15F, 0.15F, 1.0F)
}

///|
fn hovered_button_color() -> @sprite.Color {
  @sprite.Color::new(0.25F, 0.25F, 0.25F, 1.0F)
}

///|
fn pressed_button_color() -> @sprite.Color {
  @sprite.Color::new(0.35F, 0.75F, 0.35F, 1.0F)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_system_config(@app.system(button_system).after(@ui.ui_set_focus))
  .run()
}

///|
fn button_system(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
  let a11y_state_resource = @a11y.get_a11y_state_resource(world)
  let mut a11y_state_ref : Ref[@a11y.A11yState]? = None
  if a11y_state_resource.get() is Some(a11y_state) {
    a11y_state_ref = Some(Ref::new(a11y_state))
  }
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    if !(try! world.contains_by_key(entity, @ui.ecs_key_button)) {
      return
    }
    if a11y_state_ref is Some(a11y_state) {
      match interaction {
        @ui.Interaction::Pressed | @ui.Interaction::Hovered =>
          @a11y.A11yState::set_focused_node(
            a11y_state,
            @a11y.node_id_for_entity(entity),
          )
        @ui.Interaction::None =>
          @a11y.A11yState::set_focused_node(
            a11y_state,
            @moon_accesskit.NodeId::root(),
          )
      }
    }
    let text = match interaction {
      @ui.Interaction::Pressed => "Press"
      @ui.Interaction::Hovered => "Hover"
      @ui.Interaction::None => "Button"
    }
    let bg_color = match interaction {
      @ui.Interaction::Pressed => pressed_button_color()
      @ui.Interaction::Hovered => hovered_button_color()
      @ui.Interaction::None => normal_button_color()
    }
    let border_color = match interaction {
      @ui.Interaction::Pressed => @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
      @ui.Interaction::Hovered => @sprite.Color::white()
      @ui.Interaction::None => @sprite.Color::black()
    }
    if interaction != @ui.Interaction::None {
      if (try! world.get_by_key(entity, @ui.ecs_key_button)) is Some(button) {
        try! (world.replace(entity, @ui.ecs_key_button, button) |> ignore)
      }
    }
    if (try! world.contains_by_key(entity, @ui.ecs_key_background_color)) {
      try! (world.replace(
        entity,
        @ui.ecs_key_background_color,
        @ui.BackgroundColor::new(bg_color),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        entity,
        @ui.ecs_key_background_color,
        @ui.BackgroundColor::new(bg_color),
      )
    }
    if (try! world.contains_by_key(entity, @ui.ecs_key_border_color)) {
      try! (world.replace(
        entity,
        @ui.ecs_key_border_color,
        @ui.BorderColor::new(border_color),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        entity,
        @ui.ecs_key_border_color,
        @ui.BorderColor::new(border_color),
      )
    }
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      if children.entities.length() > 0 {
        let label_entity = children.entities[0]
        if (try! world.get_by_key(label_entity, @text.ecs_key_text))
          is Some(text_value) {
          text_value.content = text.to_string()
          try! (world.replace(label_entity, @text.ecs_key_text, text_value)
          |> ignore)
        }
      }
    }
  })
  if a11y_state_ref is Some(state) {
    a11y_state_resource.insert(state.val)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)

  // UI camera.
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  // Root node.
  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
  )

  // Button node.
  let button = world.spawn_empty()
  try! world.set_by_key(
    button,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(150.0F))
    .with_height(@ui.Val::Px(65.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(150.0F))
    .with_height(@ui.Val::Px(65.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(150.0F))
    .with_height(@ui.Val::Px(65.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_radius,
    @ui.BorderRadius::all(@ui.Val::Percent(100.0F)),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(@sprite.Color::black()),
  )

  // Button label.
  let label = world.spawn_empty()
  try! world.set_by_key(
    label,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    label,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(label, @text.ecs_key_text, @text.Text::new("Button"))
  try! world.set_by_key(
    label,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(33.0F),
  )
  try! world.set_by_key(
    label,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::new(0.9F, 0.9F, 0.9F, 1.0F)),
  )
  try! world.set_by_key(
    label,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Center),
  )
}
