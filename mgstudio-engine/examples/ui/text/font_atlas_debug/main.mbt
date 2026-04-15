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
const ATLAS_DEBUG_GLYPHS : String = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

///|
struct AtlasDebugState {
  mut atlas_count : Int
  mut next_glyph_index : Int
  mut timer : @time.Timer
  atlas_panel : @core.Entity?
}

///|
struct AtlasDebugText {}

///|
let atlas_debug_state_key : @ecs.ResourceKey[AtlasDebugState] = @ecs.register_resource(
  debug_name="examples.ui.text.font_atlas_debug.state",
)

///|
let atlas_debug_text_key : @ecs.ComponentKey[AtlasDebugText] = @ecs.register_component(
  debug_name="examples.ui.text.font_atlas_debug.text",
)

///|
pub impl @app.Resource for AtlasDebugState with resource() {
  atlas_debug_state_key
}

///|
pub impl @ecs.Component for AtlasDebugText with component() {
  atlas_debug_text_key
}

///|
fn yellow() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 0.0F)
}

///|
fn glyph_at(index : Int) -> String {
  let count = ATLAS_DEBUG_GLYPHS.length()
  let wrapped = if count == 0 { 0 } else { index % count }
  ATLAS_DEBUG_GLYPHS[wrapped:wrapped + 1].to_string()
}

///|
fn atlas_debug_state_default() -> AtlasDebugState {
  AtlasDebugState::{
    atlas_count: 0,
    next_glyph_index: 0,
    timer: @time.Timer::from_seconds(0.05F, @time.TimerMode::Repeating),
    atlas_panel: None,
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")

  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  let atlas_panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_top(@ui.Val::Px(0.0F))
      .with_height(@ui.Val::Px(512.0F)),
    ),
  )
  let text_panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_bottom(@ui.Val::Px(0.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(text_panel),
        @text.Text::new("a"),
        @text.TextFont::default()
        .with_font(font)
        .with_font_size(@text.FontSize::Px(50.0F)),
        @text.TextColor::new(yellow()),
        AtlasDebugText::{  },
      ),
    ),
  )
  commands.insert_resource(AtlasDebugState::{
    ..atlas_debug_state_default(),
    atlas_panel: Some(atlas_panel),
  })
}

///|
fn text_update_system(
  state : @app.ResMut[AtlasDebugState],
  time : @app.Res[@time.Time[@time.Real]],
  query : @app.Single[@ecs.Mut[@text.Text], @ecs.With[AtlasDebugText]],
) -> Unit {
  let state_ref = state.get_ref()
  state_ref.val.timer = state_ref.val.timer.tick(time.get().delta())
  if !state_ref.val.timer.just_finished() {
    return
  }
  let glyph = glyph_at(state_ref.val.next_glyph_index)
  state_ref.val.next_glyph_index = state_ref.val.next_glyph_index + 1
  let text = query.get()
  let current = text.value().content
  if !current.contains(glyph) {
    text.set(@text.Text::new(current + glyph))
  }
}

///|
fn atlas_render_system(
  commands : @app.Commands,
  state : @app.ResMut[AtlasDebugState],
  font_atlas_set : @app.Res[@text.FontAtlasSet],
  images : @app.Res[@asset.Assets[@image.Image]],
) -> Unit {
  let state_ref = state.get_ref()
  let panel = match state_ref.val.atlas_panel {
    Some(entity) => entity
    None => return
  }
  let entries = font_atlas_set.get().entries
  if entries.length() == 0 {
    return
  }
  let atlases = entries[0].atlases
  if state_ref.val.atlas_count >= atlases.length() {
    return
  }
  let atlas = atlases[state_ref.val.atlas_count]
  let image = match images.get().get(atlas.texture) {
    Some(image) => image
    None => return
  }
  let x_offset = Float::from_double(
    (image.width * state_ref.val.atlas_count).to_double(),
  )
  state_ref.val.atlas_count = state_ref.val.atlas_count + 1
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @ui.ImageNode::new(atlas.texture),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(0.0F))
        .with_left(@ui.Val::Px(x_offset)),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(text_update_system)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(atlas_render_system)),
  )
  .run()
}
