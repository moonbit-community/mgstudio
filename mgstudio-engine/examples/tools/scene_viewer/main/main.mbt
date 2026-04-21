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
const MAIN_SCENE_ASSET : String = "models/FlightHelmet/FlightHelmet.gltf"

///|
struct OrbitCamera {
  radius : Float
  height : Float
  speed : Float
}

///|
let orbit_camera_key : @ecs.ComponentKey[OrbitCamera] = @ecs.register_component(
  debug_name="examples.tools.scene_viewer.main.OrbitCamera",
)

///|
pub impl @ecs.Component for OrbitCamera with component() {
  orbit_camera_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.queue(fn(world : @ecs.World) {
    world.insert_resource(
      @pbr.ecs_key_global_ambient_light,
      @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 1800.0F),
    )
  })
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(4.0F, 2.8F, 6.0F).looking_at(
          @math.Vec3::new(0.0F, 0.8F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        OrbitCamera::{ radius: 6.0F, height: 2.8F, speed: 0.26F },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 9000.0F, true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 2.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        asset_server
        .get()
        .load(@gltf.GltfAssetLabel::Scene(0).from_asset(MAIN_SCENE_ASSET)),
      ),
    ),
  )
}

///|
fn orbit_camera(
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[
    (@ecs.Comp[OrbitCamera], @ecs.Mut[@transform.Transform]),
    @ecs.With[@pbr.Camera3d],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! cameras.for_each(fn(_entity, data) {
    let (orbit, transform) = data
    let angle = t * orbit.value().speed
    let x = @math.cos(angle) * orbit.value().radius
    let z = @math.sin(angle) * orbit.value().radius
    transform.set(
      @transform.Transform::from_xyz(x, orbit.value().height, z).looking_at(
        @math.Vec3::new(0.0F, 0.8F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(orbit_camera)))
  .run()
}
