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
test "core2d: graph systems include Bevy prepass and early postprocess" {
  let log : Array[String] = []
  let core_2d_stage = @app.schedule_label(CORE_2D_SCHEDULE_NAME)
  let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
    Some(core_2d_stage),
  )
  let render_sub_app = core_2d_configure_render_sub_app(render_sub_app)
    .add_systems(
      core_2d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("prepass") }).in_set(
        core_2d_set_prepass,
      ),
    )
    .add_systems(
      core_2d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("main") }).in_set(
        core_2d_set_main_pass,
      ),
    )
    .add_systems(
      core_2d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("early_post") }).in_set(
        core_2d_set_early_post_process,
      ),
    )
    .add_systems(
      core_2d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("post") }).in_set(
        core_2d_set_post_process,
      ),
    )

  ignore(render_sub_app.update())

  debug_inspect(log.join(","), content="\"prepass,main,early_post,post\"")
}
