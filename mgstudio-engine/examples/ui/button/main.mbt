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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(ui_button_setup)
  .add_system(button_system)
  .run()
}

///| Bevy-aligned button update system (simplified).
fn button_system(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let button_store = @ui.Has_Button::get_button_store(world)
  let interaction_store = @ui.Has_Interaction::get_interaction_store(world)
  let bg_store = @ui.Has_BackgroundColor::get_background_color_store(world)
  let children_store = @hierarchy.Has_Children::get_children_store(world)
  let ui_text_store = @ui.Has_UiText::get_ui_text_store(world)

  let normal = @render2d.Color::new(0.15F, 0.15F, 0.15F, 1.0F)
  let hovered = @render2d.Color::new(0.25F, 0.25F, 0.25F, 1.0F)
  let pressed = @render2d.Color::new(0.35F, 0.75F, 0.35F, 1.0F)

  button_store.for_each(fn(entity, _btn) {
    let state = match interaction_store.get(entity) {
      Some(v) => v
      None => @ui.Interaction::None
    }
    let color = match state {
      @ui.Interaction::Pressed => pressed
      @ui.Interaction::Hovered => hovered
      @ui.Interaction::None => normal
    }
    let bg = @ui.BackgroundColor::new(color)
    if bg_store.contains(entity) {
      bg_store.set(entity, bg, tick) |> ignore
    } else {
      bg_store.insert(entity, bg, tick)
    }

    let label_text = match state {
      @ui.Interaction::Pressed => "Press"
      _ => "Button"
    }
    if children_store.get(entity) is Some(children) {
      for child in children.entities {
        if ui_text_store.get(child) is Some(text_node) {
          @text.text_set_content(text_node.handle, label_text.to_string())
        }
      }
    }
  })
}

///|
fn ui_button_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::increment_change_tick(world)

  // Camera.
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore

  // Root node (full-screen viewport space).
  let root = world.spawn_empty()
  @ui.Has_UiRoot::get_ui_root_store(world).insert(
    root,
    @ui.UiRoot::default(),
    tick,
  )
  // Bevy-like: center children in the root container.
  @ui.Has_Node::get_node_store(world).insert(
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
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    button,
    @hierarchy.Parent::new(root),
    tick,
  )
  @ui.Has_Button::get_button_store(world).insert(button, @ui.Button::default(), tick)
  @ui.Has_AccessibilityLabel::get_accessibility_label_store(world).insert(
    button,
    @ui.AccessibilityLabel::new("Button".to_string()),
    tick,
  )
  let button_node : @ui.Node = @ui.Node::default()
    .with_width(@ui.Val::Px(150.0F))
    .with_height(@ui.Val::Px(65.0F))
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
  @ui.Has_Node::get_node_store(world).insert(button, button_node, tick)
  let normal = @render2d.Color::new(0.15F, 0.15F, 0.15F, 1.0F)
  @ui.Has_BackgroundColor::get_background_color_store(world).insert(
    button,
    @ui.BackgroundColor::new(normal),
    tick,
  )

  // Label node (text handle is state-based, synced by UI systems).
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let font_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(33.0F)
  let label_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Button"),
      font_style,
      @math.Transform::identity(),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
    .spawn()
  let label = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    label,
    @hierarchy.Parent::new(button),
    tick,
  )
  let label_node : @ui.Node = @ui.Node::default()
    .with_width(@ui.Val::Auto)
    .with_height(@ui.Val::Auto)
  @ui.Has_Node::get_node_store(world).insert(label, label_node, tick)
  @ui.Has_ZIndex::get_z_index_store(world).insert(label, @ui.ZIndex::new(1), tick)
  @ui.Has_UiText::get_ui_text_store(world).insert(
    label,
    @ui.UiText::new(label_handle),
    tick,
  )
}
