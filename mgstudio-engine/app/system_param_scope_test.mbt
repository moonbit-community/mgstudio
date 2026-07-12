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
struct ScopeProbeResource {
  value : Int
}

///|
let scope_probe_resource_key : @ecs.ResourceKey[ScopeProbeResource] = @ecs.register_resource(
  debug_name="tests.app.scope_probe_resource",
)

///|
pub impl Resource for ScopeProbeResource with fn resource() {
  scope_probe_resource_key
}

///|
test "app: escaped system parameters lose their World lease after invocation" {
  let escaped_commands : Ref[Commands?] = Ref(None)
  let escaped_query : Ref[@ecs.Query[@core.Entity, @ecs.All]?] = Ref(None)
  let escaped_resource : Ref[ResMut[ScopeProbeResource]?] = Ref(None)
  let world = @ecs.World::new()
  world.insert_resource(scope_probe_resource_key, { value: 1 })
  let mut app = App::new(world).add_system_param3(fn(
    commands : Commands,
    query : @ecs.Query[@core.Entity, @ecs.All],
    resource : ResMut[ScopeProbeResource],
  ) {
    ignore(resource.get().value)
    escaped_commands.val = Some(commands)
    escaped_query.val = Some(query)
    escaped_resource.val = Some(resource)
  })
  app = app.run_once()

  guard escaped_commands.val is Some(commands) else {
    abort("missing Commands")
  }
  guard escaped_query.val is Some(query) else { abort("missing Query") }
  guard escaped_resource.val is Some(resource) else { abort("missing ResMut") }
  debug_inspect(commands.is_active(), content="false")
  debug_inspect(query.is_active(), content="false")
  debug_inspect(resource.is_active(), content="false")
  debug_inspect(app.world().is_closed(), content="false")
}
