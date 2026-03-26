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
const TARGET_NAME : String = "AnimatedText"

///|
fn animated_ui_graph() -> (
  @asset.Handle[@animation.AnimationGraph],
  @animation.AnimationNodeIndex,
  @animation.AnimationTargetId,
) {
  let target = @animation.AnimationTargetId::from_name(TARGET_NAME)
  let clip = @animation.AnimationClip::new()
    .add_scale_curve(target, [
      @animation.KeyframeVec3::new(0.0F, @math.Vec3::splat(0.3F)),
      @animation.KeyframeVec3::new(0.5F, @math.Vec3::splat(1.0F)),
      @animation.KeyframeVec3::new(1.0F, @math.Vec3::splat(0.3F)),
      @animation.KeyframeVec3::new(1.5F, @math.Vec3::splat(1.0F)),
      @animation.KeyframeVec3::new(2.0F, @math.Vec3::splat(0.3F)),
      @animation.KeyframeVec3::new(2.5F, @math.Vec3::splat(1.0F)),
      @animation.KeyframeVec3::new(3.0F, @math.Vec3::splat(0.3F)),
    ])
    .add_text_color_curve(target, [
      @animation.KeyframeColor::new(0.0F, @sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
      @animation.KeyframeColor::new(1.0F, @sprite.Color::srgb(0.0F, 1.0F, 0.0F)),
      @animation.KeyframeColor::new(2.0F, @sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
      @animation.KeyframeColor::new(3.0F, @sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
    ])
  let clip_handle = @animation.animation_clip_add(clip)
  let (graph, node) = @animation.AnimationGraph::from_clip(clip_handle)
  let graph_handle = @animation.animation_graph_add(graph)
  (graph_handle, node, target)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )

  let (graph_handle, node, target) = animated_ui_graph()
  let player = @animation.AnimationPlayer::default()
  player.play(node).repeat() |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      player,
      @animation.AnimationGraphHandle::new(graph_handle),
    ),
  )

  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ecs.Name::new(TARGET_NAME),
      @ui.Node::default(),
      @text.Text::new("Bevy"),
      @text.TextFont::default()
      .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(@text.FontSize::Px(80.0F)),
      @text.TextColor::new(@sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
      @text.TextLayout::new_with_justify(@text.Justify::Center),
      @transform.Transform::identity().with_scale(@math.Vec3::splat(0.3F)),
    ),
  )
  commands.entity(text_entity).insert_component(target)
  commands
  .entity(text_entity)
  .insert_component(@animation.AnimatedBy::new(root))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
