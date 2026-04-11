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
struct RuntimeConfig {
  fps : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct BrokenConfig {
  enabled : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
test "ecs resource: insert/get/update" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="runtime_config",
  )

  debug_inspect(try! world.get_resource(res_config), content="None")

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  debug_inspect(
    try! world.get_resource(res_config),
    content="Some({ fps: 60 })",
  )

  debug_inspect(
    try! world.update_resource(res_config, fn(config) {
      RuntimeConfig::{ fps: config.fps + 30 }
    }),
    content="true",
  )
  debug_inspect(
    try! world.get_resource(res_config),
    content="Some({ fps: 90 })",
  )
}

///|
test "ecs resource: update missing returns false" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="missing_runtime_config",
  )

  debug_inspect(
    try! world.update_resource(res_config, fn(config) {
      RuntimeConfig::{ fps: config.fps + 1 }
    }),
    content="false",
  )
}

///|
test "ecs resource: type mismatch diagnostics fail fast" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="decode_runtime_config",
  )
  let res_broken : ResourceKey[BrokenConfig] = res_config.cast()

  world.insert_resource(res_config, RuntimeConfig::{ fps: 144 })

  let result : Result[BrokenConfig?, EcsError] = try? world.get_resource(
    res_broken,
  )
  guard result is Err(ResourceTypeMismatch(key_id, _debug_name, _actual)) else {
    fail("expected resource type mismatch diagnostics")
  }
  debug_inspect(key_id == res_config.id(), content="true")
}

///|
test "ecs resource: get_resource_ref observes live world storage" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="ref_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  let config_ref = try! world.get_resource_ref(res_config).unwrap()
  config_ref.val = RuntimeConfig::{ fps: 75 }

  debug_inspect(
    try! world.get_resource(res_config),
    content="Some({ fps: 75 })",
  )
}

///|
test "ecs resource: get_resource_ref_mut observes live world storage" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="ref_mut_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  let config_ref = try! world.get_resource_ref_mut(res_config).unwrap()
  config_ref.val = RuntimeConfig::{ fps: 90 }

  debug_inspect(
    try! world.get_resource(res_config),
    content="Some({ fps: 90 })",
  )
}
