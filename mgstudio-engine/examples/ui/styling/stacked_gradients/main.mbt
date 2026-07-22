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
struct Layer {
  index : Int
}

///|
let layer_key : @ecs.ComponentKey[Layer] = @ecs.register_component(
  debug_name="examples.ui.styling.stacked_gradients.Layer",
)

///|
pub impl @ecs.Component for Layer with fn component() {
  layer_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.BackgroundColor::new(@color.Color::black()),
    ),
  )

  for i in 0..<5 {
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        Layer::{ index: i },
        @ui.Node::Node()
        .with_width(Percent(100.0F))
        .with_height(Percent(100.0F))
        .with_position_type(Absolute),
        @ui.BackgroundColor::new(
          match i {
            0 => @color.Color::new(0.9F, 0.1F, 0.1F, 0.25F)
            1 => @color.Color::new(0.1F, 0.2F, 0.9F, 0.25F)
            2 => @color.Color::new(0.95F, 0.85F, 0.1F, 0.2F)
            3 => @color.Color::new(0.1F, 0.75F, 0.6F, 0.2F)
            _ => @color.Color::new(0.9F, 0.9F, 0.9F, 0.1F)
          },
        ),
      ),
    )
    |> ignore
  }
}

///|
fn animate_layers(
  time : @app.Res[@time.Time[Unit]],
  layers : @ecs.Query[
    (@ecs.Read[Layer], @ecs.Write[@ui.BackgroundColor]),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! layers.view(fn(_entity, data) {
    let (layer, color) = data
    let f = Float::from_int(layer.value().index)
    color.set(
      @ui.BackgroundColor::new(
        @color.Color::new(
          0.5F + 0.4F * @math.sin(elapsed * 0.35F + f),
          0.5F + 0.4F * @math.sin(elapsed * 0.45F + f * 1.2F),
          0.5F + 0.4F * @math.sin(elapsed * 0.55F + f * 1.5F),
          0.08F + 0.18F / (f + 1.0F),
        ),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param(Startup, setup)
  .add_systems_param2(Update, animate_layers)
  .run()
}
