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
test "core3d: graph systems run main pass before early postprocess" {
  let log : Array[String] = []
  let core_3d_stage = @app.schedule_label("mgstudio.core_pipeline.core_3d")
  let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
    Some(core_3d_stage),
  )
  let render_sub_app = core_3d_configure_render_sub_app(render_sub_app)
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("prepass") }).in_set(
        core_3d_set_prepass,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("main") }).in_set(
        core_3d_set_main_pass,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("early_post") }).in_set(
        core_3d_set_early_post_process,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("post") }).in_set(
        core_3d_set_post_process,
      ),
    )

  ignore(render_sub_app.update())

  debug_inspect(log.join(","), content="\"prepass,main,early_post,post\"")
}

///|
test "core3d: main opaque pass skybox draw requires prepared skybox state" {
  let world = @ecs.World::new()
  let render_entity = @core.Entity::new(1, 1)

  debug_inspect(
    main_opaque_pass_3d_draw_skybox(world, render_entity),
    content="false",
  )
}
