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
pub struct ScheduleBuildSettings {
  auto_insert_apply_deferred : Bool
} derive(Eq, Debug)

///|
pub fn ScheduleBuildSettings::new() -> ScheduleBuildSettings {
  { auto_insert_apply_deferred: true }
}

///|
pub fn ScheduleBuildSettings::auto_insert_apply_deferred(
  self : ScheduleBuildSettings,
) -> Bool {
  self.auto_insert_apply_deferred
}

///|
pub fn ScheduleBuildSettings::set_auto_insert_apply_deferred(
  self : ScheduleBuildSettings,
  auto_insert_apply_deferred : Bool,
) -> ScheduleBuildSettings {
  ignore(self)
  ScheduleBuildSettings::{ auto_insert_apply_deferred }
}

///|
pub struct Schedule {
  label : ScheduleStage
  mut executor_kind : ExecutorKind
  mut build_settings : ScheduleBuildSettings
  mut apply_final_deferred : Bool
}

///|
pub fn Schedule::new(label : ScheduleStage) -> Schedule {
  {
    label,
    executor_kind: MultiThreaded,
    build_settings: ScheduleBuildSettings::new(),
    apply_final_deferred: true,
  }
}

///|
pub fn Schedule::label(self : Schedule) -> ScheduleStage {
  self.label
}

///|
pub fn Schedule::get_executor_kind(self : Schedule) -> ExecutorKind {
  self.executor_kind
}

///|
pub fn Schedule::set_executor_kind(
  self : Schedule,
  executor_kind : ExecutorKind,
) -> Schedule {
  self.executor_kind = executor_kind
  self
}

///|
pub fn Schedule::get_build_settings(self : Schedule) -> ScheduleBuildSettings {
  self.build_settings
}

///|
pub fn Schedule::set_build_settings(
  self : Schedule,
  build_settings : ScheduleBuildSettings,
) -> Schedule {
  self.build_settings = build_settings
  self
}

///|
pub fn Schedule::get_apply_final_deferred(self : Schedule) -> Bool {
  self.apply_final_deferred
}

///|
pub fn Schedule::set_apply_final_deferred(
  self : Schedule,
  apply_final_deferred : Bool,
) -> Schedule {
  self.apply_final_deferred = apply_final_deferred
  self
}

///|
priv struct ScheduleGraphPlan {
  graph_generation : Int
  set_order : Array[SystemSet]
  dependency_edges : Array[(Int, Int, Bool)]
  groups : Array[SystemSet]
  system_layers : Array[Int]
  execution_order : Array[Int]
  build_error : String?
}

///|
priv struct ScheduleAccessPlan {
  graph_generation : Int
  world_id : Int
  component_registration_generation : Int
  allowed_ambiguous_fingerprint : Int
  auto_insert_apply_deferred : Bool
  system_accesses : Array[SystemAccess]
  runnable_execution_order : Array[Int]
  apply_after_execution_order : Array[Bool]
  invalid_system_errors : Array[(Int, String)]
  single_threaded_batches : Array[Array[Int]]
  multi_threaded_batches : Array[Array[Int]]
}

///|
priv struct ScheduleExecutionPlan[W] {
  systems : Array[SystemConfig[W]]
  execution_order : Array[Int]
  execution_batches : Array[Array[Int]]
  apply_after_execution_order : Array[Bool]
  apply_final_deferred : Bool
  set_run_conditions : @hashmap.HashMap[SystemSet, Ref[ScheduleSetRunConditions[W]]]
  invalid_system_errors : Array[(Int, String)]
  report_invalid_system_errors : Bool
  build_error : String?
  report_build_error : Bool
}

priv struct ScheduleSetRunConditions[W] {
  run_ifs : Array[StatefulRunConditionFn[W]]
  run_if_states : Array[Ref[Json]]
  run_if_last_run_sequences : Array[@core.Sequence]
}

///|
priv struct ScheduleEntry[W] {
  systems : Array[SystemConfig[W]]
  set_edges : Array[(SystemSet, SystemSet)]
  set_edges_ignore_deferred : Array[(SystemSet, SystemSet)]
  set_run_conditions : @hashmap.HashMap[SystemSet, Ref[ScheduleSetRunConditions[W]]]
  mut executor_kind : ExecutorKind
  mut apply_final_deferred : Bool
  mut chain_internal_set_counter : Int
  mut graph_generation : Int
  mut cached_graph_plan : ScheduleGraphPlan?
  mut cached_access_plan : ScheduleAccessPlan?
  mut last_reported_build_error_generation : Int?
  mut last_reported_invalid_access_key : (Int, Int, Int, Int, Bool)?
  mut build_settings : ScheduleBuildSettings
}

///|
fn[W] ScheduleEntry::new() -> ScheduleEntry[W] {
  {
    systems: [],
    set_edges: [],
    set_edges_ignore_deferred: [],
    set_run_conditions: @hashmap.HashMap::new(),
    executor_kind: MultiThreaded,
    apply_final_deferred: true,
    chain_internal_set_counter: 0,
    graph_generation: 0,
    cached_graph_plan: None,
    cached_access_plan: None,
    last_reported_build_error_generation: None,
    last_reported_invalid_access_key: None,
    build_settings: ScheduleBuildSettings::new(),
  }
}

///|
struct ScheduleRegistry[W] {
  entries : @hashmap.HashMap[String, Ref[ScheduleEntry[W]]]
}

///|
fn schedule_stage_storage_key(stage : ScheduleStage) -> String {
  match stage {
    Main => "Main"
    PreStartup => "PreStartup"
    Startup => "Startup"
    PostStartup => "PostStartup"
    First => "First"
    PreUpdate => "PreUpdate"
    StateTransition => "StateTransition"
    RunFixedMainLoop => "RunFixedMainLoop"
    FixedFirst => "FixedFirst"
    FixedPreUpdate => "FixedPreUpdate"
    FixedUpdate => "FixedUpdate"
    FixedPostUpdate => "FixedPostUpdate"
    FixedLast => "FixedLast"
    FixedMain => "FixedMain"
    Update => "Update"
    SpawnScene => "SpawnScene"
    PostUpdate => "PostUpdate"
    Last => "Last"
    Custom(name) => "__custom__:\{name}"
  }
}

///|
fn default_schedule_labels() -> Array[ScheduleStage] {
  [
    Main,
    PreStartup,
    Startup,
    PostStartup,
    First,
    PreUpdate,
    StateTransition,
    RunFixedMainLoop,
    FixedFirst,
    FixedPreUpdate,
    FixedUpdate,
    FixedPostUpdate,
    FixedLast,
    FixedMain,
    Update,
    SpawnScene,
    PostUpdate,
    Last,
  ]
}

///|
fn[W] schedule_entry_ref(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Ref[ScheduleEntry[W]] {
  let key = schedule_stage_storage_key(stage)
  match schedule_registry.entries.get(key) {
    Some(entry_ref) => entry_ref
    None => {
      let entry_ref = Ref::new(ScheduleEntry::new())
      schedule_registry.entries.set(key, entry_ref)
      entry_ref
    }
  }
}

///|
fn[W] ScheduleRegistry::new() -> ScheduleRegistry[W] {
  let schedule = ScheduleRegistry::{ entries: @hashmap.HashMap::new() }
  for stage in default_schedule_labels() {
    ignore(schedule_entry_ref(schedule, stage))
  }
  schedule_entry_ref(schedule, RunFixedMainLoop).val.set_edges.push(
    (
      run_fixed_main_loop_system_set_name(BeforeFixedMainLoop),
      run_fixed_main_loop_system_set_name(FixedMainLoop),
    ),
  )
  schedule_entry_ref(schedule, RunFixedMainLoop).val.set_edges.push(
    (
      run_fixed_main_loop_system_set_name(FixedMainLoop),
      run_fixed_main_loop_system_set_name(AfterFixedMainLoop),
    ),
  )
  schedule
}

///|
fn[W] schedule_entry_mark_graph_changed(schedule_entry : ScheduleEntry[W]) -> Unit {
  schedule_entry.graph_generation = schedule_entry.graph_generation + 1
  schedule_entry.cached_graph_plan = None
  schedule_entry.cached_access_plan = None
  schedule_entry.last_reported_build_error_generation = None
  schedule_entry.last_reported_invalid_access_key = None
}

///|
fn schedule_allowed_ambiguous_fingerprint(
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool],
) -> Int {
  let mut count = 0
  let mut sum = 0
  let mut sum_sq = 0
  for entry in allowed_ambiguous_components.iter() {
    let key = entry.0
    let value = if entry.1 { 1 } else { 0 }
    count = count + 1
    sum = sum + (key * 31 + value)
    sum_sq = sum_sq + ((key * key + 17) * (value + 1))
  }
  count * 1_000_003 + sum * 97 + sum_sq * 7
}

///|
fn schedule_pop_smallest(ready : Array[Int]) -> Int {
  let mut best_pos = 0
  let mut best_value = ready[0]
  let len = ready.length()
  for i in 1..<len {
    let value = ready[i]
    if value < best_value {
      best_value = value
      best_pos = i
    }
  }
  let last_index = ready.length() - 1
  ready[best_pos] = ready[last_index]
  ready.pop().unwrap() |> ignore
  best_value
}

///|
fn[W] schedule_build_graph_plan(
  schedule_entry : ScheduleEntry[W],
  stage : ScheduleStage,
) -> ScheduleGraphPlan {
  let seen : @hashmap.HashMap[SystemSet, Bool] = @hashmap.HashMap::new()
  let set_order : Array[SystemSet] = []
  fn push_unique(
    seen : @hashmap.HashMap[SystemSet, Bool],
    set_order : Array[SystemSet],
    set : SystemSet,
  ) -> Unit {
    if !seen.contains(set) {
      set_order.push(set)
      seen.set(set, true)
    }
  }

  let system_count = schedule_entry.systems.length()
  let groups : Array[SystemSet] = []
  for i in 0..<system_count {
    let cfg = schedule_entry.systems[i]
    let set = if cfg.set is Some(s) { s } else { "__anon#\{i.to_string()}" }
    groups.push(set)
    push_unique(seen, set_order, set)
    for other in cfg.before {
      push_unique(seen, set_order, other)
    }
    for other in cfg.after {
      push_unique(seen, set_order, other)
    }
    for other in cfg.before_ignore_deferred {
      push_unique(seen, set_order, other)
    }
    for other in cfg.after_ignore_deferred {
      push_unique(seen, set_order, other)
    }
  }
  for edge in schedule_entry.set_edges {
    push_unique(seen, set_order, edge.0)
    push_unique(seen, set_order, edge.1)
  }
  for edge in schedule_entry.set_edges_ignore_deferred {
    push_unique(seen, set_order, edge.0)
    push_unique(seen, set_order, edge.1)
  }
  let set_count = set_order.length()
  let set_index : @hashmap.HashMap[SystemSet, Int] = @hashmap.HashMap::new()
  for i in 0..<set_count {
    set_index.set(set_order[i], i)
  }
  let indeg : Array[Int] = []
  let adj : Array[Array[Int]] = []
  let dependency_edges : Array[(Int, Int, Bool)] = []
  for _ in 0..<set_count {
    indeg.push(0)
    adj.push([])
  }
  fn add_edge(
    set_index : @hashmap.HashMap[SystemSet, Int],
    indeg : Array[Int],
    adj : Array[Array[Int]],
    from : SystemSet,
    to : SystemSet,
    ignore_deferred : Bool,
  ) -> Unit {
    let from_i = set_index.at(from)
    let to_i = set_index.at(to)
    adj[from_i].push(to_i)
    dependency_edges.push((from_i, to_i, ignore_deferred))
    indeg[to_i] = indeg[to_i] + 1
  }

  for edge in schedule_entry.set_edges {
    add_edge(set_index, indeg, adj, edge.0, edge.1, false)
  }
  for edge in schedule_entry.set_edges_ignore_deferred {
    add_edge(set_index, indeg, adj, edge.0, edge.1, true)
  }
  for i in 0..<system_count {
    let cfg = schedule_entry.systems[i]
    let group = groups[i]
    for other in cfg.before {
      add_edge(set_index, indeg, adj, group, other, false)
    }
    for other in cfg.after {
      add_edge(set_index, indeg, adj, other, group, false)
    }
    for other in cfg.before_ignore_deferred {
      add_edge(set_index, indeg, adj, group, other, true)
    }
    for other in cfg.after_ignore_deferred {
      add_edge(set_index, indeg, adj, other, group, true)
    }
  }
  let indeg_for_topo : Array[Int] = []
  for value in indeg {
    indeg_for_topo.push(value)
  }
  let ready : Array[Int] = []
  for i in 0..<set_count {
    if indeg[i] == 0 {
      ready.push(i)
    }
  }
  let set_layers : Array[Array[Int]] = []
  let mut visited_count = 0
  while ready.length() > 0 {
    let layer : Array[Int] = []
    while ready.length() > 0 {
      layer.push(schedule_pop_smallest(ready))
    }
    visited_count = visited_count + layer.length()
    set_layers.push(layer)
    let next_ready : Array[Int] = []
    for next in layer {
      for to in adj[next] {
        indeg[to] = indeg[to] - 1
        if indeg[to] == 0 {
          next_ready.push(to)
        }
      }
    }
    for next in next_ready {
      ready.push(next)
    }
  }
  if visited_count != set_count {
    let cycle_sets : Array[String] = []
    for i in 0..<set_count {
      if indeg[i] > 0 {
        cycle_sets.push(set_order[i])
      }
    }
    let cycle_set_names = cycle_sets.join(", ")
    let cycle_hint = if cycle_sets.length() > 0 {
      " Cyclic sets: \{cycle_set_names}."
    } else {
      ""
    }
    let system_layers : Array[Int] = []
    for _ in 0..<system_count {
      system_layers.push(0)
    }
    return {
      graph_generation: schedule_entry.graph_generation,
      set_order,
      dependency_edges,
      groups,
      system_layers,
      execution_order: [],
      build_error: Some(
        "Schedule `\{to_repr(stage).to_string()}` has a dependency cycle between system sets.\{cycle_hint}",
      ),
    }
  }
  let set_layer_index : Array[Int] = []
  for _ in 0..<set_count {
    set_layer_index.push(0)
  }
  for layer_i in 0..<set_layers.length() {
    for set_i in set_layers[layer_i] {
      set_layer_index[set_i] = layer_i
    }
  }
  let topo_ready : Array[Int] = []
  for i in 0..<set_count {
    if indeg_for_topo[i] == 0 {
      topo_ready.push(i)
    }
  }
  let topo : Array[Int] = []
  while topo_ready.length() > 0 {
    let next = schedule_pop_smallest(topo_ready)
    topo.push(next)
    for to in adj[next] {
      indeg_for_topo[to] = indeg_for_topo[to] - 1
      if indeg_for_topo[to] == 0 {
        topo_ready.push(to)
      }
    }
  }
  if topo.length() != set_count {
    let system_layers : Array[Int] = []
    for _ in 0..<system_count {
      system_layers.push(0)
    }
    return {
      graph_generation: schedule_entry.graph_generation,
      set_order,
      dependency_edges,
      groups,
      system_layers,
      execution_order: [],
      build_error: Some(
        "Schedule `\{to_repr(stage).to_string()}` failed to build a valid execution order.",
      ),
    }
  }
  let systems_by_set : Array[Array[Int]] = []
  for _ in 0..<set_count {
    systems_by_set.push([])
  }
  for i in 0..<system_count {
    let set_i = set_index.at(groups[i])
    systems_by_set[set_i].push(i)
  }
  let execution_order : Array[Int] = []
  for set_i in topo {
    for system_i in systems_by_set[set_i] {
      execution_order.push(system_i)
    }
  }
  let system_layers : Array[Int] = []
  for i in 0..<system_count {
    let set_i = set_index.at(groups[i])
    system_layers.push(set_layer_index[set_i])
  }
  {
    graph_generation: schedule_entry.graph_generation,
    set_order,
    dependency_edges,
    groups,
    system_layers,
    execution_order,
    build_error: None,
  }
}

///|
fn[W] schedule_resolve_graph_plan(
  schedule_entry : ScheduleEntry[W],
  stage : ScheduleStage,
) -> ScheduleGraphPlan {
  match schedule_entry.cached_graph_plan {
    Some(plan) if plan.graph_generation == schedule_entry.graph_generation => plan
    _ => {
      let plan = schedule_build_graph_plan(schedule_entry, stage)
      schedule_entry.cached_graph_plan = Some(plan)
      plan
    }
  }
}

///|
fn[W] schedule_build_access_plan(
  schedule_entry : ScheduleEntry[W],
  graph_plan : ScheduleGraphPlan,
  build_settings : ScheduleBuildSettings,
  world : @ecs.World,
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool],
  world_id : Int,
  component_registration_generation : Int,
  allowed_ambiguous_fingerprint : Int,
) -> ScheduleAccessPlan {
  if graph_plan.build_error is Some(_) {
    return {
      graph_generation: graph_plan.graph_generation,
      world_id,
      component_registration_generation,
      allowed_ambiguous_fingerprint,
      auto_insert_apply_deferred: build_settings.auto_insert_apply_deferred(),
      system_accesses: [],
      runnable_execution_order: [],
      apply_after_execution_order: [],
      invalid_system_errors: [],
      single_threaded_batches: [],
      multi_threaded_batches: [],
    }
  }
  let system_count = schedule_entry.systems.length()
  let system_accesses : Array[SystemAccess] = []
  let invalid_system_errors : Array[(Int, String)] = []
  for i in 0..<system_count {
    match schedule_entry.systems[i].access_factory {
      Some(access_factory) => {
        let access = access_factory(world)
        match access.validation_error() {
          Some(message) => invalid_system_errors.push((i, message))
          None => ()
        }
        system_accesses.push(access)
      }
      None => system_accesses.push(SystemAccess::exclusive())
    }
  }
  let runnable_execution_order : Array[Int] = []
  for system_i in graph_plan.execution_order {
    if system_accesses[system_i].validation_error() is None {
      runnable_execution_order.push(system_i)
    }
  }
  let apply_after_execution_order : Array[Bool] = []
  for _ in 0..<runnable_execution_order.length() {
    apply_after_execution_order.push(false)
  }
  if build_settings.auto_insert_apply_deferred() {
    let set_count = graph_plan.set_order.length()
    let set_index : @hashmap.HashMap[SystemSet, Int] = @hashmap.HashMap::new()
    for i in 0..<set_count {
      set_index.set(graph_plan.set_order[i], i)
    }
    let set_has_deferred : Array[Bool] = []
    let set_has_exclusive : Array[Bool] = []
    let set_has_apply_deferred_node : Array[Bool] = []
    let set_has_unconditional_apply_deferred_node : Array[Bool] = []
    let set_has_run_conditions : Array[Bool] = []
    let set_first_execution_pos : Array[Int] = []
    let runnable_set_order : Array[Int] = []
    for i in 0..<set_count {
      set_has_deferred.push(false)
      set_has_exclusive.push(false)
      set_has_apply_deferred_node.push(false)
      set_has_unconditional_apply_deferred_node.push(false)
      let set_name = graph_plan.set_order[i]
      let has_run_conditions = match schedule_entry.set_run_conditions.get(set_name) {
        Some(run_conditions_ref) => run_conditions_ref.val.run_ifs.length() > 0
        None => false
      }
      set_has_run_conditions.push(has_run_conditions)
      set_first_execution_pos.push(-1)
    }
    let mut last_set_i : Int? = None
    for execution_i in 0..<runnable_execution_order.length() {
      let system_i = runnable_execution_order[execution_i]
      let config = schedule_entry.systems[system_i]
      let access = system_accesses[system_i]
      let set_i = set_index.at(graph_plan.groups[system_i])
      if set_first_execution_pos[set_i] < 0 {
        set_first_execution_pos[set_i] = execution_i
      }
      if last_set_i != Some(set_i) {
        runnable_set_order.push(set_i)
        last_set_i = Some(set_i)
      }
      if access.uses_deferred_commands() {
        set_has_deferred[set_i] = true
      }
      if access.is_exclusive() {
        set_has_exclusive[set_i] = true
      }
      if config.is_apply_deferred_node {
        set_has_apply_deferred_node[set_i] = true
        if config.run_ifs.length() == 0 && !set_has_run_conditions[set_i] {
          set_has_unconditional_apply_deferred_node[set_i] = true
        }
      }
    }
    let incoming_sets_all : Array[Array[Int]] = []
    let incoming_sets_requiring_sync : Array[Array[Int]] = []
    for _ in 0..<set_count {
      incoming_sets_all.push([])
      incoming_sets_requiring_sync.push([])
    }
    for edge in graph_plan.dependency_edges {
      let (from_i, to_i, ignore_deferred) = edge
      if !incoming_sets_all[to_i].contains(from_i) {
        incoming_sets_all[to_i].push(from_i)
      }
      if !ignore_deferred || set_has_exclusive[to_i] {
        if !incoming_sets_requiring_sync[to_i].contains(from_i) {
          incoming_sets_requiring_sync[to_i].push(from_i)
        }
      }
    }
    let pending_deferred_after_set : Array[Bool] = []
    for _ in 0..<set_count {
      pending_deferred_after_set.push(false)
    }
    for set_i in runnable_set_order {
      let mut pending_deferred_before_set = false
      for from_i in incoming_sets_all[set_i] {
        if pending_deferred_after_set[from_i] {
          pending_deferred_before_set = true
          break
        }
      }
      let mut needs_sync_before_set = false
      for from_i in incoming_sets_requiring_sync[set_i] {
        if pending_deferred_after_set[from_i] {
          needs_sync_before_set = true
          break
        }
      }
      if needs_sync_before_set {
        if set_has_unconditional_apply_deferred_node[set_i] {
          // Unconditional explicit ApplyDeferred acts as the sync point.
          pending_deferred_before_set = false
        } else if set_has_apply_deferred_node[set_i] {
          // Conditional explicit ApplyDeferred cannot be reused as an auto sync point.
          // Keep pending deferred and let it bubble to the next required boundary.
          ()
        } else {
          let first_pos = set_first_execution_pos[set_i]
          if first_pos > 0 {
            apply_after_execution_order[first_pos - 1] = true
          }
          pending_deferred_before_set = false
        }
      }
      if set_has_unconditional_apply_deferred_node[set_i] {
        // The explicit ApplyDeferred in this set drains deferred commands.
        pending_deferred_after_set[set_i] = set_has_deferred[set_i]
      } else {
        pending_deferred_after_set[set_i] =
          pending_deferred_before_set || set_has_deferred[set_i]
      }
    }
  }
  let single_threaded_batches : Array[Array[Int]] = []
  for system_i in runnable_execution_order {
    single_threaded_batches.push([system_i])
  }
  let multi_threaded_batches : Array[Array[Int]] = []
  let current_batch_ref : Ref[Array[Int]] = Ref::new([])
  let current_batch_layer_ref : Ref[Int?] = Ref::new(None)
  for system_i in runnable_execution_order {
    let system_layer = graph_plan.system_layers[system_i]
    let access = system_accesses[system_i]
    let can_join_current_batch = Ref::new(
      current_batch_ref.val.length() > 0 &&
      current_batch_layer_ref.val == Some(system_layer),
    )
    if can_join_current_batch.val {
      for existing_i in current_batch_ref.val {
        if !system_access_compatible(
            system_accesses[existing_i],
            access,
            allowed_ambiguous_components,
          ) {
          can_join_current_batch.val = false
          break
        }
      }
    }
    if current_batch_ref.val.length() == 0 {
      current_batch_ref.val = [system_i]
      current_batch_layer_ref.val = Some(system_layer)
    } else if can_join_current_batch.val {
      current_batch_ref.val.push(system_i)
    } else {
      multi_threaded_batches.push(current_batch_ref.val)
      current_batch_ref.val = [system_i]
      current_batch_layer_ref.val = Some(system_layer)
    }
  }
  if current_batch_ref.val.length() > 0 {
    multi_threaded_batches.push(current_batch_ref.val)
  }
  {
    graph_generation: graph_plan.graph_generation,
    world_id,
    component_registration_generation,
    allowed_ambiguous_fingerprint,
    auto_insert_apply_deferred: build_settings.auto_insert_apply_deferred(),
    system_accesses,
    runnable_execution_order,
    apply_after_execution_order,
    invalid_system_errors,
    single_threaded_batches,
    multi_threaded_batches,
  }
}

///|
fn[W] schedule_resolve_access_plan(
  schedule_entry : ScheduleEntry[W],
  graph_plan : ScheduleGraphPlan,
  build_settings : ScheduleBuildSettings,
  world : @ecs.World,
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool],
) -> ScheduleAccessPlan {
  let world_id = world.world_id()
  let component_registration_generation = world.component_registration_generation()
  let allowed_ambiguous_fingerprint = schedule_allowed_ambiguous_fingerprint(
    allowed_ambiguous_components,
  )
  match schedule_entry.cached_access_plan {
    Some(plan) if plan.graph_generation == graph_plan.graph_generation &&
      plan.world_id == world_id &&
      plan.component_registration_generation == component_registration_generation &&
      plan.auto_insert_apply_deferred ==
      build_settings.auto_insert_apply_deferred() &&
      plan.allowed_ambiguous_fingerprint == allowed_ambiguous_fingerprint => plan
    _ => {
      let plan = schedule_build_access_plan(
        schedule_entry,
        graph_plan,
        build_settings,
        world,
        allowed_ambiguous_components,
        world_id,
        component_registration_generation,
        allowed_ambiguous_fingerprint,
      )
      schedule_entry.cached_access_plan = Some(plan)
      plan
    }
  }
}

///|
fn[W] schedule_execution_plan(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  world : @ecs.World,
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool],
) -> ScheduleExecutionPlan[W] {
  let schedule_entry = schedule_entry_ref(schedule_registry, stage).val
  let graph_plan = schedule_resolve_graph_plan(schedule_entry, stage)
  let report_build_error = Ref::new(false)
  if graph_plan.build_error is Some(_) &&
    schedule_entry.last_reported_build_error_generation !=
    Some(graph_plan.graph_generation) {
    report_build_error.val = true
    schedule_entry.last_reported_build_error_generation = Some(
      graph_plan.graph_generation,
    )
  }
  let access_plan = schedule_resolve_access_plan(
    schedule_entry,
    graph_plan,
    schedule_entry.build_settings,
    world,
    allowed_ambiguous_components,
  )
  let report_invalid_system_errors = Ref::new(false)
  if access_plan.invalid_system_errors.length() > 0 {
    let access_key = (
      access_plan.graph_generation,
      access_plan.world_id,
      access_plan.component_registration_generation,
      access_plan.allowed_ambiguous_fingerprint,
      access_plan.auto_insert_apply_deferred,
    )
    if schedule_entry.last_reported_invalid_access_key != Some(access_key) {
      report_invalid_system_errors.val = true
      schedule_entry.last_reported_invalid_access_key = Some(access_key)
    }
  }
  let execution_batches = match schedule_entry.executor_kind {
    SingleThreaded => access_plan.single_threaded_batches
    MultiThreaded => access_plan.multi_threaded_batches
  }
  {
    systems: schedule_entry.systems,
    execution_order: access_plan.runnable_execution_order,
    execution_batches,
    apply_after_execution_order: access_plan.apply_after_execution_order,
    apply_final_deferred: schedule_entry.apply_final_deferred,
    set_run_conditions: schedule_entry.set_run_conditions,
    invalid_system_errors: access_plan.invalid_system_errors,
    report_invalid_system_errors: report_invalid_system_errors.val,
    build_error: graph_plan.build_error,
    report_build_error: report_build_error.val,
  }
}

///|
fn[W] schedule_next_chain_internal_set(
  schedule_entry : ScheduleEntry[W],
  stage : ScheduleStage,
) -> SystemSet {
  let next_id = schedule_entry.chain_internal_set_counter
  schedule_entry.chain_internal_set_counter = next_id + 1
  "__chain__:\{schedule_stage_storage_key(stage)}:\{next_id.to_string()}"
}

///|
fn[W] schedule_chain_inherit_config(
  child : SystemConfig[W],
  wrapper : SystemConfig[W],
) -> SystemConfig[W] {
  let inherited_error_handler = match child.error_handler {
    Some(_) => child.error_handler
    None => wrapper.error_handler
  }
  let inherited_set = match child.set {
    Some(_) => child.set
    None => wrapper.set
  }
  let run_ifs : Array[StatefulRunConditionFn[W]] = []
  for cond in child.run_ifs {
    run_ifs.push(cond)
  }
  for cond in wrapper.run_ifs {
    run_ifs.push(cond)
  }
  let run_if_states : Array[Ref[Json]] = []
  for state in child.run_if_states {
    run_if_states.push(state)
  }
  for state in wrapper.run_if_states {
    run_if_states.push(Ref::new(state.val))
  }
  let before : Array[SystemSet] = []
  for set in child.before {
    before.push(set)
  }
  for set in wrapper.before {
    before.push(set)
  }
  let after : Array[SystemSet] = []
  for set in child.after {
    after.push(set)
  }
  for set in wrapper.after {
    after.push(set)
  }
  let before_ignore_deferred : Array[SystemSet] = []
  for set in child.before_ignore_deferred {
    before_ignore_deferred.push(set)
  }
  for set in wrapper.before_ignore_deferred {
    before_ignore_deferred.push(set)
  }
  let after_ignore_deferred : Array[SystemSet] = []
  for set in child.after_ignore_deferred {
    after_ignore_deferred.push(set)
  }
  for set in wrapper.after_ignore_deferred {
    after_ignore_deferred.push(set)
  }
  let run_if_last_run_sequences : Array[@core.Sequence] = []
  for sequence in child.run_if_last_run_sequences {
    run_if_last_run_sequences.push(sequence)
  }
  for _ in wrapper.run_if_last_run_sequences {
    run_if_last_run_sequences.push(0)
  }
  SystemConfig::{
    ..child,
    error_handler: inherited_error_handler,
    run_ifs,
    run_if_states,
    set: inherited_set,
    before,
    after,
    before_ignore_deferred,
    after_ignore_deferred,
    run_if_last_run_sequences,
  }
}

///|
fn[W] schedule_collect_expanded_chain_members(
  config : SystemConfig[W],
  out : Array[SystemConfig[W]],
) -> Unit {
  match config.chain_members {
    Some(members) =>
      for child_config in members {
        let inherited = schedule_chain_inherit_config(child_config, config)
        schedule_collect_expanded_chain_members(inherited, out)
      }
    None => out.push(config)
  }
}

///|
fn[W] schedule_push_config(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  config : SystemConfig[W],
) -> Unit {
  let entry_ref = schedule_entry_ref(schedule_registry, stage)
  let graph_changed_ref = Ref::new(false)
  match config.chain_members {
    Some(_) => {
      let expanded_members : Array[SystemConfig[W]] = []
      schedule_collect_expanded_chain_members(config, expanded_members)
      if expanded_members.length() == 0 {
        return
      }
      let normalized_members : Array[SystemConfig[W]] = []
      for child_config in expanded_members {
        let normalized_member = match child_config.set {
          Some(_) => child_config
          None =>
            SystemConfig::{
              ..child_config,
              set: Some(
                schedule_next_chain_internal_set(entry_ref.val, stage),
              ),
            }
        }
        normalized_members.push(normalized_member)
        entry_ref.val.systems.push(normalized_member)
      }
      if normalized_members.length() <= 1 {
        return
      }
      for i in 0..<(normalized_members.length() - 1) {
        guard normalized_members[i].set is Some(left_set) else { continue }
        guard normalized_members[i + 1].set is Some(right_set) else { continue }
        if left_set != right_set {
          if config.chain_ignore_deferred {
            entry_ref.val.set_edges_ignore_deferred.push((left_set, right_set))
          } else {
            entry_ref.val.set_edges.push((left_set, right_set))
          }
          graph_changed_ref.val = true
        }
      }
      graph_changed_ref.val = true
    }
    None => {
      entry_ref.val.systems.push(config)
      graph_changed_ref.val = true
    }
  }
  if graph_changed_ref.val {
    schedule_entry_mark_graph_changed(entry_ref.val)
  }
}

///|
fn[W] schedule_systems(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Array[SystemConfig[W]] {
  schedule_entry_ref(schedule_registry, stage).val.systems
}

///|
fn[W] schedule_set_edges(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
) -> Array[(SystemSet, SystemSet)] {
  let entry = schedule_entry_ref(schedule_registry, stage).val
  let edges : Array[(SystemSet, SystemSet)] = []
  for edge in entry.set_edges {
    edges.push(edge)
  }
  for edge in entry.set_edges_ignore_deferred {
    edges.push(edge)
  }
  edges
}

///|
fn[W] schedule_set_executor_kind(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  executor_kind : ExecutorKind,
) -> Unit {
  schedule_entry_ref(schedule_registry, stage).val.executor_kind = executor_kind
}

///|
fn[W] schedule_set_apply_final_deferred(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  apply_final_deferred : Bool,
) -> Unit {
  schedule_entry_ref(
    schedule_registry,
    stage,
  ).val.apply_final_deferred = apply_final_deferred
}

///|
fn[W] schedule_set_build_settings(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  build_settings : ScheduleBuildSettings,
) -> Unit {
  let entry_ref = schedule_entry_ref(schedule_registry, stage)
  if entry_ref.val.build_settings != build_settings {
    entry_ref.val.build_settings = build_settings
    entry_ref.val.cached_access_plan = None
    entry_ref.val.last_reported_invalid_access_key = None
  }
}

pub fn[W] SubApp::add_schedule(
  self : SubApp[W],
  schedule : Schedule,
) -> SubApp[W] {
  schedule_set_executor_kind(
    self.schedule,
    schedule.label(),
    schedule.get_executor_kind(),
  )
  schedule_set_build_settings(
    self.schedule,
    schedule.label(),
    schedule.get_build_settings(),
  )
  schedule_set_apply_final_deferred(
    self.schedule,
    schedule.label(),
    schedule.get_apply_final_deferred(),
  )
  self
}

///|
pub fn[W] SubApp::get_schedule_executor_kind(
  self : SubApp[W],
  stage : ScheduleStage,
) -> ExecutorKind {
  schedule_entry_ref(self.schedule, stage).val.executor_kind
}

///|
fn[W] schedule_configure_set_run_conditions(
  schedule_entry : ScheduleEntry[W],
  set : SystemSet,
  set_run_ifs : Array[RunConditionFn[W]],
  set_run_if_statefuls : Array[(Json, StatefulRunConditionFn[W])],
) -> Bool {
  guard set_run_ifs.length() > 0 || set_run_if_statefuls.length() > 0 else {
    return false
  }
  let run_conditions_ref = match schedule_entry.set_run_conditions.get(set) {
    Some(existing_ref) => existing_ref
    None => {
      let created_ref = Ref::new(ScheduleSetRunConditions::{
        run_ifs: [],
        run_if_states: [],
        run_if_last_run_sequences: [],
      })
      schedule_entry.set_run_conditions.set(set, created_ref)
      created_ref
    }
  }
  for cond in set_run_ifs {
    run_conditions_ref.val.run_ifs.push(
      fn(world : W, _state : Ref[Json]) {
        cond(world)
      },
    )
    run_conditions_ref.val.run_if_states.push(Ref::new(Json::null()))
    run_conditions_ref.val.run_if_last_run_sequences.push(0)
  }
  for entry in set_run_if_statefuls {
    let (init_state, cond) = entry
    run_conditions_ref.val.run_ifs.push(cond)
    run_conditions_ref.val.run_if_states.push(Ref::new(init_state))
    run_conditions_ref.val.run_if_last_run_sequences.push(0)
  }
  true
}

///|
pub fn[W] SubApp::add_systems(
  self : SubApp[W],
  schedule : ScheduleStage,
  config : SystemConfig[W],
) -> SubApp[W] {
  schedule_push_config(self.schedule, schedule, config)
  self
}

///|
pub fn[W] SubApp::configure_set(
  self : SubApp[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
  before_ignore_deferred? : Array[SystemSet] = [],
  after_ignore_deferred? : Array[SystemSet] = [],
  set_run_ifs? : Array[RunConditionFn[W]] = [],
  set_run_if_statefuls? : Array[(Json, StatefulRunConditionFn[W])] = [],
) -> SubApp[W] {
  let entry_ref = schedule_entry_ref(self.schedule, stage)
  let edges = entry_ref.val.set_edges
  let ignore_deferred_edges = entry_ref.val.set_edges_ignore_deferred
  let mut graph_changed = false
  for other in before {
    edges.push((set, other))
    graph_changed = true
  }
  for other in after {
    edges.push((other, set))
    graph_changed = true
  }
  for other in before_ignore_deferred {
    ignore_deferred_edges.push((set, other))
    graph_changed = true
  }
  for other in after_ignore_deferred {
    ignore_deferred_edges.push((other, set))
    graph_changed = true
  }
  let access_changed = schedule_configure_set_run_conditions(
    entry_ref.val,
    set,
    set_run_ifs,
    set_run_if_statefuls,
  )
  if graph_changed {
    schedule_entry_mark_graph_changed(entry_ref.val)
  } else if access_changed {
    entry_ref.val.cached_access_plan = None
    entry_ref.val.last_reported_invalid_access_key = None
  }
  self
}

///|
pub fn[W] SubApp::configure_sets(
  self : SubApp[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
  before_ignore_deferred? : Array[SystemSet] = [],
  after_ignore_deferred? : Array[SystemSet] = [],
  set_run_ifs? : Array[RunConditionFn[W]] = [],
  set_run_if_statefuls? : Array[(Json, StatefulRunConditionFn[W])] = [],
) -> SubApp[W] {
  self.configure_set(
    stage,
    set,
    before~,
    after~,
    before_ignore_deferred~,
    after_ignore_deferred~,
    set_run_ifs~,
    set_run_if_statefuls~,
  )
}

///|
pub fn[W] App::add_schedule(self : App[W], schedule : Schedule) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.add_schedule(schedule)
  self
}

///|
pub fn[W] App::get_schedule_executor_kind(
  self : App[W],
  stage : ScheduleStage,
) -> ExecutorKind {
  self.sub_apps.main.get_schedule_executor_kind(stage)
}

///|
pub fn[W] App::add_systems(
  self : App[W],
  schedule : ScheduleStage,
  config : SystemConfig[W],
) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.add_systems(schedule, config)
  self
}

///|
pub fn[W] App::configure_set(
  self : App[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
  before_ignore_deferred? : Array[SystemSet] = [],
  after_ignore_deferred? : Array[SystemSet] = [],
  set_run_ifs? : Array[RunConditionFn[W]] = [],
  set_run_if_statefuls? : Array[(Json, StatefulRunConditionFn[W])] = [],
) -> App[W] {
  self.sub_apps.main = self.sub_apps.main.configure_set(
    stage,
    set,
    before~,
    after~,
    before_ignore_deferred~,
    after_ignore_deferred~,
    set_run_ifs~,
    set_run_if_statefuls~,
  )
  self
}

///|
pub fn[W] App::configure_sets(
  self : App[W],
  stage : ScheduleStage,
  set : SystemSet,
  before? : Array[SystemSet] = [],
  after? : Array[SystemSet] = [],
  before_ignore_deferred? : Array[SystemSet] = [],
  after_ignore_deferred? : Array[SystemSet] = [],
  set_run_ifs? : Array[RunConditionFn[W]] = [],
  set_run_if_statefuls? : Array[(Json, StatefulRunConditionFn[W])] = [],
) -> App[W] {
  self.configure_set(
    stage,
    set,
    before~,
    after~,
    before_ignore_deferred~,
    after_ignore_deferred~,
    set_run_ifs~,
    set_run_if_statefuls~,
  )
}
