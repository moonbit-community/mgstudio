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
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="runtime_config",
  )

  debug_inspect(world.get_resource(res_config), content="None")

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  debug_inspect(world.get_resource(res_config), content="Some({ fps: 60 })")

  debug_inspect(
    world.update_resource(res_config, fn(config) {
      RuntimeConfig::{ fps: config.fps + 30 }
    }),
    content="true",
  )
  debug_inspect(world.get_resource(res_config), content="Some({ fps: 90 })")
}

///|
test "ecs resource: update missing returns false" {
  let world = World::new()
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="missing_runtime_config",
  )

  debug_inspect(
    world.update_resource(res_config, fn(config) {
      RuntimeConfig::{ fps: config.fps + 1 }
    }),
    content="false",
  )
}

///|
test "ecs resource: get_resource reads world storage" {
  let world = World::new()
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="ref_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  world.insert_resource(res_config, RuntimeConfig::{ fps: 75 })

  debug_inspect(world.get_resource(res_config), content="Some({ fps: 75 })")
}

///|
test "ecs resource: ResourceMut updates live world storage" {
  let world = World::new()
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="ref_mut_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  let config = world.get_resource_mut(res_config).unwrap()
  config.set(RuntimeConfig::{ fps: 90 })

  debug_inspect(world.get_resource(res_config), content="Some({ fps: 90 })")
}

///|
test "ecs resource: ResourceMut exposes detect changes metadata" {
  let world = World::new()
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="resource_mut_detect_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  world.increment_change_tick() |> ignore

  let first_ctx = @core.SystemTickContext::new()
  first_ctx.set(@core.SystemTicks::new(0, 1))
  world.set_tick_context(first_ctx)

  let first_config = world.get_resource_mut(res_config).unwrap()
  debug_inspect(first_config.is_added(), content="true")
  debug_inspect(first_config.is_changed(), content="true")
  debug_inspect(first_config.added(), content="1")
  debug_inspect(first_config.last_changed(), content="1")
  debug_inspect(first_config.changed_by() is None, content="true")

  world.increment_change_tick() |> ignore
  let second_ctx = @core.SystemTickContext::new()
  second_ctx.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(second_ctx)

  let second_config = world.get_resource_mut(res_config).unwrap()
  debug_inspect(second_config.is_added(), content="false")
  debug_inspect(second_config.is_changed(), content="false")

  second_config.set(RuntimeConfig::{ fps: 75 })
  debug_inspect(second_config.is_changed(), content="true")
  debug_inspect(second_config.last_changed(), content="2")
  second_config.set_changed()
  debug_inspect(second_config.last_changed(), content="2")
  debug_inspect(
    second_config.changed_by().unwrap().contains("resource_test.mbt"),
    content="true",
  )
  debug_inspect(world.get_resource(res_config), content="Some({ fps: 75 })")
}

///|
test "ecs resource: ResourceMut acquisition and peek do not mark changed" {
  let world = World::new()
  defer world.close()
  let res_config : ResourceKey[RuntimeConfig] = register_resource(
    debug_name="resource_mut_acquire_runtime_config",
  )

  world.insert_resource(res_config, RuntimeConfig::{ fps: 60 })
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore

  let read_ctx = @core.SystemTickContext::new()
  read_ctx.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(read_ctx)

  let config = world.get_resource_mut(res_config).unwrap()
  debug_inspect(config.peek(), content="{ fps: 60 }")
  debug_inspect(config.is_changed(), content="false")
  debug_inspect(config.changed_by() is None, content="true")
}
