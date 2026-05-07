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
test "fixed update: app does not run fixed loop without time plugin runner" {
  let counter : Ref[Int] = Ref(0)
  let app = App::new(@ecs.World::new()).add_fixed_update_system(fn(
    _world : @ecs.World,
  ) {
    counter.val = counter.val + 1
  })
  app.run_once() |> ignore
  debug_inspect(counter.val, content="0")
}
