// Copyright 2025 International Digital Economy Academy
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
test "app: current_world is only available during system execution" {
  debug_inspect(current_world() is None, content="true")

  let observed_world_id : Ref[Int] = Ref(-1)
  let observed_stage : Ref[String] = Ref("missing")
  let world = @ecs.World::new()
  let world_id = world.world_id()
  let app = App::new(world).add_system(fn(_world : @ecs.World) {
    observed_world_id.val = match current_world() {
      Some(active_world) => active_world.world_id()
      None => -2
    }
    observed_stage.val = match current_schedule_stage() {
      Some(Update) => "update"
      Some(_) => "other"
      None => "none"
    }
  })

  app.run_once() |> ignore

  debug_inspect(observed_world_id.val == world_id, content="true")
  debug_inspect(observed_stage.val, content="\"update\"")
  debug_inspect(current_world() is None, content="true")
}
