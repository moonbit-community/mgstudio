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
