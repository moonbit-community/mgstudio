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
test "app: escaped Commands retains only the World allocator connection" {
  let escaped : Ref[Commands?] = Ref(None)
  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    commands : Commands,
  ) {
    escaped.val = Some(commands)
  })
  app = app.run_once()

  guard escaped.val is Some(commands) else {
    abort("expected Commands to escape the system invocation")
  }
  debug_inspect(commands.scope.is_active(), content="false")
  debug_inspect(app.world().is_closed(), content="false")
}
