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
fn anchor_items() -> Array[(String, @math.Vec2, @sprite.Color)] {
  [
    (
      "left",
      @math.Vec2::new(-0.5F, 0.0F),
      @sprite.Color::srgb(1.0F, 0.0F, 0.0F),
    ),
    (
      "right",
      @math.Vec2::new(0.5F, 0.0F),
      @sprite.Color::srgb(1.0F, 0.5F, 0.0F),
    ),
    (
      "center",
      @math.Vec2::new(0.0F, 0.0F),
      @sprite.Color::srgb(1.0F, 0.9F, 0.1F),
    ),
    ("top", @math.Vec2::new(0.0F, 0.5F), @sprite.Color::srgb(0.0F, 1.0F, 0.0F)),
    (
      "bottom",
      @math.Vec2::new(0.0F, -0.5F),
      @sprite.Color::srgb(0.2F, 0.4F, 1.0F),
    ),
  ]
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
}

///|
fn anchors(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  for entry in anchor_items() {
    let (label, anchor, color) = entry
    let position = @math.Vec2::new(350.0F * anchor.x, 350.0F * anchor.y)
    gizmos.text_2d(
      @gizmos.Isometry2d::new(position, 0.0F),
      "+",
      12.0F,
      @math.Vec2::new(0.0F, 0.0F),
      @sprite.Color::white(),
    )
    gizmos.text_2d(
      @gizmos.Isometry2d::new(position, seconds),
      label,
      25.0F,
      anchor,
      color,
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_system_param2(anchors)
  .run()
}
