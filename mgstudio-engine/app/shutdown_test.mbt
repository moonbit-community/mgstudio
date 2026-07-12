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
test "app: shutdown closes owned Worlds while remove and replace transfer ownership" {
  let main_world = @ecs.World::new()
  let transferred_world = @ecs.World::new()
  let replacement_world = @ecs.World::new()
  let mut app = App::new(main_world).insert_sub_app(
    RenderApp,
    SubApp::new(transferred_world),
  )

  guard app.remove_sub_app(RenderApp) is Some(transferred) else {
    abort("expected removed SubApp")
  }
  debug_inspect(transferred.world().is_closed(), content="false")
  app = app.insert_sub_app(RenderApp, transferred)
  guard app.replace_sub_app(RenderApp, SubApp::new(replacement_world))
    is Some(replaced) else {
    abort("expected replaced SubApp")
  }
  debug_inspect(replaced.world().is_closed(), content="false")
  ignore(replaced.shutdown())

  app = app.shutdown()
  app = app.shutdown()
  debug_inspect(main_world.is_closed(), content="true")
  debug_inspect(transferred_world.is_closed(), content="true")
  debug_inspect(replacement_world.is_closed(), content="true")
}
