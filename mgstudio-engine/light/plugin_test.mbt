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
test "light plugin: initializes default light resources" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(LightPlugin::default())
  debug_inspect(
    app.contains_resource(ecs_key_global_ambient_light),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_point_light_shadow_map),
    content="true",
  )
  debug_inspect(
    app.contains_resource(ecs_key_directional_light_shadow_map),
    content="true",
  )
}
