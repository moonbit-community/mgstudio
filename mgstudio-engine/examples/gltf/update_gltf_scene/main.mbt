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
struct MovedScene {}

///|
let ecs_key_moved_scene : @ecs.ComponentKey[MovedScene] = @ecs.register_component(
  debug_name="examples.gltf.update_gltf_scene.MovedScene",
)

///|
pub impl @ecs.Component for MovedScene with component() {
  ecs_key_moved_scene
}

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

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
        @transform.Transform::from_xyz(4.0F, 25.0F, 8.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(-0.5F, 0.9F, 1.5F).looking_at(
          @math.Vec3::new(-0.5F, 0.3F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.EnvironmentMapLight::new(
          Some(server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
          Some(server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
          150.0F,
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(-1.0F, 0.0F, 0.0F),
        @scene.SceneRoot::new(
          server.load(
            @gltf.GltfAssetLabel::Scene(0).from_asset(FLIGHT_HELMET_SCENE_ASSET),
          ),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          server.load(
            @gltf.GltfAssetLabel::Scene(0).from_asset(FLIGHT_HELMET_SCENE_ASSET),
          ),
        ),
        MovedScene::{  },
      ),
    ),
  )
}

///|
fn visit_descendants(
  world : @ecs.World,
  entity : @core.Entity,
  f : (@core.Entity) -> Unit,
) -> Unit {
  match (try! world.get_by_key(entity, @hierarchy.ecs_key_children)) {
    Some(children) =>
      for child in children.entities() {
        f(child)
        visit_descendants(world, child, f)
      }
    None => ()
  }
}

///|
fn move_scene_entities(world : @ecs.World) -> Unit {
  ignore(world.advance_sequence())
  let elapsed = match
    (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time.elapsed_secs()
    None => return
  }
  let moved_scenes : @ecs.Query[@core.Entity, @ecs.With[MovedScene]] = @ecs.query_filtered(
    world,
    @ecs.With::new(MovedScene::component()),
  )
  try! moved_scenes.view(fn(_entity, moved_scene_entity) {
    let offset = Ref::new(0.0F)
    visit_descendants(world, moved_scene_entity, fn(descendant) {
      match (try! world.get_by_key(descendant, @transform.ecs_key_transform)) {
        Some(transform) => {
          let moved_transform = @transform.Transform::{
            ..transform,
            translation: @math.Vec3::new(
              offset.val * @math.sin(elapsed) / 20.0F,
              0.0F,
              @math.cos(elapsed) / 20.0F,
            ),
          }
          try! (world.replace(
            descendant, @transform.ecs_key_transform, moved_transform,
          )
          |> ignore)
          offset.val = offset.val + 0.5F
        }
        None => ()
      }
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(move_scene_entities))
  .run()
}
