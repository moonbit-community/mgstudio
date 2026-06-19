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
// Bevy source: `bevy/examples/ui/widgets/vertical_slider.rs`.
struct ValueLabel {
  entity : @core.Entity
}

///|
struct DemoSlider {}

///|
struct DemoSliderThumb {}

///|
struct VerticalSlider {}

///|
let value_label_key : @ecs.ComponentKey[ValueLabel] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.ValueLabel",
)

///|
let demo_slider_key : @ecs.ComponentKey[DemoSlider] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.DemoSlider",
)

///|
let demo_slider_thumb_key : @ecs.ComponentKey[DemoSliderThumb] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.DemoSliderThumb",
)

///|
let vertical_slider_key : @ecs.ComponentKey[VerticalSlider] = @ecs.register_component(
  debug_name="examples.ui.widgets.vertical_slider.VerticalSlider",
)

///|
pub impl @ecs.Component for ValueLabel with fn component() {
  value_label_key
}

///|
pub impl @ecs.Component for DemoSlider with fn component() {
  demo_slider_key
}

///|
pub impl @ecs.Component for DemoSliderThumb with fn component() {
  demo_slider_thumb_key
}

///|
pub impl @ecs.Component for VerticalSlider with fn component() {
  vertical_slider_key
}

///|
fn slider_track_color() -> @color.Color {
  @color.Color::srgb(0.05F, 0.05F, 0.05F)
}

///|
fn slider_thumb_color() -> @color.Color {
  @color.Color::srgb(0.35F, 0.75F, 0.35F)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_column_gap(@ui.Val::Px(50.0F)),
      @input_focus.TabGroup::new(0),
    ),
  )
  spawn_vertical_slider_column(commands, root, font)
  spawn_horizontal_slider_column(commands, root, font)
}

///|
fn spawn_title(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  title : String,
) -> Unit {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.Text::new(title),
      @text.TextFont::TextFont().with_font(font).with_font_size(20.0F),
      @text.TextColor::new(@color.Color::srgb(0.9F, 0.9F, 0.9F)),
    ),
  )
  |> ignore
}

///|
fn spawn_value_label(
  commands : @app.Commands,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.Text::new("50"),
      @text.TextFont::TextFont().with_font(font).with_font_size(24.0F),
      @text.TextColor::new(@color.Color::srgb(0.9F, 0.9F, 0.9F)),
    ),
  )
}

///|
fn spawn_slider_column(
  commands : @app.Commands,
  root : @core.Entity,
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_row_gap(@ui.Val::Px(10.0F)),
    ),
  )
}

///|
fn spawn_vertical_slider_column(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let column = spawn_slider_column(commands, root)
  spawn_title(commands, column, font, "Vertical")
  let label = spawn_value_label(commands, column, font)
  let slider = spawn_vertical_slider(commands, column)
  commands.entity(slider).insert_component(ValueLabel::{ entity: label })
  ignore(commands.entity(slider).observe3(@ui_widgets.slider_self_update))
}

///|
fn spawn_horizontal_slider_column(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let column = spawn_slider_column(commands, root)
  spawn_title(commands, column, font, "Horizontal")
  let label = spawn_value_label(commands, column, font)
  let slider = spawn_horizontal_slider(commands, column)
  commands.entity(slider).insert_component(ValueLabel::{ entity: label })
  ignore(commands.entity(slider).observe3(@ui_widgets.slider_self_update))
}

///|
fn spawn_vertical_slider(
  commands : @app.Commands,
  parent : @core.Entity,
) -> @core.Entity {
  let slider = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Stretch)
      .with_column_gap(@ui.Val::Px(4.0F))
      .with_width(@ui.Val::Px(12.0F))
      .with_height(@ui.Val::Px(200.0F)),
      DemoSlider::{  },
      VerticalSlider::{  },
      @ui_widgets.Slider::Slider().with_track_click(
        @ui_widgets.TrackClick::Snap,
      ),
      @ui_widgets.SliderValue::new(50.0F),
      @ui_widgets.SliderRange::new(0.0F, 100.0F),
      @input_focus.TabIndex::new(0),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(slider),
      @ui.Node::Node()
      .with_width(@ui.Val::Px(6.0F))
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Px(3.0F))),
      @ui.BackgroundColor::new(slider_track_color()),
    ),
  )
  |> ignore
  let thumb_container = commands.spawn(
    (
      @hierarchy.Parent::new(slider),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Px(12.0F))
      .with_bottom(@ui.Val::Px(0.0F))
      .with_left(@ui.Val::Px(0.0F))
      .with_right(@ui.Val::Px(0.0F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(thumb_container),
      DemoSliderThumb::{  },
      @ui_widgets.SliderThumb::SliderThumb(),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_width(@ui.Val::Px(12.0F))
      .with_height(@ui.Val::Px(12.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_bottom(@ui.Val::Percent(0.0F))
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Percent(100.0F))),
      @ui.BackgroundColor::new(slider_thumb_color()),
    ),
  )
  |> ignore
  slider
}

///|
fn spawn_horizontal_slider(
  commands : @app.Commands,
  parent : @core.Entity,
) -> @core.Entity {
  let slider = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Stretch)
      .with_column_gap(@ui.Val::Px(4.0F))
      .with_height(@ui.Val::Px(12.0F))
      .with_width(@ui.Val::Px(200.0F)),
      DemoSlider::{  },
      @ui_widgets.Slider::Slider().with_track_click(
        @ui_widgets.TrackClick::Snap,
      ),
      @ui_widgets.SliderValue::new(50.0F),
      @ui_widgets.SliderRange::new(0.0F, 100.0F),
      @input_focus.TabIndex::new(0),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(slider),
      @ui.Node::Node()
      .with_height(@ui.Val::Px(6.0F))
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Px(3.0F))),
      @ui.BackgroundColor::new(slider_track_color()),
    ),
  )
  |> ignore
  let thumb_container = commands.spawn(
    (
      @hierarchy.Parent::new(slider),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_right(@ui.Val::Px(12.0F))
      .with_top(@ui.Val::Px(0.0F))
      .with_bottom(@ui.Val::Px(0.0F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(thumb_container),
      DemoSliderThumb::{  },
      @ui_widgets.SliderThumb::SliderThumb(),
      @ui.Node::Node()
      .with_display(@ui.Display::Flex)
      .with_width(@ui.Val::Px(12.0F))
      .with_height(@ui.Val::Px(12.0F))
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Percent(0.0F))
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Percent(100.0F))),
      @ui.BackgroundColor::new(slider_thumb_color()),
    ),
  )
  |> ignore
  slider
}

///|
fn visit_descendants(
  children_query : @ecs.Query[@ecs.Read[@hierarchy.Children], @ecs.All],
  entity : @core.Entity,
  visit : (@core.Entity) -> Unit,
) -> Unit {
  guard (children_query.get(entity) catch { _ => None }) is Some(children) else {
    return
  }
  for child in children.value().entities() {
    visit(child)
    visit_descendants(children_query, child, visit)
  }
}

///|
fn update_slider_visuals(
  sliders : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[@ui_widgets.SliderValue],
      @ecs.Read[@ui_widgets.SliderRange],
      @ecs.Read[@ui.Interaction]?,
      @ecs.Read[@ui_widgets.SliderDragState],
      @ecs.Has[VerticalSlider],
    ),
    @ecs.With[DemoSlider],
  ],
  children : @ecs.Query[@ecs.Read[@hierarchy.Children], @ecs.All],
  thumbs : @ecs.Query[
    (
      @ecs.Write[@ui.Node],
      @ecs.Write[@ui.BackgroundColor],
      @ecs.Has[DemoSliderThumb],
    ),
    @ecs.Without[DemoSlider],
  ],
) -> Unit {
  try! sliders.view(fn(_query_entity, data) {
    let (slider, value, range, interaction, drag_state, is_vertical) = data
    visit_descendants(children, slider, fn(child) {
      guard (thumbs.get(child) catch { _ => None })
        is Some((thumb_node, thumb_bg, is_thumb)) else {
        return
      }
      if !is_thumb.present() {
        return
      }
      let position = range.value().thumb_position(value.value().value()) *
        100.0F
      let node = thumb_node.peek()
      let next_node = if is_vertical.present() {
        node.with_bottom(@ui.Val::Percent(position))
      } else {
        node.with_left(@ui.Val::Percent(position))
      }
      thumb_node.set(next_node)
      let hovered_or_pressed = match interaction {
        Some(state) =>
          state.value() == @ui.Interaction::Hovered ||
          state.value() == @ui.Interaction::Pressed
        None => false
      }
      let active = hovered_or_pressed || drag_state.value().dragging()
      thumb_bg.set(
        @ui.BackgroundColor::new(
          if active {
            slider_thumb_color().lighter(0.3F)
          } else {
            slider_thumb_color()
          },
        ),
      )
    })
  })
}

///|
fn update_value_labels(
  sliders : @ecs.Query[
    (@ecs.Read[@ui_widgets.SliderValue], @ecs.Read[ValueLabel]),
    @ecs.With[DemoSlider],
  ],
  texts : @ecs.Query[@ecs.Write[@text.Text], @ecs.All],
) -> Unit {
  try! sliders.view(fn(_entity, data) {
    let (value, label) = data
    guard (texts.get(label.value().entity) catch { _ => None }) is Some(text) else {
      return
    }
    text.set(
      @text.Text::new(value.value().value().round().to_int().to_string()),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@input_focus.TabNavigationPlugin::TabNavigationPlugin())
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param2(@app.Update, update_value_labels)
  .add_systems_param3(@app.Update, update_slider_visuals)
  .run()
}
