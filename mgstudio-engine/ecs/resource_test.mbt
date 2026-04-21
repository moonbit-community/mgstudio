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

///|
test "ecs resource: ResourceMut exposes detect changes metadata" {
  let world = World::new()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="resource_mut_detect_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  world.advance_sequence() |> ignore

  let first_ctx = @core.SystemSequenceContext::new()
  first_ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(first_ctx)

  let first_config = (try! world.get_resource_mut(res_config)).unwrap()
  debug_inspect(first_config.is_added(), content="true")
  debug_inspect(first_config.is_changed(), content="true")
  debug_inspect(first_config.added(), content="1")
  debug_inspect(first_config.last_changed(), content="1")
  debug_inspect(first_config.changed_by() is None, content="true")

  world.advance_sequence() |> ignore
  let second_ctx = @core.SystemSequenceContext::new()
  second_ctx.set(@core.SystemSequence::new(1, 2))
  world.set_sequence_context(second_ctx)

  let second_config = (try! world.get_resource_mut(res_config)).unwrap()
  debug_inspect(second_config.is_added(), content="false")
  debug_inspect(second_config.is_changed(), content="false")

  second_config.bypass_change_detection().val = RuntimeConfig::{ fps: 75 }
  debug_inspect(second_config.last_changed(), content="1")
  second_config.set_changed()
  debug_inspect(second_config.last_changed(), content="2")
  debug_inspect(
    second_config.changed_by().unwrap().contains("resource_test.mbt"),
    content="true",
  )
  debug_inspect(
    try! world.get_resource(res_config),
    content="Some({ fps: 75 })",
  )
}
