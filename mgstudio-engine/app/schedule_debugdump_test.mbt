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
test "app schedule graph dot includes filtered system order for stage" {
  let app = App::new(@ecs.World::new())
    .add_systems(
      PostUpdate,
      system(fn(_world : @ecs.World) { () }).named("tests.a"),
    )
    .add_systems(
      PostUpdate,
      system(fn(_world : @ecs.World) { () }).named("tests.b"),
    )
  let dot = app.schedule_graph_dot(PostUpdate)
  inspect(dot.contains("stage: PostUpdate"), content="true")
  inspect(dot.contains("\"tests.a\""), content="true")
  inspect(dot.contains("\"tests.b\""), content="true")
  inspect(dot.contains("\"tests.a\" -> \"tests.b\""), content="true")

  let filtered = app.schedule_graph_dot(
    PostUpdate,
    settings=ScheduleGraphSettings::default().with_include_system_name(fn(
      name : String,
    ) {
      name.contains("tests.b")
    }),
  )
  inspect(filtered.contains("\"tests.a\""), content="false")
  inspect(filtered.contains("\"tests.b\""), content="true")
}
