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
/// Port of `bevy/examples/ui/widgets/button.rs`.
fn normal_button_color() -> @render2d.Color {
  @render2d.Color::new(0.15F, 0.15F, 0.15F, 1.0F)
}

///|
fn hovered_button_color() -> @render2d.Color {
  @render2d.Color::new(0.25F, 0.25F, 0.25F, 1.0F)
}

///|
fn pressed_button_color() -> @render2d.Color {
  @render2d.Color::new(0.35F, 0.75F, 0.35F, 1.0F)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system_config(@app.system(button_system).after(@ui.ui_set_focus))
  .run()
}

///|
fn button_system(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  let system_ticks = world.get_system_context().ticks()
  let a11y_state_resource = @a11y.get_a11y_state_resource(world)
  let mut a11y_state_ref : Ref[@a11y.A11yState]? = None
  if a11y_state_resource.get() is Some(a11y_state) {
    a11y_state_ref = Some(Ref::new(a11y_state))
  }
  let button_store = world.component(@ui.ecs_key_button)
  let interaction_store = world.component(@ui.ecs_key_interaction)
  let background_store = world.component(@ui.ecs_key_background_color)
  let border_store = world.component(@ui.ecs_key_border_color)
  let children_store = world.component(@hierarchy.ecs_key_children)
  let ui_text_store = world.component(@ui.ecs_key_ui_text)
  interaction_store.for_each_changed(system_ticks, fn(entity, interaction) {
    if !button_store.contains(entity) {
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
      @ui.Interaction::Pressed => @render2d.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
      @ui.Interaction::Hovered => @render2d.Color::white()
      @ui.Interaction::None => @render2d.Color::black()
    }
    if interaction != @ui.Interaction::None {
      if button_store.get(entity) is Some(button) {
        button_store.set(entity, button, tick) |> ignore
      }
    }
    if background_store.contains(entity) {
      background_store.set(entity, @ui.BackgroundColor::new(bg_color), tick)
      |> ignore
    } else {
      background_store.insert(entity, @ui.BackgroundColor::new(bg_color), tick)
    }
    if border_store.contains(entity) {
      border_store.set(entity, @ui.BorderColor::new(border_color), tick)
      |> ignore
    } else {
      border_store.insert(entity, @ui.BorderColor::new(border_color), tick)
    }
    if children_store.get(entity) is Some(children) {
      if children.entities.length() > 0 {
        let label_entity = children.entities[0]
        if ui_text_store.get(label_entity) is Some(ui_text) {
          @text.text_set_content(ui_text.handle, text.to_string())
        }
      }
    }
  })
  if a11y_state_ref is Some(state) {
    a11y_state_resource.insert(state.val, tick)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()

  // UI camera.
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  // Root node.
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )

  // Button node.
  let button = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(button, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_button)
  .insert(button, @ui.Button::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    button,
    @ui.Node::default()
    .with_width(@ui.Val::Px(150.0F))
    .with_height(@ui.Val::Px(65.0F))
    .with_border(@ui.UiRect::all(@ui.Val::Px(5.0F)))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )
  world
  .component(@ui.ecs_key_border_radius)
  .insert(button, @ui.BorderRadius::all(@ui.Val::Percent(100.0F)), tick)
  world
  .component(@ui.ecs_key_border_color)
  .insert(button, @ui.BorderColor::new(@render2d.Color::white()), tick)
  world
  .component(@ui.ecs_key_background_color)
  .insert(button, @ui.BackgroundColor::new(@render2d.Color::black()), tick)

  // Button label.
  let label_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Button"),
      @text.TextFont::default().with_font(font).with_font_size(33.0F),
      @math.Transform::identity(),
    )
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.9F, 0.9F, 0.9F, 1.0F)),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
    .spawn()
  let label = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(label, @hierarchy.Parent::new(button), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    label,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(label, @ui.UiText::new(label_handle), tick)
}
