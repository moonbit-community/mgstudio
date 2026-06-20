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
test "screenshot: RenderPlugin initializes pending capture state resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  debug_inspect(
    app
    .world()
    .resource(pending_screenshot_entity_captures_resource_key)
    .is_present(),
    content="true",
  )
}

///|
test "screenshot: pending capture state self-initializes as world resource" {
  let world = @ecs.World::new()
  debug_inspect(
    world.resource(pending_screenshot_entity_captures_resource_key).is_present(),
    content="false",
  )
  screenshot_finalize_capture_requests(world)
  debug_inspect(
    world.resource(pending_screenshot_entity_captures_resource_key).is_present(),
    content="true",
  )
}
