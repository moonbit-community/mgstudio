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
fn all_glyphs() -> String {
  " !\\\"#$%&'()*\n+,-./012345\n6789:;<=>?@\nABCDEFGHIJK\nLMNOPQRSTUV\nWXYZ[\\\\]^_`a\nbcdefghijkl\nmnopqrstuvw\nxyz{|}~"
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
}

///|
fn draw_all_glyphs(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
) -> Unit {
  gizmos.text_2d(
    @gizmos.Isometry2d::identity(),
    all_glyphs(),
    40.0F,
    @math.Vec2::new(0.0F, 0.0F),
    @sprite.Color::white(),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_system_param(draw_all_glyphs)
  .run()
}
