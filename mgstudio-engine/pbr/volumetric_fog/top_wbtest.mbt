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
test "pbr volumetric fog: Bevy Core3d order is MainPass then volumetric_fog then EarlyPostProcess" {
  let log : Array[String] = []
  let graph_stage = @render.RenderGraph::schedule()
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let render_sub_app = @app.SubApp::new(lifecycle_world_15_0)
    .set_update_schedule(Some(graph_stage))
    .add_schedule(@render.RenderGraph::base_schedule())
  let fog_assets = FogAssets::new(@asset.Handle::new(1), @asset.Handle::new(2))
  let render_sub_app = volumetric_fog_configure_render_sub_app(
      render_sub_app, fog_assets,
    )
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("main") }).in_set(
        @core_pipeline.core3d_system_set_main_pass(),
      ),
    )
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("volumetric_fog") }).in_set(
        volumetric_fog_render_set_node,
      ),
    )
    .add_systems(
      graph_stage,
      @app.system(fn(_world : @ecs.World) { log.push("early_post") }).in_set(
        @core_pipeline.core3d_system_set_early_post_process(),
      ),
    )

  ignore(render_sub_app.update())

  debug_inspect(log.join(","), content="\"main,volumetric_fog,early_post\"")
}
