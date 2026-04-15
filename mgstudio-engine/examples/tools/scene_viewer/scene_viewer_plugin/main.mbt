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
struct ViewerScenes {
  handles : Array[@asset.Handle[@scene.Scene]]
  mut index : Int
}

///|
struct ViewerRoot {}

///|
let viewer_scenes_key : @ecs.ResourceKey[ViewerScenes] = @ecs.register_resource(
  debug_name="examples.tools.scene_viewer.scene_viewer_plugin.ViewerScenes",
)

///|
let viewer_root_key : @ecs.ComponentKey[ViewerRoot] = @ecs.register_component(
  debug_name="examples.tools.scene_viewer.scene_viewer_plugin.ViewerRoot",
)

///|
impl @app.Resource for ViewerScenes with resource() {
  viewer_scenes_key
}

///|
pub impl @ecs.Component for ViewerRoot with component() {
  viewer_root_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  let handles = [
    server.load(
      @gltf.GltfAssetLabel::Scene(0).from_asset(
        "models/FlightHelmet/FlightHelmet.gltf",
      ),
    ),
    server.load(
      @gltf.GltfAssetLabel::Scene(0).from_asset("models/GolfBall/GolfBall.glb"),
    ),
  ]
  commands.insert_resource(ViewerScenes::{ handles, index: 0 })
  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(4.0F, 2.4F, 6.0F).looking_at(
          @math.Vec3::new(0.0F, 0.8F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
        @transform.Transform::from_xyz(4.0F, 7.0F, 2.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
  ignore(commands.spawn((ViewerRoot::{  }, @scene.SceneRoot::new(handles[0]))))
}

///|
fn cycle_scene(
  keyboard : @input.ButtonInput[@window.KeyCode],
  scenes : @app.ResMut[ViewerScenes],
  roots : @ecs.Query[@ecs.Comp[ViewerRoot], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Enter) {
    return
  }
  let scenes_ref = scenes.get_ref()
  if scenes_ref.val.handles.length() == 0 {
    return
  }
  scenes_ref.val.index = (scenes_ref.val.index + 1) %
    scenes_ref.val.handles.length()
  let handle = scenes_ref.val.handles[scenes_ref.val.index]
  try! roots.for_each(fn(entity, _root) {
    commands.entity(entity).insert_component(@scene.SceneRoot::new(handle))
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(cycle_scene)))
  .run()
}
