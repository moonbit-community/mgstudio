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
struct PluginGroupTestPlugin1 {}

///|
struct PluginGroupTestPlugin1Override {}

///|
struct PluginGroupTestPlugin2 {}

///|
struct PluginGroupTestPlugin3 {}

///|
struct PluginGroupTestPlugin4 {}

///|
struct MissingPluginTest {}

///|
struct PluginLifecycleTestPlugin {}

///|
struct NestedParentPlugin {}

///|
struct NestedChildPlugin {}

///|
struct PluginBuildDepthProbePlugin {}

///|
struct FinishAddsPluginPlugin {}

///|
struct PluginAddedProbePlugin {}

///|
struct PluginReadyCountPlugin {}

///|
struct FinishAddsDeferredFinishPlugin {}

///|
struct DeferredFinishProbePlugin {}

///|
let plugin_group_test_log_ref : Ref[Array[Int]] = Ref::new([])

///|
let plugin_lifecycle_log_ref : Ref[Array[Int]] = Ref::new([])

///|
let nested_plugin_lifecycle_log_ref : Ref[Array[Int]] = Ref::new([])

///|
let plugin_lifecycle_ready_ref : Ref[Bool] = Ref::new(true)

///|
let plugin_build_depth_probe_ref : Ref[Bool] = Ref::new(false)

///|
let plugin_added_probe_finish_ref : Ref[Bool] = Ref::new(false)

///|
let plugin_added_probe_cleanup_ref : Ref[Bool] = Ref::new(false)

///|
let plugin_ready_count_ref : Ref[Int] = Ref::new(0)

///|
let deferred_finish_probe_log_ref : Ref[Array[Int]] = Ref::new([])

///|
fn plugin_group_test_reset_log() -> Unit {
  plugin_group_test_log_ref.val = []
}

///|
fn plugin_lifecycle_test_reset_log() -> Unit {
  plugin_lifecycle_log_ref.val = []
  nested_plugin_lifecycle_log_ref.val = []
  plugin_lifecycle_ready_ref.val = true
  plugin_build_depth_probe_ref.val = false
  plugin_added_probe_finish_ref.val = false
  plugin_added_probe_cleanup_ref.val = false
  plugin_ready_count_ref.val = 0
  deferred_finish_probe_log_ref.val = []
}

///|
fn plugin_group_test_plugin_1(app : App[@ecs.World]) -> App[@ecs.World] {
  app.add_system(fn(_world : @ecs.World) {
    plugin_group_test_log_ref.val.push(1)
  })
}

///|
fn plugin_group_test_plugin_1_override(
  app : App[@ecs.World],
) -> App[@ecs.World] {
  app.add_system(fn(_world : @ecs.World) {
    plugin_group_test_log_ref.val.push(10)
  })
}

///|
fn plugin_group_test_plugin_2(app : App[@ecs.World]) -> App[@ecs.World] {
  app.add_system(fn(_world : @ecs.World) {
    plugin_group_test_log_ref.val.push(2)
  })
}

///|
pub impl Plugin for PluginGroupTestPlugin1 with name(_self) {
  "mgstudio.app.test_plugin_1"
}

///|
pub impl Plugin for PluginGroupTestPlugin1 with build(_self, app) {
  plugin_group_test_plugin_1(app)
}

///|
pub impl Plugin for PluginGroupTestPlugin1Override with name(_self) {
  "mgstudio.app.test_plugin_1"
}

///|
pub impl Plugin for PluginGroupTestPlugin1Override with build(_self, app) {
  plugin_group_test_plugin_1_override(app)
}

///|
pub impl Plugin for PluginGroupTestPlugin2 with name(_self) {
  "mgstudio.app.test_plugin_2"
}

///|
pub impl Plugin for PluginGroupTestPlugin2 with build(_self, app) {
  plugin_group_test_plugin_2(app)
}

///|
pub impl Plugin for PluginGroupTestPlugin3 with name(_self) {
  "mgstudio.app.test_plugin_3"
}

///|
pub impl Plugin for PluginGroupTestPlugin3 with build(_self, app) {
  app.add_system(fn(_world : @ecs.World) {
    plugin_group_test_log_ref.val.push(3)
  })
}

///|
pub impl Plugin for PluginGroupTestPlugin4 with name(_self) {
  "mgstudio.app.test_plugin_4"
}

///|
pub impl Plugin for PluginGroupTestPlugin4 with build(_self, app) {
  app.add_system(fn(_world : @ecs.World) {
    plugin_group_test_log_ref.val.push(4)
  })
}

///|
fn missing_plugin_test(app : App[@ecs.World]) -> App[@ecs.World] {
  app
}

///|
pub impl Plugin for MissingPluginTest with name(_self) {
  "mgstudio.app.missing_plugin_test"
}

///|
pub impl Plugin for MissingPluginTest with build(_self, app) {
  missing_plugin_test(app)
}

///|
fn plugin_lifecycle_test_plugin(app : App[@ecs.World]) -> App[@ecs.World] {
  plugin_lifecycle_log_ref.val.push(1)
  app
}

///|
pub impl Plugin for PluginLifecycleTestPlugin with name(_self) {
  "mgstudio.app.plugin_lifecycle_test"
}

///|
pub impl Plugin for PluginLifecycleTestPlugin with build(_self, app) {
  plugin_lifecycle_test_plugin(app)
}

///|
pub impl Plugin for PluginLifecycleTestPlugin with ready(_self, _app) {
  plugin_lifecycle_ready_ref.val
}

///|
pub impl Plugin for PluginLifecycleTestPlugin with finish(_self, app) {
  plugin_lifecycle_log_ref.val.push(2)
  app
}

///|
pub impl Plugin for PluginLifecycleTestPlugin with cleanup(_self, app) {
  plugin_lifecycle_log_ref.val.push(3)
  app
}

///|
pub impl Plugin for NestedParentPlugin with name(_self) {
  "mgstudio.app.nested_parent_plugin"
}

///|
pub impl Plugin for NestedParentPlugin with build(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(1)
  app.add_plugins(NestedChildPlugin::{  })
}

///|
pub impl Plugin for NestedParentPlugin with finish(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(10)
  app
}

///|
pub impl Plugin for NestedParentPlugin with cleanup(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(100)
  app
}

///|
pub impl Plugin for NestedChildPlugin with name(_self) {
  "mgstudio.app.nested_child_plugin"
}

///|
pub impl Plugin for NestedChildPlugin with build(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(2)
  app
}

///|
pub impl Plugin for NestedChildPlugin with finish(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(20)
  app
}

///|
pub impl Plugin for NestedChildPlugin with cleanup(_self, app) {
  nested_plugin_lifecycle_log_ref.val.push(200)
  app
}

///|
pub impl Plugin for PluginBuildDepthProbePlugin with name(_self) {
  "mgstudio.app.plugin_build_depth_probe"
}

///|
pub impl Plugin for PluginBuildDepthProbePlugin with build(_self, app) {
  plugin_build_depth_probe_ref.val = app.is_building_plugins()
  app
}

///|
pub impl Plugin for FinishAddsPluginPlugin with name(_self) {
  "mgstudio.app.finish_adds_plugin"
}

///|
pub impl Plugin for FinishAddsPluginPlugin with build(_self, app) {
  app
}

///|
pub impl Plugin for FinishAddsPluginPlugin with finish(_self, app) {
  app.add_plugins(PluginGroupTestPlugin2::{  })
}

///|
pub impl Plugin for PluginAddedProbePlugin with name(_self) {
  "mgstudio.app.plugin_added_probe"
}

///|
pub impl Plugin for PluginAddedProbePlugin with build(_self, app) {
  app
}

///|
pub impl Plugin for PluginAddedProbePlugin with finish(_self, app) {
  plugin_added_probe_finish_ref.val = app.is_plugin_added(PluginGroupTestPlugin1::{

  })
  app
}

///|
pub impl Plugin for PluginAddedProbePlugin with cleanup(_self, app) {
  plugin_added_probe_cleanup_ref.val = app.is_plugin_added(PluginGroupTestPlugin1::{

  })
  app
}

///|
pub impl Plugin for PluginReadyCountPlugin with name(_self) {
  "mgstudio.app.plugin_ready_count"
}

///|
pub impl Plugin for PluginReadyCountPlugin with build(_self, app) {
  app
}

///|
pub impl Plugin for PluginReadyCountPlugin with ready(_self, _app) {
  plugin_ready_count_ref.val = plugin_ready_count_ref.val + 1
  true
}

///|
pub impl Plugin for FinishAddsDeferredFinishPlugin with name(_self) {
  "mgstudio.app.finish_adds_deferred_finish"
}

///|
pub impl Plugin for FinishAddsDeferredFinishPlugin with build(_self, app) {
  app
}

///|
pub impl Plugin for FinishAddsDeferredFinishPlugin with finish(_self, app) {
  deferred_finish_probe_log_ref.val.push(1)
  app.add_plugins(DeferredFinishProbePlugin::{  })
}

///|
pub impl Plugin for DeferredFinishProbePlugin with name(_self) {
  "mgstudio.app.deferred_finish_probe"
}

///|
pub impl Plugin for DeferredFinishProbePlugin with build(_self, app) {
  deferred_finish_probe_log_ref.val.push(2)
  app
}

///|
pub impl Plugin for DeferredFinishProbePlugin with finish(_self, app) {
  deferred_finish_probe_log_ref.val.push(3)
  app
}

///|
test "app: run_if skips system execution" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push(1) }).run_if(fn(
      _world : @ecs.World,
    ) {
      false
    }),
  )
  app.run_once() |> ignore
  debug_inspect(log.length(), content="0")
}

///|
test "app: run_if evaluates with condition system sequence" {
  let observed : Array[(Int, Int)] = []
  let system_ran = Ref::new(false)
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { system_ran.val = true }).run_if(fn(
      _world : @ecs.World,
    ) {
      let sequence = current_system_sequence()
      observed.push((sequence.last_run, sequence.this_run))
      false
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(observed.length(), content="2")
  debug_inspect(system_ran.val, content="false")
  debug_inspect(observed[0].0 == 0 && observed[0].1 == 3, content="true")
  debug_inspect(observed[1].0 == 3 && observed[1].1 == 6, content="true")
}

///|
test "app: repeated run_if composes without short-circuiting" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push("system") })
    .run_if(fn(_world : @ecs.World) {
      log.push("first")
      false
    })
    .run_if(fn(_world : @ecs.World) {
      log.push("second")
      true
    }),
  )

  app.run_once() |> ignore

  debug_inspect(log.join(","), content="\"first,second\"")
}

///|
test "app: repeated run_if_stateful keeps independent condition state" {
  let first_seen : Array[Int] = []
  let second_seen : Array[Int] = []
  let system_runs = Ref::new(0)
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { system_runs.val = system_runs.val + 1 })
    .run_if_stateful((0).to_json(), fn(_world : @ecs.World, state : Ref[Json]) {
      let value : Int = try! @json.from_json(state.val)
      first_seen.push(value)
      state.val = (value + 1).to_json()
      true
    })
    .run_if_stateful((100).to_json(), fn(
      _world : @ecs.World,
      state : Ref[Json],
    ) {
      let value : Int = try! @json.from_json(state.val)
      second_seen.push(value)
      state.val = (value + 10).to_json()
      true
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(system_runs.val, content="2")
  debug_inspect(first_seen[0] == 0 && first_seen[1] == 1, content="true")
  debug_inspect(second_seen[0] == 100 && second_seen[1] == 110, content="true")
}

///|
test "app: add_plugins registers grouped plugins" {
  plugin_group_test_reset_log()
  fn group() -> PluginGroupBuilder[@ecs.World] {
    PluginGroupBuilder::start()
    .add(PluginGroupTestPlugin3::{  })
    .add(PluginGroupTestPlugin4::{  })
  }
  let app = App::new(@ecs.World::new()).add_plugins(group())
  app.run_once() |> ignore
  debug_inspect(
    plugin_group_test_log_ref.val.length() == 2 &&
    plugin_group_test_log_ref.val[0] == 3 &&
    plugin_group_test_log_ref.val[1] == 4,
    content="true",
  )
}

///|
test "app: plugin group set_plugin and disable preserve configured plugins" {
  plugin_group_test_reset_log()
  let group = PluginGroupBuilder::start_named("TestPlugins")
    .add(PluginGroupTestPlugin1::{  })
    .add(PluginGroupTestPlugin2::{  })
  debug_inspect(group.contains(PluginGroupTestPlugin1::{  }), content="true")
  debug_inspect(group.enabled(PluginGroupTestPlugin2::{  }), content="true")

  let app = App::new(@ecs.World::new()).add_plugins(
    group
    .set(PluginGroupTestPlugin1Override::{  })
    .disable(PluginGroupTestPlugin2::{  }),
  )
  app.run_once() |> ignore

  debug_inspect(plugin_group_test_log_ref.val.length(), content="1")
  debug_inspect(plugin_group_test_log_ref.val[0], content="10")
}

///|
test "app: plugin group try_set_plugin raises when id is missing" {
  let missing_plugin_id = try {
    ignore(
      PluginGroupBuilder::start_named("TestPlugins").try_set(MissingPluginTest::{

      }),
    )
    "ok"
  } catch {
    MissingPlugin(id) => id
    DuplicatePlugin(id) => "duplicate:\{id}"
  }

  debug_inspect(
    missing_plugin_id,
    content="\"mgstudio.app.missing_plugin_test\"",
  )
}

///|
test "app: plugin group add reorders existing plugin like Bevy" {
  let group = PluginGroupBuilder::start_named("TestPlugins")
    .add(PluginGroupTestPlugin1::{  })
    .add(PluginGroupTestPlugin2::{  })
    .add(PluginGroupTestPlugin1Override::{  })
  let entries = group.build_entries()
  debug_inspect(entries.length(), content="2")
  debug_inspect(entries[0].id, content="\"mgstudio.app.test_plugin_2\"")
  debug_inspect(entries[1].id, content="\"mgstudio.app.test_plugin_1\"")
}

///|
test "app: plugin group add_before and add_after overwrite existing position" {
  let before_group = PluginGroupBuilder::start_named("TestPlugins")
    .add(PluginGroupTestPlugin1::{  })
    .add(PluginGroupTestPlugin2::{  })
    .add(PluginGroupTestPlugin3::{  })
    .add_before(PluginGroupTestPlugin2::{  }, PluginGroupTestPlugin3::{  })
  let before_entries = before_group.build_entries()
  debug_inspect(before_entries[0].id, content="\"mgstudio.app.test_plugin_1\"")
  debug_inspect(before_entries[1].id, content="\"mgstudio.app.test_plugin_3\"")
  debug_inspect(before_entries[2].id, content="\"mgstudio.app.test_plugin_2\"")

  let after_group = PluginGroupBuilder::start_named("TestPlugins")
    .add(PluginGroupTestPlugin1::{  })
    .add(PluginGroupTestPlugin2::{  })
    .add(PluginGroupTestPlugin3::{  })
    .add_after(PluginGroupTestPlugin1::{  }, PluginGroupTestPlugin3::{  })
  let after_entries = after_group.build_entries()
  debug_inspect(after_entries[0].id, content="\"mgstudio.app.test_plugin_1\"")
  debug_inspect(after_entries[1].id, content="\"mgstudio.app.test_plugin_3\"")
  debug_inspect(after_entries[2].id, content="\"mgstudio.app.test_plugin_2\"")
}

///|
test "app: plugin group try_add variants preserve Bevy errors" {
  let duplicate_id = try {
    ignore(
      PluginGroupBuilder::start_named("TestPlugins")
      .add(PluginGroupTestPlugin1::{  })
      .try_add(PluginGroupTestPlugin1Override::{  }),
    )
    "ok"
  } catch {
    DuplicatePlugin(id) => id
    MissingPlugin(id) => "missing:\{id}"
  }
  debug_inspect(duplicate_id, content="\"mgstudio.app.test_plugin_1\"")

  let missing_target_id = try {
    ignore(
      PluginGroupBuilder::start_named("TestPlugins")
      .add(PluginGroupTestPlugin1::{  })
      .try_add_before(MissingPluginTest::{  }, PluginGroupTestPlugin2::{  }),
    )
    "ok"
  } catch {
    DuplicatePlugin(id) => "duplicate:\{id}"
    MissingPlugin(id) => id
  }
  debug_inspect(
    missing_target_id,
    content="\"mgstudio.app.missing_plugin_test\"",
  )
}

///|
test "app: plugin group set preserves disabled state" {
  let group = PluginGroupBuilder::start_named("TestPlugins")
    .add(PluginGroupTestPlugin1::{  })
    .disable(PluginGroupTestPlugin1::{  })
    .set(PluginGroupTestPlugin1Override::{  })
  debug_inspect(group.enabled(PluginGroupTestPlugin1::{  }), content="false")
  debug_inspect(group.build_entries().length(), content="0")
}

///|
test "app: plugin group add_group deduplicates by final ordering" {
  let group_a = PluginGroupBuilder::start_named("GroupA")
    .add(PluginGroupTestPlugin1::{  })
    .add(PluginGroupTestPlugin3::{  })
  let group_b = PluginGroupBuilder::start_named("GroupB")
    .add(PluginGroupTestPlugin2::{  })
    .add(PluginGroupTestPlugin3::{  })
  let group = PluginGroupBuilder::start_named("Root")
    .add_group(group_a)
    .add_group(group_b)
  let entries = group.build_entries()
  debug_inspect(entries.length(), content="3")
  debug_inspect(entries[0].id, content="\"mgstudio.app.test_plugin_1\"")
  debug_inspect(entries[1].id, content="\"mgstudio.app.test_plugin_2\"")
  debug_inspect(entries[2].id, content="\"mgstudio.app.test_plugin_3\"")
}

///|
test "app: plugin lifecycle finish/cleanup run on first update, not add_plugin" {
  plugin_lifecycle_test_reset_log()
  let mut app = App::new(@ecs.World::new()).add_plugins(PluginLifecycleTestPlugin::{

  })
  debug_inspect(app.plugins_state() == Ready, content="true")
  debug_inspect(plugin_lifecycle_log_ref.val, content="[1]")
  app = app.run_once()
  debug_inspect(app.plugins_state() == Cleaned, content="true")
  debug_inspect(plugin_lifecycle_log_ref.val, content="[1, 2, 3]")
}

///|
test "app: schedules do not run before plugin ready lifecycle finalizes" {
  plugin_lifecycle_test_reset_log()
  plugin_lifecycle_ready_ref.val = false
  let run_log : Array[Int] = []
  let mut app = App::new(@ecs.World::new())
    .add_plugins(PluginLifecycleTestPlugin::{  })
    .add_system(fn(_world : @ecs.World) { run_log.push(1) })
  app = app.run_once()
  debug_inspect(run_log.length(), content="0")
  debug_inspect(app.plugins_state() == Adding, content="true")
  plugin_lifecycle_ready_ref.val = true
  app = app.run_once()
  debug_inspect(run_log.length(), content="1")
  debug_inspect(app.plugins_state() == Cleaned, content="true")
  debug_inspect(plugin_lifecycle_log_ref.val, content="[1, 2, 3]")
}

///|
test "app: explicit finish/cleanup follow bevy lifecycle ordering" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new()).add_plugins(PluginLifecycleTestPlugin::{

  })
  let app = app.finish()
  debug_inspect(app.plugins_state() == Finished, content="true")
  debug_inspect(plugin_lifecycle_log_ref.val, content="[1, 2]")
  let app = app.cleanup()
  debug_inspect(app.plugins_state() == Cleaned, content="true")
  debug_inspect(plugin_lifecycle_log_ref.val, content="[1, 2, 3]")
}

///|
test "app: nested plugin registry preserves parent before child lifecycle" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new()).add_plugins(NestedParentPlugin::{  })
  debug_inspect(nested_plugin_lifecycle_log_ref.val, content="[1, 2]")
  debug_inspect(app.plugin_names().length(), content="2")
  let app = app.finish()
  debug_inspect(nested_plugin_lifecycle_log_ref.val, content="[1, 2, 10, 20]")
  app.cleanup() |> ignore
  debug_inspect(
    nested_plugin_lifecycle_log_ref.val,
    content="[1, 2, 10, 20, 100, 200]",
  )
}

///|
test "app: plugin build depth is visible only during plugin build" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new()).add_plugins(PluginBuildDepthProbePlugin::{

  })
  debug_inspect(plugin_build_depth_probe_ref.val, content="true")
  debug_inspect(app.is_building_plugins(), content="false")
}

///|
test "app: plugin can add another plugin during finish" {
  let app = App::new(@ecs.World::new())
    .add_plugins(PluginGroupTestPlugin1::{  })
    .add_plugins(FinishAddsPluginPlugin::{  })
    .finish()
  debug_inspect(app.plugin_names().length(), content="3")
  debug_inspect(app.plugin_names()[0], content="\"mgstudio.app.test_plugin_1\"")
  debug_inspect(
    app.plugin_names()[1],
    content="\"mgstudio.app.finish_adds_plugin\"",
  )
  debug_inspect(app.plugin_names()[2], content="\"mgstudio.app.test_plugin_2\"")
  debug_inspect(app.plugins_state() == Finished, content="true")
}

///|
test "app: plugin added during finish is not finished in same pass" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new()).add_plugins(FinishAddsDeferredFinishPlugin::{

  })
  let app = app.finish()
  debug_inspect(app.plugin_names().length(), content="2")
  debug_inspect(deferred_finish_probe_log_ref.val, content="[1, 2]")
}

///|
test "app: is_plugin_added is available during finish and cleanup" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new())
    .add_plugins(PluginGroupTestPlugin1::{  })
    .add_plugins(PluginAddedProbePlugin::{  })
  debug_inspect(
    app.is_plugin_added(PluginGroupTestPlugin1::{  }),
    content="true",
  )
  debug_inspect(
    app.is_plugin_added(PluginGroupTestPlugin2::{  }),
    content="false",
  )

  let app = app.finish()
  debug_inspect(plugin_added_probe_finish_ref.val, content="true")
  app.cleanup() |> ignore
  debug_inspect(plugin_added_probe_cleanup_ref.val, content="true")
}

///|
test "app: plugins_state query does not transition out of adding" {
  plugin_lifecycle_test_reset_log()
  let app = App::new(@ecs.World::new()).add_plugins(PluginReadyCountPlugin::{  })
  debug_inspect(plugin_ready_count_ref.val, content="0")
  debug_inspect(app.plugins_state() == Ready, content="true")
  debug_inspect(app.plugins_state() == Ready, content="true")
  debug_inspect(plugin_ready_count_ref.val, content="2")
}

///|
test "app: schedule sets order and preserve insertion within a set" {
  let log : Array[Int] = []
  let set_a = system_set("A")
  let set_b = system_set("B")
  let app = App::new(@ecs.World::new())
  app
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(1) }).in_set(set_a),
  )
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(2) }).in_set(set_a),
  )
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(3) }).in_set(set_b),
  )
  .configure_sets(Update, set_a, before=[set_b])
  .run_once()
  |> ignore
  debug_inspect(
    log.length() == 3 && log[0] == 1 && log[1] == 2 && log[2] == 3,
    content="true",
  )
}

///|
test "app: system before and after are node dependencies, not whole-set dependencies" {
  let log : Array[String] = []
  let set_a = system_set("NodeDependency.A")
  let set_b = system_set("NodeDependency.B")
  let app = App::new(@ecs.World::new())
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("first") })
      .in_set(set_a)
      .before(set_b),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("second") })
      .in_set(set_a)
      .after(set_b),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("middle") }).in_set(set_b),
    )

  app.run_once() |> ignore

  debug_inspect(log.join(","), content="\"first,middle,second\"")
}

///|
test "app: parent set conditions apply to child set systems" {
  let log : Array[String] = []
  let child_set = system_set("Hierarchy.Child")
  let parent_set = system_set("Hierarchy.Parent")
  let app = App::new(@ecs.World::new())
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("child") }).in_set(child_set),
    )
    .configure_sets(Update, child_set, in_sets=[parent_set])
    .configure_sets(Update, parent_set, set_run_ifs=[
      fn(_world : @ecs.World) { false },
    ])

  app.run_once() |> ignore

  debug_inspect(log, content="[]")
}

///|
test "app: parent set ordering applies to child set systems" {
  let log : Array[String] = []
  let child_set = system_set("Hierarchy.Order.Child")
  let parent_set = system_set("Hierarchy.Order.Parent")
  let after_set = system_set("Hierarchy.Order.After")
  let app = App::new(@ecs.World::new())
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("after") }).in_set(after_set),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("child") }).in_set(child_set),
    )
    .configure_sets(Update, child_set, in_sets=[parent_set])
    .configure_sets(Update, parent_set, before=[after_set])

  app.run_once() |> ignore

  debug_inspect(log.join(","), content="\"child,after\"")
}

///|
test "app: cyclic set hierarchy reports validation error and skips stage execution" {
  let log : Array[Int] = []
  let kinds : Array[ErrorContextKind] = []
  let set_a = system_set("HierarchyCycle.A")
  let set_b = system_set("HierarchyCycle.B")
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push(1) }).in_set(set_a),
    )
    .configure_sets(Update, set_a, in_sets=[set_b])
    .configure_sets(Update, set_b, in_sets=[set_a])

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(log.length(), content="0")
  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Validation, content="true")
}

///|
test "app: cyclic set ordering reports validation error and skips stage execution" {
  let log : Array[Int] = []
  let kinds : Array[ErrorContextKind] = []
  let set_a = system_set("CycleA")
  let set_b = system_set("CycleB")
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push(1) }).in_set(set_a),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push(2) }).in_set(set_b),
    )
    .configure_sets(Update, set_a, before=[set_b])
    .configure_sets(Update, set_b, before=[set_a])
  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(log.length(), content="0")
  debug_inspect(kinds.length(), content="1")
  debug_inspect(kinds[0] == ErrorContextKind::Validation, content="true")
}

///|
test "app: chained tuple system configs run in declared order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_systems(
    Update,
    (
      system(fn(_world : @ecs.World) { log.push(1) }),
      system(fn(_world : @ecs.World) { log.push(2) }),
      system(fn(_world : @ecs.World) { log.push(3) }),
    )
    |> chain(),
  )
  app.run_once() |> ignore
  debug_inspect(log, content="[1, 2, 3]")
}

///|
test "app: chained tuple preserves per-system run_if evaluation" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new()).add_systems(
    Update,
    (
      system(fn(_world : @ecs.World) { log.push("first") }).run_if(fn(
        _world : @ecs.World,
      ) {
        false
      }),
      system(fn(_world : @ecs.World) { log.push("second") }).run_if(fn(
        _world : @ecs.World,
      ) {
        true
      }),
    )
    |> chain(),
  )
  app.run_once() |> ignore
  debug_inspect(log.join(","), content="\"second\"")
}

///|
test "app: chained tuple in_set preserves order and set boundaries" {
  let log : Array[String] = []
  let propagate_set = system_set("test.chain.propagate")
  let app = App::new(@ecs.World::new())
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("before") }).before(
        propagate_set,
      ),
    )
    .add_systems(
      Update,
      (
        system(fn(_world : @ecs.World) { log.push("mark") }),
        system(fn(_world : @ecs.World) { log.push("propagate") }),
        system(fn(_world : @ecs.World) { log.push("sync") }),
      )
      |> chain()
      |> SystemConfig::in_set(propagate_set),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { log.push("after") }).after(propagate_set),
    )
  app.run_once() |> ignore
  debug_inspect(log.join(","), content="\"before,mark,propagate,sync,after\"")
}

///|
test "app: chained tuple in_set applies set run conditions" {
  let log : Array[String] = []
  let gated_set = system_set("test.chain.gated")
  let app = App::new(@ecs.World::new())
    .add_systems(
      Update,
      (
        system(fn(_world : @ecs.World) { log.push("first") }),
        system(fn(_world : @ecs.World) { log.push("second") }),
      )
      |> chain()
      |> SystemConfig::in_set(gated_set),
    )
    .configure_sets(Update, gated_set, set_run_ifs=[
      fn(_world : @ecs.World) { false },
    ])
  app.run_once() |> ignore
  debug_inspect(log, content="[]")
}

///|
test "app: Last stage runs after PostUpdate" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_pre_update_system(fn(_world : @ecs.World) { log.push("pre") })
    .add_system(fn(_world : @ecs.World) { log.push("update") })
    .add_post_update_system(fn(_world : @ecs.World) { log.push("post") })
    .add_last_system(fn(_world : @ecs.World) { log.push("last") })
  app.run_once() |> ignore
  debug_inspect(log.join(","), content="\"pre,update,post,last\"")
}

///|
test "app: update runs startup once and update every frame" {
  let log : Array[String] = []
  let mut app = App::new(@ecs.World::new())
    .add_systems(
      PreStartup,
      system(fn(_world : @ecs.World) { log.push("pre_startup") }),
    )
    .add_systems(
      Startup,
      system(fn(_world : @ecs.World) { log.push("startup") }),
    )
    .add_systems(
      PostStartup,
      system(fn(_world : @ecs.World) { log.push("post_startup") }),
    )
    .add_systems(Update, system(fn(_world : @ecs.World) { log.push("update") }))

  app = app.update()
  app = app.update()

  debug_inspect(
    log.join(","),
    content="\"pre_startup,startup,post_startup,update,update\"",
  )
}

///|
struct Param1 {
  value : Int
}

///|
struct Param2 {
  value : Int
}

///|
struct Param3 {
  value : Int
}

///|
struct Param4 {
  value : Int
}

///|
struct Param5 {
  value : Int
}

///|
struct Param6 {
  value : Int
}

///|
impl SystemParam for Param1 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param1 with get(_state) {
  { value: 1 }
}

///|
impl SystemParam for Param1 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param2 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param2 with get(_state) {
  { value: 2 }
}

///|
impl SystemParam for Param2 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param3 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param3 with get(_state) {
  { value: 3 }
}

///|
impl SystemParam for Param3 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param4 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param4 with get(_state) {
  { value: 4 }
}

///|
impl SystemParam for Param4 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param5 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param5 with get(_state) {
  { value: 5 }
}

///|
impl SystemParam for Param5 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param6 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param6 with get(_state) {
  { value: 6 }
}

///|
impl SystemParam for Param6 with store(self, _state) {
  ignore(self)
}

///|
struct SequenceParam {
  sequence : @core.SystemSequence
}

///|
impl SystemParam for SequenceParam with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for SequenceParam with get(_state) {
  { sequence: current_system_sequence() }
}

///|
impl SystemParam for SequenceParam with store(self, _state) {
  ignore(self)
}

///|
struct TestMessage {
  value : Int
}

///|
let test_message_key : @ecs.MessageKey[TestMessage] = @ecs.register_message(
  debug_name="tests.app.TestMessage",
)

///|
impl @ecs.Message for TestMessage with message() {
  test_message_key
}

///|
test "app: add_system_param4 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_param4(fn(
    p1 : Param1,
    p2 : Param2,
    p3 : Param3,
    p4 : Param4,
  ) {
    log.push(p1.value)
    log.push(p2.value)
    log.push(p3.value)
    log.push(p4.value)
  })
  app.run_once() |> ignore
  debug_inspect(
    log.length() == 4 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4,
    content="true",
  )
}

///|
test "app: system_param5 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system(
    system_param5(fn(
      p1 : Param1,
      p2 : Param2,
      p3 : Param3,
      p4 : Param4,
      p5 : Param5,
    ) {
      log.push(p1.value)
      log.push(p2.value)
      log.push(p3.value)
      log.push(p4.value)
      log.push(p5.value)
    }),
  )
  app.run_once() |> ignore
  debug_inspect(
    log.length() == 5 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4 &&
    log[4] == 5,
    content="true",
  )
}

///|
test "app: system_param6 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system(
    system_param6(fn(
      p1 : Param1,
      p2 : Param2,
      p3 : Param3,
      p4 : Param4,
      p5 : Param5,
      p6 : Param6,
    ) {
      log.push(p1.value)
      log.push(p2.value)
      log.push(p3.value)
      log.push(p4.value)
      log.push(p5.value)
      log.push(p6.value)
    }),
  )
  app.run_once() |> ignore
  debug_inspect(
    log.length() == 6 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4 &&
    log[4] == 5 &&
    log[5] == 6,
    content="true",
  )
}

///|
test "app: system param can read current system sequence" {
  let log : Array[(Int, Int)] = []
  let app = App::new(@ecs.World::new())
  app
  .add_system_param(fn(param : SequenceParam) {
    log.push((param.sequence.last_run, param.sequence.this_run))
  })
  .add_system_param(fn(param : SequenceParam) {
    log.push((param.sequence.last_run, param.sequence.this_run))
  })
  .run_once()
  |> ignore
  debug_inspect(log.length(), content="2")
  debug_inspect(log[0].0 == 0 && log[0].1 == 3, content="true")
  debug_inspect(log[1].0 == 0 && log[1].1 == 4, content="true")
}

///|
test "app: MessageWriter system param writes messages for MessageReader" {
  let observed : Ref[Int] = Ref::new(-1)
  let app = App::new(@ecs.World::new())
    .add_message(test_message_key)
    .add_system_param(fn(writer : @ecs.MessageWriter[TestMessage]) {
      ignore(writer.write({ value: 42 }))
    })
    .add_system_param(fn(reader : @ecs.MessageReader[TestMessage]) {
      let messages = try! reader.read()
      if messages.length() > 0 {
        observed.val = messages[0].value
      }
    })
  app.run_once() |> ignore
  debug_inspect(observed.val, content="42")
}

///|
struct EcsPosition {
  mut x : Int
} derive(Eq, Debug)

///|
struct EcsVelocity {
  x : Int
} derive(Eq, Debug)

///|
let ecs_position_key : @ecs.ComponentKey[EcsPosition] = @ecs.register_component(
  debug_name="tests.app.ecs.position",
)

///|
let ecs_velocity_key : @ecs.ComponentKey[EcsVelocity] = @ecs.register_component(
  debug_name="tests.app.ecs.velocity",
)

///|
pub impl @ecs.Component for EcsPosition with component() {
  ecs_position_key
}

///|
pub impl @ecs.Component for EcsVelocity with component() {
  ecs_velocity_key
}

///|
test "app: SystemParam Query2 injects typed query into update system" {
  let world = @ecs.World::new()

  let app = App::new(world)
    .add_startup_system(fn(startup_world) {
      let entity = startup_world.spawn()
      try! startup_world.set_by_key(entity, ecs_position_key, EcsPosition::{
        x: 1,
      })
      try! startup_world.set_by_key(entity, ecs_velocity_key, EcsVelocity::{
        x: 41,
      })
    })
    .add_system_param(fn(
      query : @ecs.Query[
        (@ecs.Mut[EcsPosition], @ecs.Comp[EcsVelocity]),
        @ecs.All,
      ],
    ) {
      try! query.for_each(fn(_entity, data) {
        let (position, velocity) = data
        position.modify(fn(value) { value.x = value.x + velocity.value().x })
      })
    })
    .run_startup()
    .run_once()

  let query_world = app.world()
  let value_ref : Ref[Int] = Ref::new(0)
  let query : @ecs.Query[@ecs.Comp[EcsPosition], @ecs.All] = @ecs.query(
    query_world,
  )
  try! query.view(fn(_entity, position) { value_ref.val = position.value().x })
  debug_inspect(value_ref.val, content="42")
}

///|
test "app: schedule reports conflicting query params during execution validation" {
  let kinds : Array[ErrorContextKind] = []
  let ran = Ref::new(false)
  let app = App::new(@ecs.World::new())
    .set_error_handler(fn(_error, context) { kinds.push(context.kind()) })
    .add_system_param2(fn(
      _lhs : @ecs.Query[@ecs.Mut[EcsPosition], @ecs.All],
      _rhs : @ecs.Query[@ecs.Mut[EcsPosition], @ecs.All],
    ) {
      ran.val = true
    })

  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(ran.val, content="false")
  debug_inspect(kinds.length(), content="2")
  debug_inspect(
    kinds[0] == ErrorContextKind::Validation &&
    kinds[1] == ErrorContextKind::Validation,
    content="true",
  )
}
