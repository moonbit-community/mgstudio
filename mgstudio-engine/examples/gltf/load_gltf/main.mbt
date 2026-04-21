// Copyright 2025 International Digital Economy Academy
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
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_4 : Float = 0.7853981633974483F

///|
const FLIGHT_HELMET_SCENE_ASSET : String = "models/FlightHelmet/FlightHelmet.gltf"

///|
const PISA_DIFFUSE_MAP_ASSET : String = "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"

///|
const PISA_SPECULAR_MAP_ASSET : String = "environment_maps/pisa_specular_rgb9e5_zstd.ktx2"

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  commands.queue(fn(world : @ecs.World) {
    world.insert_resource(
      @pbr.ecs_key_directional_light_shadow_map,
      @pbr.DirectionalLightShadowMap::new(4096),
    )
  })
  commands.spawn(
    (
      @camera.Camera3d::default(),
      @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
        @math.Vec3::new(0.0F, 0.3F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      @pbr.EnvironmentMapLight::new(
        Some(server.load(PISA_DIFFUSE_MAP_ASSET)),
        Some(server.load(PISA_SPECULAR_MAP_ASSET)),
        250.0F,
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true).with_cascade_shadow_config_builder(
        @pbr.CascadeShadowConfigBuilder::default()
        .with_num_cascades(1)
        .with_maximum_distance(1.6F),
      ),
      @transform.Transform::identity(),
    ),
  )
  |> ignore

  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        server.load(
          @gltf.GltfAssetLabel::Scene(0).from_asset(FLIGHT_HELMET_SCENE_ASSET),
        ),
      ),
    ),
  )
}

///|
fn animate_light_direction(
  time : @app.Res[@time.Time[Unit]],
  lights : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  try! lights.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = @math.Quat::from_euler(
        @math.EulerRot::ZYX,
        0.0F,
        elapsed * PI / 5.0F,
        -FRAC_PI_4,
      )
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(animate_light_direction)),
  )
  .run()
}
