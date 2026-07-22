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
test "bench visibility: reset view visibility" (b : @bench.T) {
  let world = @ecs.World::new()
  defer world.close()
  for _ in 0..<102_400 {
    let entity = world.spawn()
    try! world.set_by_key(
      entity,
      ecs_key_view_visibility,
      ViewVisibility::visible(),
    )
  }
  b.bench(name="reset ViewVisibility x102400", count=50U, () => {
    reset_view_visibility_system(world)
    b.keep(world.read_change_tick())
  })
}
