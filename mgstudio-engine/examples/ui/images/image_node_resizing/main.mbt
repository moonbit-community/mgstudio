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
const MIN_RESIZE_VAL : Float = 1.0F

///|
const IMAGE_GROUP_BOX_MIN_WIDTH : Float = 50.0F

///|
const IMAGE_GROUP_BOX_MAX_WIDTH : Float = 100.0F

///|
const IMAGE_GROUP_BOX_MIN_HEIGHT : Float = 10.0F

///|
const IMAGE_GROUP_BOX_MAX_HEIGHT : Float = 50.0F

///|
const IMAGE_GROUP_BOX_INIT_WIDTH : Float = 75.0F

///|
const IMAGE_GROUP_BOX_INIT_HEIGHT : Float = 30.0F

///|
const TEXT_PREFIX : String = "Compare NodeImageMode(Auto, Stretch). Use Arrow keys to resize the image groups.\n"

///|
struct ImageGroup {}

///|
struct ResizeLabel {}

///|
struct TextData {
  mut height : Float
  mut width : Float
}

///|
pub(all) enum ImageGroupResize {
  HeightGrow
  HeightShrink
  WidthGrow
  WidthShrink
}

///|
pub(all) enum ResizeAxis {
  Height
  Width
}

///|
struct TextUpdate {
  change : Float
  direction : ResizeAxis
  mut entity : @core.Entity
}

///|
let image_group_key : @ecs.ComponentKey[ImageGroup] = @ecs.register_component(
  debug_name="examples.ui.images.image_node_resizing.ImageGroup",
)

///|
let resize_label_key : @ecs.ComponentKey[ResizeLabel] = @ecs.register_component(
  debug_name="examples.ui.images.image_node_resizing.ResizeLabel",
)

///|
let text_data_key : @ecs.ComponentKey[TextData] = @ecs.register_component(
  debug_name="examples.ui.images.image_node_resizing.TextData",
)

///|
let image_group_resize_event_key : @ecs.EventKey[ImageGroupResize] = @ecs.register_event(
  debug_name="examples.ui.images.image_node_resizing.ImageGroupResize",
)

///|
let text_update_event_key : @ecs.EventKey[TextUpdate] = @ecs.register_event(
  debug_name="examples.ui.images.image_node_resizing.TextUpdate",
)

///|
pub impl @ecs.Component for ImageGroup with component() {
  image_group_key
}

///|
pub impl @ecs.Component for ResizeLabel with component() {
  resize_label_key
}

///|
pub impl @ecs.Component for TextData with component() {
  text_data_key
}

///|
pub impl @ecs.TriggerEvent for ImageGroupResize with observer_event() {
  image_group_resize_event_key
}

///|
pub impl @ecs.TriggerEvent for ImageGroupResize with observer_entity(_self) {
  None
}

///|
pub impl @ecs.TriggerEvent for ImageGroupResize with set_observer_entity(
  _event_ref,
  _entity,
) {

}

///|
pub impl @ecs.TriggerEvent for ImageGroupResize with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for ImageGroupResize with debug_name() {
  "ImageGroupResize"
}

///|
pub impl @ecs.TriggerEvent for TextUpdate with observer_event() {
  text_update_event_key
}

///|
pub impl @ecs.TriggerEvent for TextUpdate with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for TextUpdate with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for TextUpdate with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for TextUpdate with debug_name() {
  "TextUpdate"
}

///|
fn root_background() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 1.0F)
}

///|
fn group_background() -> @sprite.Color {
  @sprite.Color::srgb(0.86F, 0.92F, 0.99F)
}

///|
fn panel_background() -> @sprite.Color {
  @sprite.Color::srgb(0.08F, 0.08F, 0.08F)
}

///|
fn text_color() -> @sprite.Color {
  @sprite.Color::srgb(0.05F, 0.05F, 0.05F)
}

///|
fn resize_label_text(width : Float, height : Float) -> String {
  TEXT_PREFIX +
  "height: " +
  height.to_string() +
  "%, width: " +
  width.to_string() +
  "%"
}

///|
fn resize_group_node(
  node_ref : Ref[@ui.Node],
  event : ImageGroupResize,
) -> Unit {
  match event {
    HeightGrow =>
      match node_ref.val.height {
        Percent(value) =>
          node_ref.val = node_ref.val.with_height(
            @ui.Val::Percent(
              (value + MIN_RESIZE_VAL).min(IMAGE_GROUP_BOX_MAX_HEIGHT),
            ),
          )
        _ => ()
      }
    HeightShrink =>
      match node_ref.val.height {
        Percent(value) =>
          node_ref.val = node_ref.val.with_height(
            @ui.Val::Percent(
              (value - MIN_RESIZE_VAL).max(IMAGE_GROUP_BOX_MIN_HEIGHT),
            ),
          )
        _ => ()
      }
    WidthGrow =>
      match node_ref.val.width {
        Percent(value) =>
          node_ref.val = node_ref.val.with_width(
            @ui.Val::Percent(
              (value + MIN_RESIZE_VAL).min(IMAGE_GROUP_BOX_MAX_WIDTH),
            ),
          )
        _ => ()
      }
    WidthShrink =>
      match node_ref.val.width {
        Percent(value) =>
          node_ref.val = node_ref.val.with_width(
            @ui.Val::Percent(
              (value - MIN_RESIZE_VAL).max(IMAGE_GROUP_BOX_MIN_WIDTH),
            ),
          )
        _ => ()
      }
  }
}

///|
fn spawn_label(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let label = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      ResizeLabel::{  },
      TextData::{
        height: IMAGE_GROUP_BOX_INIT_HEIGHT,
        width: IMAGE_GROUP_BOX_INIT_WIDTH,
      },
      @text.Text::new(
        resize_label_text(
          IMAGE_GROUP_BOX_INIT_WIDTH,
          IMAGE_GROUP_BOX_INIT_HEIGHT,
        ),
      ),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(22.0F)),
      @text.TextColor::new(text_color()),
      @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(10.0F))),
    ),
  )
  ignore(commands.entity(label).observe2(update_text))
  label
}

///|
fn spawn_image_group(
  commands : @app.Commands,
  parent : @core.Entity,
  image : @asset.Handle[@image.Image],
  mode : @ui.NodeImageMode,
) -> @core.Entity {
  let group = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      ImageGroup::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Percent(IMAGE_GROUP_BOX_INIT_WIDTH))
      .with_height(@ui.Val::Percent(IMAGE_GROUP_BOX_INIT_HEIGHT))
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(group_background()),
    ),
  )
  match mode {
    Auto =>
      for _ in 0..<4 {
        ignore(
          commands.spawn(
            (
              @hierarchy.Parent::new(group),
              @ui.Node::default(),
              @ui.ImageNode::new(image).with_mode(@ui.NodeImageMode::Auto),
            ),
          ),
        )
      }
    Stretch => {
      let widths : Array[Float] = [10.0F, 20.0F, 30.0F, 40.0F]
      for width in widths {
        ignore(
          commands.spawn(
            (
              @hierarchy.Parent::new(group),
              @ui.Node::default()
              .with_width(@ui.Val::Percent(width))
              .with_height(@ui.Val::Percent(100.0F)),
              @ui.ImageNode::new(image).with_mode(@ui.NodeImageMode::Stretch),
            ),
          ),
        )
      }
    }
    _ => ()
  }
  group
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let icon = asset_server.get().load_image("branding/icon.png")
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_justify_content(@ui.JustifyContent::SpaceAround)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(root_background()),
    ),
  )

  ignore(spawn_label(commands, root, font))

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_justify_content(@ui.JustifyContent::SpaceAround)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BackgroundColor::new(panel_background()),
    ),
  )

  ignore(spawn_image_group(commands, panel, icon, @ui.NodeImageMode::Auto))
  ignore(spawn_image_group(commands, panel, icon, @ui.NodeImageMode::Stretch))
}

///|
fn update(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  labels : @ecs.Query[
    (@core.Entity, @ecs.Comp[TextData]),
    @ecs.With[ResizeLabel],
  ],
  commands : @app.Commands,
) -> Unit {
  guard (try? labels.single()) is Ok(Some((entity, _label_comp))) else {
    return
  }
  if keyboard_input.pressed(ArrowUp) {
    commands.trigger(ImageGroupResize::HeightGrow)
    commands.trigger(TextUpdate::{
      entity,
      direction: Height,
      change: MIN_RESIZE_VAL,
    })
  }
  if keyboard_input.pressed(ArrowDown) {
    commands.trigger(ImageGroupResize::HeightShrink)
    commands.trigger(TextUpdate::{
      entity,
      direction: Height,
      change: -MIN_RESIZE_VAL,
    })
  }
  if keyboard_input.pressed(ArrowLeft) {
    commands.trigger(ImageGroupResize::WidthShrink)
    commands.trigger(TextUpdate::{
      entity,
      direction: Width,
      change: -MIN_RESIZE_VAL,
    })
  }
  if keyboard_input.pressed(ArrowRight) {
    commands.trigger(ImageGroupResize::WidthGrow)
    commands.trigger(TextUpdate::{
      entity,
      direction: Width,
      change: MIN_RESIZE_VAL,
    })
  }
}

///|
fn update_text(
  event : @ecs.On[TextUpdate],
  label_query : @ecs.Query[(@ecs.Mut[TextData], @ecs.Mut[@text.Text]), @ecs.All],
) -> Unit raise {
  guard event.entity() is Some(entity) else { return }
  guard label_query.get(entity) is Some((text_data_mut, text_mut)) else {
    return
  }

  let text_data_ref = text_data_mut.get_ref()
  let text_ref = text_mut.get_ref()
  match event.event().direction {
    Height =>
      text_data_ref.val.height = (text_data_ref.val.height +
      event.event().change).clamp(
        min=IMAGE_GROUP_BOX_MIN_HEIGHT,
        max=IMAGE_GROUP_BOX_MAX_HEIGHT,
      )
    Width =>
      text_data_ref.val.width = (text_data_ref.val.width + event.event().change).clamp(
        min=IMAGE_GROUP_BOX_MIN_WIDTH,
        max=IMAGE_GROUP_BOX_MAX_WIDTH,
      )
  }

  text_ref.val.content = resize_label_text(
    text_data_ref.val.width,
    text_data_ref.val.height,
  )
}

///|
fn on_trigger_image_group(
  event : @ecs.On[ImageGroupResize],
  groups : @ecs.Query[@ecs.Mut[@ui.Node], @ecs.With[ImageGroup]],
) -> Unit {
  try! groups.view(fn(_entity, node_mut) {
    resize_group_node(node_mut.get_ref(), event.event())
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param2(setup)
  .add_system_param3(update)
  .add_observer2(on_trigger_image_group)
  .run()
}
