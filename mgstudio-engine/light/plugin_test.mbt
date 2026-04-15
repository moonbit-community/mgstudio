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

///|
test "light plugin: automatically adds default parallax correction to reflection probes" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    LightPlugin::default(),
  )
  let world = app.world()

  let auto_probe = world.spawn()
  try! world.set(auto_probe, EnvironmentMapLight::default())
  try! world.set(auto_probe, LightProbe::default())

  let custom_probe = world.spawn()
  try! world.set(custom_probe, EnvironmentMapLight::default())
  try! world.set(custom_probe, LightProbe::default())
  try! world.set(
    custom_probe,
    ParallaxCorrection::Custom(@math.Vec3::new(0.25, 0.5, 0.75)),
  )

  let non_probe = world.spawn()
  try! world.set(non_probe, LightProbe::default())

  app = app.update()

  let auto_inserted = match
    (try! app.world().get_by_key(auto_probe, ecs_key_parallax_correction)) {
    Some(ParallaxCorrection::Auto) => true
    _ => false
  }
  debug_inspect(auto_inserted, content="true")

  let custom_preserved = match
    (try! app.world().get_by_key(custom_probe, ecs_key_parallax_correction)) {
    Some(ParallaxCorrection::Custom(_)) => true
    _ => false
  }
  debug_inspect(custom_preserved, content="true")

  debug_inspect(
    try! (app.world().get_by_key(non_probe, ecs_key_parallax_correction) is None),
    content="true",
  )
}
