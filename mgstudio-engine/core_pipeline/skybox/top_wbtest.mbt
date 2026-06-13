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
fn skybox_test_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn skybox_test_approx(a : Float, b : Float) -> Bool {
  skybox_test_abs(a - b) < 0.0001F
}

///|
test "skybox: render sub app configuration installs Bevy-shaped resources" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
    Some(@render.render_schedule_stage()),
  )
  let render_sub_app = configure_skybox_render_sub_app(render_sub_app)
  let world = render_sub_app.world()

  debug_inspect(
    world.resource(SkyboxPipelineState::resource()).is_present(),
    content="true",
  )
  debug_inspect(
    world.resource(ExtractedSkyboxes::resource()).is_present(),
    content="true",
  )
}

///|
test "skybox: uniforms match Bevy brightness and inverse-rotation transform" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(7)
  let skybox = @light.Skybox::new(image, 2.0F).with_rotation(
    @math.Quat::identity(),
  )
  let uniforms = SkyboxUniforms::from_skybox(skybox, 3.0F)

  debug_inspect(skybox_test_approx(uniforms.brightness, 6.0F), content="true")
  debug_inspect(uniforms.transform.length(), content="16")
  debug_inspect(
    skybox_test_approx(uniforms.transform[0], 1.0F) &&
    skybox_test_approx(uniforms.transform[5], 1.0F) &&
    skybox_test_approx(uniforms.transform[10], 1.0F) &&
    skybox_test_approx(uniforms.transform[15], 1.0F),
    content="true",
  )
}
