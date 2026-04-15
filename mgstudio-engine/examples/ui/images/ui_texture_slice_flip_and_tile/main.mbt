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
fn float_from_int(value : Int) -> Float {
  Float::from_int(value)
}

///|
fn image_with_flip(
  image_node : @ui.ImageNode,
  flip_x : Bool,
  flip_y : Bool,
) -> @ui.ImageNode {
  let image_node = if flip_x { image_node.with_flip_x() } else { image_node }
  if flip_y {
    image_node.with_flip_y()
  } else {
    image_node
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.queue(fn(world : @ecs.World) {
    world.resource(@ui.ecs_key_ui_scale).insert(@ui.UiScale::new(2.0F))
  })
  let image = asset_server
    .get()
    .load_with_settings("textures/fantasy_ui_borders/numbered_slices.png", fn(
      settings,
    ) {
      settings.sampler = @asset.ImageSampler::nearest()
    })
  let slicer = @ui.TextureSlicer::new(@ui.BorderRect::square(16.0F))
    .with_center_scale_mode(@ui.SliceScaleMode::Tile(1.0F))
    .with_sides_scale_mode(@ui.SliceScaleMode::Tile(1.0F))

  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::{
        ..@ui.Node::default(),
        width: @ui.Val::Percent(100.0F),
        height: @ui.Val::Percent(100.0F),
        justify_content: @ui.JustifyContent::Center,
        align_content: @ui.AlignContent::Center,
        flex_wrap: @ui.FlexWrap::Wrap,
        column_gap: @ui.Val::Px(10.0F),
        row_gap: @ui.Val::Px(10.0F),
      },
    ),
  )

  let dimensions : Array[(Int, Int)] = [(3, 3), (4, 4), (5, 4), (4, 5), (5, 5)]
  let flips : Array[(Bool, Bool)] = [
    (false, false),
    (false, true),
    (true, false),
    (true, true),
  ]
  for dimension in dimensions {
    for flip in flips {
      let image_node = image_with_flip(
        @ui.ImageNode::new(image).with_mode(@ui.NodeImageMode::Sliced(slicer)),
        flip.0,
        flip.1,
      )
      ignore(
        commands.spawn(
          (
            @hierarchy.Parent::new(root),
            image_node,
            @ui.Node::default()
            .with_width(@ui.Val::Px(16.0F * float_from_int(dimension.0)))
            .with_height(@ui.Val::Px(16.0F * float_from_int(dimension.1))),
          ),
        ),
      )
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
