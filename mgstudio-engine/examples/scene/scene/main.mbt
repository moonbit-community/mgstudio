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
const FLIGHT_HELMET_SCENE_ASSET : String = "models/FlightHelmet/FlightHelmet.gltf"

///|
const SECOND_SCENE_ASSET : String = "models/GolfBall/GolfBall.glb"

///|
struct SceneSpin {
  speed : Float
}

///|
let scene_spin_key : @ecs.ComponentKey[SceneSpin] = @ecs.register_component(
  debug_name="examples.scene.scene.SceneSpin",
)

///|
pub impl @ecs.Component for SceneSpin with component() {
  scene_spin_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(16.0F, 12.0F, 16.0F).looking_at(
          @math.Vec3::new(0.0F, 0.8F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 12000.0F, true),
        @transform.Transform::from_xyz(14.0F, 20.0F, 8.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mgscene.SceneRoot::new(
          server.load(
            @gltf.GltfAssetLabel::Scene(0).from_asset(FLIGHT_HELMET_SCENE_ASSET),
          ),
        ),
        @transform.Transform::from_xyz(-5.0F, 0.0F, 0.0F),
        SceneSpin::{ speed: 0.18F },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mgscene.SceneRoot::new(
          server.load(
            @gltf.GltfAssetLabel::Scene(0).from_asset(SECOND_SCENE_ASSET),
          ),
        ),
        @transform.Transform::from_xyz(5.0F, 0.0F, 0.0F).with_scale(
          @math.Vec3::new(2.0F, 2.0F, 2.0F),
        ),
        SceneSpin::{ speed: -0.28F },
      ),
    ),
  )
}

///|
fn rotate_scene_roots(
  time : @app.Res[@time.Time[Unit]],
  roots : @ecs.Query[
    (@ecs.Comp[SceneSpin], @ecs.Mut[@transform.Transform]),
    @ecs.With[@mgscene.SceneRoot],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! roots.for_each(fn(_entity, data) {
    let (spin, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.rotation = @math.Quat::from_rotation_y(
      t * spin.value().speed,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_scene_roots)))
  .run()
}
