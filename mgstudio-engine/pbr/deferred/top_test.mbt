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
test "pbr deferred: depth id clamps to byte range" {
  let depth = PbrDeferredLightingDepthId::new(999)
  inspect(depth.get(), content="255")
  depth.set(-1)
  inspect(depth.get(), content="0")
}

///|
test "pbr deferred: plugin inserts default depth id for deferred prepass entity" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    DeferredPbrLightingPlugin::default(),
  )
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @core_pipeline.ecs_key_deferred_prepass,
    @core_pipeline.DeferredPrepass::default(),
  )
  app = app.run_once()
  let depth = match
    (try! app.world().get_by_key(entity, ecs_key_pbr_deferred_lighting_depth_id)) {
    Some(v) => v
    None => abort("missing deferred depth id component")
  }
  inspect(depth.get(), content="1")
}

///|
test "pbr deferred: plugin keeps explicit depth id value" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    DeferredPbrLightingPlugin::default(),
  )
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @core_pipeline.ecs_key_deferred_prepass,
    @core_pipeline.DeferredPrepass::default(),
  )
  try! world.set_by_key(
    entity,
    ecs_key_pbr_deferred_lighting_depth_id,
    PbrDeferredLightingDepthId::new(7),
  )
  app = app.run_once()
  let depth = match
    (try! app.world().get_by_key(entity, ecs_key_pbr_deferred_lighting_depth_id)) {
    Some(v) => v
    None => abort("missing deferred depth id component")
  }
  inspect(depth.get(), content="7")
}
