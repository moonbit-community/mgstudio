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
fn setup_camera(world : @ecs.World) -> Unit {
  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )
}

///|
fn configure_gizmos(
  config_store : @app.ResMut[@gizmos.GizmoConfigStore],
) -> Unit {
  let store_ref = config_store.get_ref()
  let (config, _group) = store_ref.val.config_mut(
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  config.val = { ..config.val, line: { ..config.val.line, width: 4.0F } }
}

///|
fn draw_text(
  gizmos : @gizmos.Gizmos[@gizmos.DefaultGizmoConfigGroup],
  time : @app.Res[@time.Time[@time.Virtual]],
) -> Unit {
  let seconds = time.get().elapsed_secs()
  let rotation = 0.2F * seconds
  gizmos.text_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(0.0F, 1.5F, 0.0F),
      @math.Quat::from_rotation_y(-rotation),
    ),
    "Hello",
    1.0F,
    @math.Vec2::zero(),
    @sprite.Color::srgb(0.9F, 0.2F, 0.2F),
  )
  gizmos.text_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Quat::from_rotation_y(rotation + 0.25F),
    ),
    "Text",
    1.0F,
    @math.Vec2::zero(),
    @sprite.Color::srgb(0.95F, 0.5F, 0.15F),
  )
  gizmos.text_3d(
    @math.Isometry3d::new(
      @math.Vec3::new(0.0F, -1.5F, 0.0F),
      @math.Quat::from_rotation_y(-rotation - 0.5F),
    ),
    "Gizmos",
    1.0F,
    @math.Vec2::zero(),
    @sprite.Color::srgb(0.95F, 0.85F, 0.25F),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup_camera))
  .add_systems(@app.Startup, @app.system(@app.system_param(configure_gizmos)))
  .add_system_param2(draw_text)
  .run()
}
