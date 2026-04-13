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
test "pbr prepass: any_enabled reflects individual flags" {
  let bindings = render3d_prepass_bindings(true, false, false, false)
  inspect(bindings.any_enabled(), content="true")
  inspect(
    render3d_prepass_any_enabled(PrepassBindings3d::default()),
    content="false",
  )
}

///|
test "pbr prepass: pipeline plugin initializes pipeline state resource" {
  let app = prepass_pipeline_plugin(@app.App::new(@ecs.World::new()))
  inspect(app.contains_resource(ecs_key_prepass_pipeline_state), content="true")
}

///|
test "pbr prepass: plugin initializes marker and core prepass view state" {
  let app = prepass_plugin(@app.App::new(@ecs.World::new()))
  inspect(app.contains_resource(ecs_key_any_prepass_plugin_loaded), content="true")
  inspect(app.contains_resource(ecs_key_prepass_pipeline_state), content="true")
  inspect(app.contains_resource(ecs_key_prepass_view_state), content="true")
}

///|
test "pbr prepass: update pipeline state becomes ready when prepass components exist" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_prepass_view_state,
    PrepassViewState::default(),
  )
  world.insert_resource(
    ecs_key_prepass_pipeline_state,
    PrepassPipelineState::default(),
  )
  let entity = world.spawn()
  try! world.set_by_key(entity, ecs_key_depth_prepass, DepthPrepass::default())
  |> ignore

  prepass_update_pipeline_state(world)
  let state = (try! world.get_resource(ecs_key_prepass_pipeline_state)).unwrap()
  inspect(state.pipeline_ready, content="true")
}
