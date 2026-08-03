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
// Relocated from `text/ecs_runtime_wbtest.mbt` with the extraction move
// (ISS-480 phase 2): the render-side visibility gate now lives here, while
// the ECS-bridge sync assertions stayed with `text`.
test "text2d render extraction gates on retained view visibility" {
  let world = @ecs.World::new()
  defer world.close()
  let handle = @sprite.text_spawn(
    @sprite.Text2dBundle::new(
      @sprite.Text2d::new("Visibility"),
      @text.TextFont::TextFont(),
      @transform.Transform::identity(),
    ),
  )
  @text.text_set_view_visible(handle, false)
  @text2d.text_render_system(world)
  debug_inspect(
    @text2d.text_diagnostic_render_visible_text_count(),
    content="0",
  )
  @text.text_set_view_visible(handle, true)
  @text2d.text_render_system(world)
  debug_inspect(
    @text2d.text_diagnostic_render_visible_text_count(),
    content="1",
  )
  @text.text_despawn(handle) |> ignore
}
