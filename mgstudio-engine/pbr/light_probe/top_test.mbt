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
test "pbr light probe: view probe container enforces max probe count" {
  let probes = RenderViewLightProbes::default()
  for i in 0..<16 {
    ignore(probes.push_texture(None))
    probes.push_probe(RenderLightProbe::default())
    i |> ignore
  }
  inspect(probes.texture_count(), content="8")
  inspect(probes.probe_count(), content="8")
}

///|
test "pbr light probe: plugin initializes plugin state and uniform resources" {
  let app = light_probe_plugin(@app.App::new(@ecs.World::new()))
  inspect(app.contains_resource(ecs_key_light_probe_plugin_state), content="true")
  inspect(app.contains_resource(ecs_key_light_probes_uniform), content="true")
}

///|
test "pbr light probe: resource and component keys round-trip through ecs APIs" {
  let world = @ecs.World::new()
  world.insert_resource(
    ecs_key_light_probe_plugin_state,
    LightProbePluginState::default(),
  )
  let state : LightProbePluginState? = try! world.get_resource(
    ecs_key_light_probe_plugin_state,
  )
  inspect(state is Some(_), content="true")

  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_render_view_light_probes,
    RenderViewLightProbes::default(),
  )
  |> ignore
  let probes = try! world.get_by_key(entity, ecs_key_render_view_light_probes)
  inspect(probes is Some(_), content="true")
}
