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
test "core pipeline: Core3dSystems includes Bevy early postprocess stage" {
  debug_inspect(Core3dSystems::EarlyPostProcess, content="EarlyPostProcess")
  debug_inspect(
    core3d_system_set_early_post_process() ==
    @app.system_set("mgstudio.core_pipeline.core3d.early_post_process"),
    content="true",
  )
}

///|
test "core pipeline: Core2dSystems includes Bevy prepass and early postprocess stages" {
  debug_inspect(Core2dSystems::Prepass, content="Prepass")
  debug_inspect(Core2dSystems::EarlyPostProcess, content="EarlyPostProcess")
  debug_inspect(
    core2d_system_set_prepass() ==
    @app.system_set("mgstudio.core_pipeline.core2d.prepass"),
    content="true",
  )
  debug_inspect(
    core2d_system_set_early_post_process() ==
    @app.system_set("mgstudio.core_pipeline.core2d.early_post_process"),
    content="true",
  )
}

///|
test "core pipeline: Core3d view schedule installs Bevy CurrentView per camera" {
  let seen : Array[@core.Entity] = []
  let view_a = @core.Entity::new(10, 1)
  let view_b = @core.Entity::new(20, 1)
  let graph_stage = @render.RenderGraph::schedule()
  let lifecycle_world_41_0 = @ecs.World::new()
  defer lifecycle_world_41_0.close()
  let sub_app = @app.SubApp::new(lifecycle_world_41_0)
    .set_update_schedule(Some(graph_stage))
    .add_schedule(@render.RenderGraph::base_schedule())
    .add_schedule(core3d_base_schedule())
    .add_systems(
      Core3d::schedule(),
      @app.system(fn(world : @ecs.World) {
        let current = world
          .get_resource(@render.current_view_resource_key)
          .unwrap()
        seen.push(current.entity())
      }),
    )
    .add_systems(
      graph_stage,
      @app.system(fn(world : @ecs.World) {
        run_core3d_view_schedule(world, view_a)
        run_core3d_view_schedule(world, view_b)
      }),
    )

  ignore(sub_app.update())

  debug_inspect(
    seen,
    content="[{ id: 10, generation: 1 }, { id: 20, generation: 1 }]",
  )
  debug_inspect(
    sub_app.world().get_resource(@render.current_view_resource_key) is None,
    content="true",
  )
}
