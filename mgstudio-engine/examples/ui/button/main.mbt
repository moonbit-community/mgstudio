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
  .add_startup_system(ui_scene_setup)
  .run()
}

///|
fn ui_scene_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let root = world.spawn_empty()
  @ui.Has_UiRoot::get_ui_root_store(world).insert(
    root,
    @ui.UiRoot::default(),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_row_gap(@ui.Val::Px(18.0F)),
    tick,
  )
  let panel = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel,
    @hierarchy.Parent::new(root),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    panel,
    @ui.Node::default()
    .with_width(@ui.Val::Px(420.0F))
    .with_height(@ui.Val::Px(190.0F))
    .with_overflow(
      @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
    )
    .with_padding(@ui.UiRect::all(@ui.Val::Px(10.0F))),
    tick,
  )
  @ui.Has_ScrollPosition::get_scroll_position_store(world).insert(
    panel,
    @ui.ScrollPosition::default(),
    tick,
  )
  let panel_content = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_content,
    @hierarchy.Parent::new(panel),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    panel_content,
    @ui.Node::default()
    .with_width(@ui.Val::Px(760.0F))
    .with_height(@ui.Val::Px(420.0F))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F))),
    tick,
  )
  let panel_text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Scrollable panel (clip + scissor test)\nUse wheel or screen reader scroll actions.\nLine 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8\nLine 9\nLine 10",
      ),
      @text.TextFont::default().with_font(font).with_font_size(18.0F),
      @math.Transform::identity(),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()
  let panel_text = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    panel_text,
    @hierarchy.Parent::new(panel_content),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    panel_text,
    @ui.Node::default()
    .with_width(@ui.Val::Px(720.0F))
    .with_height(@ui.Val::Auto),
    tick,
  )
  @ui.Has_UiText::get_ui_text_store(world).insert(
    panel_text,
    @ui.UiText::new(panel_text_handle),
    tick,
  )
  @ui.Has_Label::get_label_store(world).insert(
    panel_text,
    @ui.Label::default(),
    tick,
  )
  let editable_section = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable_section,
    @hierarchy.Parent::new(root),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    editable_section,
    @ui.Node::default()
    .with_width(@ui.Val::Px(420.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(8.0F)),
    tick,
  )
  let editable_title = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable_title,
    @hierarchy.Parent::new(editable_section),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    editable_title,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
    tick,
  )
  let editable_title_text = @text.Text2dBundle::new(
      @text.Text2d::new("Editable status"),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(24.0F)
      .with_font_smoothing(@text.FontSmoothing::None),
      @math.Transform::identity(),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()
  @ui.Has_UiText::get_ui_text_store(world).insert(
    editable_title,
    @ui.UiText::new(editable_title_text),
    tick,
  )
  @ui.Has_Label::get_label_store(world).insert(
    editable_title,
    @ui.Label::default(),
    tick,
  )
  let editable = world.spawn_empty()
  @hierarchy.Has_Parent::get_parent_store(world).insert(
    editable,
    @hierarchy.Parent::new(editable_section),
    tick,
  )
  @ui.Has_Node::get_node_store(world).insert(
    editable,
    @ui.Node::default()
    .with_width(@ui.Val::Px(420.0F))
    .with_height(@ui.Val::Px(48.0F))
    .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F))),
    tick,
  )
  @ui.Has_BackgroundColor::get_background_color_store(world).insert(
    editable,
    @ui.BackgroundColor::new(@render2d.Color::new(0.12F, 0.12F, 0.16F, 1.0F)),
    tick,
  )
  @ui.Has_AccessibilityLabel::get_accessibility_label_store(world).insert(
    editable,
    @ui.AccessibilityLabel::new("Status input".to_string()),
    tick,
  )
  let editable_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(24.0F),
      @math.Transform::identity(),
    )
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()
  @ui.Has_UiText::get_ui_text_store(world).insert(
    editable,
    @ui.UiText::new(editable_text),
    tick,
  )
  @ui.Has_Label::get_label_store(world).insert(
    editable,
    @ui.Label::default(),
    tick,
  )
}
