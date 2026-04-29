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
struct AnimatedMaterialNode {}

///|
let animated_material_node_key : @ecs.ComponentKey[AnimatedMaterialNode] = @ecs.register_component(
  debug_name="examples.ui.ui_material.AnimatedMaterialNode",
)

///|
pub impl @ecs.Component for AnimatedMaterialNode with component() {
  animated_material_node_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let image = asset_server.get().load_image("branding/banner.png")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.1F, 0.14F)),
    ),
  )

  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      AnimatedMaterialNode::{  },
      @ui.Node::default()
      .with_width(@ui.Val::Px(460.0F))
      .with_height(@ui.Val::Px(190.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(12.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_border_radius(@ui.BorderRadius::all(@ui.Val::Px(18.0F))),
      @ui.BorderColor::new(@sprite.Color::srgb(0.92F, 0.95F, 1.0F)),
      @ui.ImageNode::new(image).with_color(@sprite.Color::white()),
    ),
  )
  |> ignore
}

///|
fn animate_material_node(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (@ecs.Mut[@ui.ImageNode], @ecs.Mut[@ui.BorderColor]),
    @ecs.With[AnimatedMaterialNode],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! query.view(fn(_entity, data) {
    let (image_node, border_color) = data
    let tint = @sprite.Color::srgb(
      0.45F + 0.4F * @math.sin(elapsed * 0.7F),
      0.55F + 0.35F * @math.sin(elapsed * 1.1F + 1.2F),
      0.62F + 0.3F * @math.sin(elapsed * 1.5F + 2.0F),
    )
    let image = image_node.value().with_color(tint)
    image_node.set(image)
    border_color.set(
      @ui.BorderColor::new(
        @sprite.Color::srgb(
          0.7F + 0.2F * @math.sin(elapsed),
          0.75F + 0.2F * @math.sin(elapsed + 1.4F),
          0.95F,
        ),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_material_node)),
  )
  .run()
}
