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
  ScheduleBuildSettings::{ auto_insert_apply_deferred, }
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
fn schedule_build_passes_for_settings(
  settings : ScheduleBuildSettings,
) -> Array[ScheduleBuildPassKind] {
  if settings.auto_insert_apply_deferred() {
    [AutoInsertApplyDeferredPass]
  } else {
    []
  }
}

///|
priv struct ScheduleGraphPlan {
  graph_generation : Int
  set_order : Array[SystemSet]
  dependency_edges : Array[(Int, Int, Bool)]
  system_dependency_edges : Array[(Int, Int, Bool)]
  groups : Array[SystemSet]
  system_layers : Array[Int]
  execution_order : Array[Int]
  build_error : String?
}

///|
priv enum ScheduleExecutionNode {
  ScheduledSystem(Int)
}

priv struct ScheduleBuildPassGraph[W] {
  systems : Array[SystemConfig[W]]
  system_accesses : Array[SystemAccess]
  system_to_node : Array[Int]
  nodes : Array[ScheduleExecutionNode]
  node_edges : Array[(Int, Int)]
  base_node_order : Array[Int]
  mut auto_sync_count : Int
}

///|
priv struct ScheduleAccessPlan[W] {
  graph_generation : Int
  world_id : Int
  component_registration_generation : Int
  allowed_ambiguous_fingerprint : Int
  auto_insert_apply_deferred : Bool
  system_ids : Array[Int]
  systems : Array[SystemConfig[W]]
  system_accesses : Array[SystemAccess]
  system_dependencies : Array[Int]
  system_dependents : Array[Array[Int]]
  set_ids : Array[SystemSet]
  sets_with_conditions_of_systems : Array[Array[Int]]
  systems_in_sets_with_conditions : Array[Array[Int]]
  execution_order : Array[ScheduleExecutionNode]
  invalid_system_errors : Array[(Int, String)]
  single_threaded_batches : Array[Array[ScheduleExecutionNode]]
  multi_threaded_batches : Array[Array[ScheduleExecutionNode]]
}

///|
priv struct ScheduleExecutionPlan[W] {
  systems : Array[SystemConfig[W]]
  execution_order : Array[ScheduleExecutionNode]
  execution_batches : Array[Array[ScheduleExecutionNode]]
  system_accesses : Array[SystemAccess]
  set_ids : Array[SystemSet]
  sets_with_conditions_of_systems : Array[Array[Int]]
  systems_in_sets_with_conditions : Array[Array[Int]]
  apply_final_deferred : Bool
  set_run_conditions : @hashmap.HashMap[
    SystemSet,
    Ref[ScheduleSetRunConditions[W]],
  ]
  invalid_system_errors : Array[(Int, String)]
  report_invalid_system_errors : Bool
  build_error : String?
  report_build_error : Bool
  executor_state : Ref[SingleThreadedExecutorState]
}

///|
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
  set_run_conditions : @hashmap.HashMap[
    SystemSet,
    Ref[ScheduleSetRunConditions[W]],
  ]
  mut executor_kind : ExecutorKind
  mut apply_final_deferred : Bool
  mut chain_internal_set_counter : Int
  mut graph_generation : Int
  mut cached_graph_plan : ScheduleGraphPlan?
  mut cached_access_plan : ScheduleAccessPlan[W]?
  mut last_reported_build_error_generation : Int?
  mut last_reported_invalid_access_key : (Int, Int, Int, Int, Bool)?
  mut build_settings : ScheduleBuildSettings
  mut build_passes : Array[ScheduleBuildPassKind]
  executor_state : Ref[SingleThreadedExecutorState]
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
    build_passes: schedule_build_passes_for_settings(ScheduleBuildSettings::new()),
    executor_state: Ref::new(single_threaded_executor_state_new(0, 0, true)),
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
fn[W] schedule_entry_mark_graph_changed(
  schedule_entry : ScheduleEntry[W],
) -> Unit {
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
    sum_sq = sum_sq + (key * key + 17) * (value + 1)
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
fn schedule_add_unique_system_edge(
  edges : Array[(Int, Int, Bool)],
  from_system : Int,
  to_system : Int,
  ignore_deferred : Bool,
) -> Unit {
  if from_system == to_system {
    return
  }
  for edge_i in 0..<edges.length() {
    let (existing_from, existing_to, existing_ignore) = edges[edge_i]
    if existing_from == from_system && existing_to == to_system {
      if existing_ignore && !ignore_deferred {
        edges[edge_i] = (from_system, to_system, false)
      }
      return
    }
  }
  edges.push((from_system, to_system, ignore_deferred))
}

///|
fn schedule_add_unique_node_edge(
  edges : Array[(Int, Int)],
  from_node : Int,
  to_node : Int,
) -> Unit {
  if from_node == to_node {
    return
  }
  for edge in edges {
    if edge.0 == from_node && edge.1 == to_node {
      return
    }
  }
  edges.push((from_node, to_node))
}

///|
fn schedule_pop_ready_by_rank(ready : Array[Int], rank : Array[Int]) -> Int {
  let mut best_pos = 0
  let mut best_value = ready[0]
  let mut best_rank = rank[best_value]
  let len = ready.length()
  for i in 1..<len {
    let value = ready[i]
    let value_rank = rank[value]
    if value_rank < best_rank || (value_rank == best_rank && value < best_value) {
      best_value = value
      best_rank = value_rank
      best_pos = i
    }
  }
  let last_index = ready.length() - 1
  ready[best_pos] = ready[last_index]
  ready.pop().unwrap() |> ignore
  best_value
}

///|
fn schedule_topo_system_order(
  system_count : Int,
  base_order : Array[Int],
  edges : Array[(Int, Int, Bool)],
  runnable_mask : Array[Bool],
) -> Array[Int]? {
  let rank : Array[Int] = []
  for i in 0..<system_count {
    rank.push(system_count + i)
  }
  for order_i in 0..<base_order.length() {
    rank[base_order[order_i]] = order_i
  }
  let indeg : Array[Int] = []
  let adj : Array[Array[Int]] = []
  for _ in 0..<system_count {
    indeg.push(0)
    adj.push([])
  }
  for edge in edges {
    let (from_system, to_system, _) = edge
    if runnable_mask[from_system] && runnable_mask[to_system] {
      if !adj[from_system].contains(to_system) {
        adj[from_system].push(to_system)
        indeg[to_system] = indeg[to_system] + 1
      }
    }
  }
  let ready : Array[Int] = []
  let mut runnable_count = 0
  for i in 0..<system_count {
    if runnable_mask[i] {
      runnable_count = runnable_count + 1
      if indeg[i] == 0 {
        ready.push(i)
      }
    }
  }
  let order : Array[Int] = []
  while ready.length() > 0 {
    let system_i = schedule_pop_ready_by_rank(ready, rank)
    order.push(system_i)
    for to_system in adj[system_i] {
      indeg[to_system] = indeg[to_system] - 1
      if indeg[to_system] == 0 {
        ready.push(to_system)
      }
    }
  }
  if order.length() == runnable_count {
    Some(order)
  } else {
    None
  }
}

///|
fn schedule_topo_node_order(
  node_count : Int,
  base_order : Array[Int],
  edges : Array[(Int, Int)],
) -> Array[Int]? {
  let rank : Array[Int] = []
  for i in 0..<node_count {
    rank.push(node_count + i)
  }
  for order_i in 0..<base_order.length() {
    rank[base_order[order_i]] = order_i
  }
  let indeg : Array[Int] = []
  let adj : Array[Array[Int]] = []
  for _ in 0..<node_count {
    indeg.push(0)
    adj.push([])
  }
  for edge in edges {
    let (from_node, to_node) = edge
    if from_node != to_node && !adj[from_node].contains(to_node) {
      adj[from_node].push(to_node)
      indeg[to_node] = indeg[to_node] + 1
    }
  }
  let ready : Array[Int] = []
  for i in 0..<node_count {
    if indeg[i] == 0 {
      ready.push(i)
    }
  }
  let order : Array[Int] = []
  while ready.length() > 0 {
    let node_i = schedule_pop_ready_by_rank(ready, rank)
    order.push(node_i)
    for to_node in adj[node_i] {
      indeg[to_node] = indeg[to_node] - 1
      if indeg[to_node] == 0 {
        ready.push(to_node)
      }
    }
  }
  if order.length() == node_count {
    Some(order)
  } else {
    None
  }
}

///|
fn[W] schedule_build_pass_graph_new(
  system_count : Int,
  systems : Array[SystemConfig[W]],
  system_accesses : Array[SystemAccess],
  base_system_order : Array[Int],
  base_system_edges : Array[(Int, Int, Bool)],
) -> ScheduleBuildPassGraph[W] {
  let system_to_node : Array[Int] = []
  for _ in 0..<system_count {
    system_to_node.push(-1)
  }
  let nodes : Array[ScheduleExecutionNode] = []
  let base_node_order : Array[Int] = []
  for system_i in base_system_order {
    let node_i = nodes.length()
    system_to_node[system_i] = node_i
    nodes.push(ScheduledSystem(system_i))
    base_node_order.push(node_i)
  }
  let node_edges : Array[(Int, Int)] = []
  for edge in base_system_edges {
    let from_node = system_to_node[edge.0]
    let to_node = system_to_node[edge.1]
    if from_node >= 0 && to_node >= 0 {
      schedule_add_unique_node_edge(node_edges, from_node, to_node)
    }
  }
  {
    systems: systems.copy(),
    system_accesses: system_accesses.copy(),
    system_to_node,
    nodes,
    node_edges,
    base_node_order,
    auto_sync_count: 0,
  }
}

///|
fn[W] ScheduleBuildPassGraph::add_auto_sync_node(
  self : ScheduleBuildPassGraph[W],
) -> Int {
  let node_i = self.nodes.length()
  let sync_i = self.auto_sync_count
  self.auto_sync_count = sync_i + 1
  let system_i = self.systems.length()
  self.systems.push(auto_apply_deferred_system(sync_i))
  self.system_accesses.push(SystemAccess::new())
  self.system_to_node.push(node_i)
  self.nodes.push(ScheduledSystem(system_i))
  self.base_node_order.push(node_i)
  node_i
}

///|
fn[W] ScheduleBuildPassGraph::system_node(
  self : ScheduleBuildPassGraph[W],
  system_i : Int,
) -> Int {
  self.system_to_node[system_i]
}

///|
fn[W] ScheduleBuildPassGraph::add_edge(
  self : ScheduleBuildPassGraph[W],
  from_node : Int,
  to_node : Int,
) -> Unit {
  if from_node >= 0 && to_node >= 0 {
    schedule_add_unique_node_edge(self.node_edges, from_node, to_node)
  }
}

///|
fn[W] ScheduleBuildPassGraph::remove_edge(
  self : ScheduleBuildPassGraph[W],
  from_node : Int,
  to_node : Int,
) -> Unit {
  for edge_i in 0..<self.node_edges.length() {
    let edge = self.node_edges[edge_i]
    if edge.0 == from_node && edge.1 == to_node {
      self.node_edges.remove(edge_i) |> ignore
      return
    }
  }
}

///|
fn[W] schedule_build_pass_graph_execution_order(
  graph : ScheduleBuildPassGraph[W],
) -> Array[ScheduleExecutionNode] {
  let node_order = match schedule_topo_node_order(
    graph.nodes.length(),
    graph.base_node_order,
    graph.node_edges,
  ) {
    Some(order) => order
    None => graph.base_node_order
  }
  let execution_order : Array[ScheduleExecutionNode] = []
  for node_i in node_order {
    execution_order.push(graph.nodes[node_i])
  }
  execution_order
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
  let membership_groups : @hashmap.HashMap[SystemSet, Array[SystemSet]] = @hashmap.HashMap::new()
  fn add_membership_group(
    membership_groups : @hashmap.HashMap[SystemSet, Array[SystemSet]],
    member_set : SystemSet,
    group : SystemSet,
  ) -> Unit {
    match membership_groups.get(member_set) {
      Some(groups) => if !groups.contains(group) { groups.push(group) }
      None => membership_groups.set(member_set, [group])
    }
  }
  fn member_groups_for_set(
    membership_groups : @hashmap.HashMap[SystemSet, Array[SystemSet]],
    set : SystemSet,
  ) -> Array[SystemSet] {
    match membership_groups.get(set) {
      Some(groups) if groups.length() > 0 => groups
      _ => [set]
    }
  }
  for i in 0..<system_count {
    let cfg = schedule_entry.systems[i]
    let set = if cfg.set is Some(s) { s } else { "__anon#\{i.to_string()}" }
    groups.push(set)
    push_unique(seen, set_order, set)
    for member_set in cfg.member_sets {
      add_membership_group(membership_groups, member_set, set)
      push_unique(seen, set_order, member_set)
    }
    match cfg.set {
      Some(member_set) =>
        if !member_set.has_prefix("__chain__:") {
          add_membership_group(membership_groups, member_set, set)
          push_unique(seen, set_order, member_set)
        }
      None => ()
    }
  }
  for edge in schedule_entry.set_edges {
    for set in member_groups_for_set(membership_groups, edge.0) {
      push_unique(seen, set_order, set)
    }
    for set in member_groups_for_set(membership_groups, edge.1) {
      push_unique(seen, set_order, set)
    }
  }
  for edge in schedule_entry.set_edges_ignore_deferred {
    for set in member_groups_for_set(membership_groups, edge.0) {
      push_unique(seen, set_order, set)
    }
    for set in member_groups_for_set(membership_groups, edge.1) {
      push_unique(seen, set_order, set)
    }
  }
  for i in 0..<system_count {
    let cfg = schedule_entry.systems[i]
    for other in cfg.before {
      for set in member_groups_for_set(membership_groups, other) {
        push_unique(seen, set_order, set)
      }
    }
    for other in cfg.after {
      for set in member_groups_for_set(membership_groups, other) {
        push_unique(seen, set_order, set)
      }
    }
    for other in cfg.before_ignore_deferred {
      for set in member_groups_for_set(membership_groups, other) {
        push_unique(seen, set_order, set)
      }
    }
    for other in cfg.after_ignore_deferred {
      for set in member_groups_for_set(membership_groups, other) {
        push_unique(seen, set_order, set)
      }
    }
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
    if from == to {
      return
    }
    let from_i = set_index.at(from)
    let to_i = set_index.at(to)
    adj[from_i].push(to_i)
    dependency_edges.push((from_i, to_i, ignore_deferred))
    indeg[to_i] = indeg[to_i] + 1
  }
  fn add_group_to_set_edges(
    set_index : @hashmap.HashMap[SystemSet, Int],
    indeg : Array[Int],
    adj : Array[Array[Int]],
    from : SystemSet,
    to_set : SystemSet,
    ignore_deferred : Bool,
  ) -> Unit {
    for to in member_groups_for_set(membership_groups, to_set) {
      add_edge(set_index, indeg, adj, from, to, ignore_deferred)
    }
  }
  fn add_set_to_group_edges(
    set_index : @hashmap.HashMap[SystemSet, Int],
    indeg : Array[Int],
    adj : Array[Array[Int]],
    from_set : SystemSet,
    to : SystemSet,
    ignore_deferred : Bool,
  ) -> Unit {
    for from in member_groups_for_set(membership_groups, from_set) {
      add_edge(set_index, indeg, adj, from, to, ignore_deferred)
    }
  }
  fn add_set_to_set_edges(
    set_index : @hashmap.HashMap[SystemSet, Int],
    indeg : Array[Int],
    adj : Array[Array[Int]],
    from_set : SystemSet,
    to_set : SystemSet,
    ignore_deferred : Bool,
  ) -> Unit {
    for from in member_groups_for_set(membership_groups, from_set) {
      for to in member_groups_for_set(membership_groups, to_set) {
        add_edge(set_index, indeg, adj, from, to, ignore_deferred)
      }
    }
  }

  for edge in schedule_entry.set_edges {
    add_set_to_set_edges(set_index, indeg, adj, edge.0, edge.1, false)
  }
  for edge in schedule_entry.set_edges_ignore_deferred {
    add_set_to_set_edges(set_index, indeg, adj, edge.0, edge.1, true)
  }
  for i in 0..<system_count {
    let cfg = schedule_entry.systems[i]
    let group = groups[i]
    for other in cfg.before {
      add_group_to_set_edges(set_index, indeg, adj, group, other, false)
    }
    for other in cfg.after {
      add_set_to_group_edges(set_index, indeg, adj, other, group, false)
    }
    for other in cfg.before_ignore_deferred {
      add_group_to_set_edges(set_index, indeg, adj, group, other, true)
    }
    for other in cfg.after_ignore_deferred {
      add_set_to_group_edges(set_index, indeg, adj, other, group, true)
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
      system_dependency_edges: [],
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
      system_dependency_edges: [],
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
  let set_out_edges : Array[Array[(Int, Bool)]] = []
  for _ in 0..<set_count {
    set_out_edges.push([])
  }
  for edge in dependency_edges {
    let (from_i, to_i, ignore_deferred) = edge
    set_out_edges[from_i].push((to_i, ignore_deferred))
  }
  let system_dependency_edges : Array[(Int, Int, Bool)] = []
  fn walk_system_dependency_edges(
    source_system : Int,
    set_i : Int,
    path_ignore_deferred : Bool,
  ) -> Unit {
    for edge in set_out_edges[set_i] {
      let (to_set_i, edge_ignore_deferred) = edge
      let next_ignore_deferred = path_ignore_deferred && edge_ignore_deferred
      if systems_by_set[to_set_i].length() > 0 {
        for target_system in systems_by_set[to_set_i] {
          schedule_add_unique_system_edge(
            system_dependency_edges, source_system, target_system, next_ignore_deferred,
          )
        }
      } else {
        walk_system_dependency_edges(
          source_system, to_set_i, next_ignore_deferred,
        )
      }
    }
  }
  for set_i in 0..<set_count {
    for source_system in systems_by_set[set_i] {
      walk_system_dependency_edges(source_system, set_i, true)
    }
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
    system_dependency_edges,
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
    Some(plan) if plan.graph_generation == schedule_entry.graph_generation =>
      plan
    _ => {
      let plan = schedule_build_graph_plan(schedule_entry, stage)
      schedule_entry.cached_graph_plan = Some(plan)
      plan
    }
  }
}

///|
fn[W] schedule_set_has_run_conditions(
  schedule_entry : ScheduleEntry[W],
  set : SystemSet,
) -> Bool {
  match schedule_entry.set_run_conditions.get(set) {
    Some(run_conditions_ref) => run_conditions_ref.val.run_ifs.length() > 0
    None => false
  }
}

///|
fn[W] schedule_system_has_run_conditions(
  schedule_entry : ScheduleEntry[W],
  config : SystemConfig[W],
) -> Bool {
  if config.run_ifs.length() > 0 {
    return true
  }
  match config.set {
    Some(set) =>
      if !set.has_prefix("__chain__:") &&
        schedule_set_has_run_conditions(schedule_entry, set) {
        return true
      }
    None => ()
  }
  for set in config.member_sets {
    if schedule_set_has_run_conditions(schedule_entry, set) {
      return true
    }
  }
  false
}

fn[W] schedule_build_access_plan(
  schedule_entry : ScheduleEntry[W],
  graph_plan : ScheduleGraphPlan,
  build_settings : ScheduleBuildSettings,
  world : @ecs.World,
  allowed_ambiguous_components : @hashmap.HashMap[Int, Bool],
  world_id : Int,
  component_registration_generation : Int,
  allowed_ambiguous_fingerprint : Int,
) -> ScheduleAccessPlan[W] {
  if graph_plan.build_error is Some(_) {
    return {
      graph_generation: graph_plan.graph_generation,
      world_id,
      component_registration_generation,
      allowed_ambiguous_fingerprint,
      auto_insert_apply_deferred: build_settings.auto_insert_apply_deferred(),
      system_ids: [],
      systems: [],
      system_accesses: [],
      system_dependencies: [],
      system_dependents: [],
      set_ids: [],
      sets_with_conditions_of_systems: [],
      systems_in_sets_with_conditions: [],
      execution_order: [],
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
  let runnable_mask : Array[Bool] = []
  for _ in 0..<system_count {
    runnable_mask.push(true)
  }
  let set_ids : Array[SystemSet] = []
  for set in graph_plan.set_order {
    if schedule_set_has_run_conditions(schedule_entry, set) {
      set_ids.push(set)
    }
  }
  let sets_with_conditions_of_systems : Array[Array[Int]] = []
  for _ in 0..<system_count {
    sets_with_conditions_of_systems.push([])
  }
  let systems_in_sets_with_conditions : Array[Array[Int]] = []
  for _ in 0..<set_ids.length() {
    systems_in_sets_with_conditions.push([])
  }
  for set_i in 0..<set_ids.length() {
    let set = set_ids[set_i]
    for system_i in 0..<system_count {
      let cfg = schedule_entry.systems[system_i]
      let mut in_set = cfg.member_sets.contains(set)
      match cfg.set {
        Some(primary_set) => if primary_set == set { in_set = true }
        None => ()
      }
      if in_set {
        sets_with_conditions_of_systems[system_i].push(set_i)
        systems_in_sets_with_conditions[set_i].push(system_i)
      }
    }
  }
  let base_system_edges : Array[(Int, Int, Bool)] = []
  for edge in graph_plan.system_dependency_edges {
    let (from_system, to_system, ignore_deferred) = edge
    if runnable_mask[from_system] && runnable_mask[to_system] {
      schedule_add_unique_system_edge(
        base_system_edges, from_system, to_system, ignore_deferred,
      )
    }
  }
  let base_runnable_execution_order = match
    schedule_topo_system_order(
      system_count,
      graph_plan.execution_order,
      base_system_edges,
      runnable_mask,
    ) {
    Some(order) => order
    None => {
      let order : Array[Int] = []
      for system_i in graph_plan.execution_order {
        if runnable_mask[system_i] {
          order.push(system_i)
        }
      }
      order
    }
  }
  let build_pass_graph = schedule_build_pass_graph_new(
    system_count,
    schedule_entry.systems,
    system_accesses,
    base_runnable_execution_order,
    base_system_edges,
  )
  schedule_run_build_passes(
    schedule_entry,
    build_pass_graph,
    base_runnable_execution_order,
    base_system_edges,
    system_accesses,
    runnable_mask,
  )
  let execution_order = schedule_build_pass_graph_execution_order(build_pass_graph)
  let execution_systems_by_source = build_pass_graph.systems
  let execution_system_accesses_by_source = build_pass_graph.system_accesses
  let source_to_execution_system : Array[Int] = []
  for _ in 0..<execution_systems_by_source.length() {
    source_to_execution_system.push(-1)
  }
  let execution_systems : Array[SystemConfig[W]] = []
  let execution_system_accesses : Array[SystemAccess] = []
  let execution_system_ids : Array[Int] = []
  let ordered_execution_order : Array[ScheduleExecutionNode] = []
  for node in execution_order {
    match node {
      ScheduledSystem(source_system_i) => {
        let execution_system_i = execution_systems.length()
        source_to_execution_system[source_system_i] = execution_system_i
        execution_systems.push(execution_systems_by_source[source_system_i])
        execution_system_accesses.push(
          execution_system_accesses_by_source[source_system_i],
        )
        execution_system_ids.push(source_system_i)
        ordered_execution_order.push(ScheduledSystem(execution_system_i))
      }
    }
  }
  let system_dependencies : Array[Int] = []
  let system_dependents : Array[Array[Int]] = []
  for _ in 0..<execution_systems.length() {
    system_dependencies.push(0)
    system_dependents.push([])
  }
  for edge in build_pass_graph.node_edges {
    let from_node = edge.0
    let to_node = edge.1
    match (build_pass_graph.nodes[from_node], build_pass_graph.nodes[to_node]) {
      (ScheduledSystem(from_source_i), ScheduledSystem(to_source_i)) => {
        let from_execution_i = source_to_execution_system[from_source_i]
        let to_execution_i = source_to_execution_system[to_source_i]
        if from_execution_i >= 0 && to_execution_i >= 0 {
          system_dependencies[to_execution_i] = system_dependencies[to_execution_i] + 1
          if !system_dependents[from_execution_i].contains(to_execution_i) {
            system_dependents[from_execution_i].push(to_execution_i)
          }
        }
      }
    }
  }
  let ordered_sets_with_conditions_of_systems : Array[Array[Int]] = []
  for _ in 0..<execution_systems.length() {
    ordered_sets_with_conditions_of_systems.push([])
  }
  for source_system_i in 0..<sets_with_conditions_of_systems.length() {
    if source_system_i < source_to_execution_system.length() {
      let execution_system_i = source_to_execution_system[source_system_i]
      if execution_system_i >= 0 {
        ordered_sets_with_conditions_of_systems[execution_system_i] = sets_with_conditions_of_systems[source_system_i]
      }
    }
  }
  let ordered_systems_in_sets_with_conditions : Array[Array[Int]] = []
  for set_systems in systems_in_sets_with_conditions {
    let ordered_set_systems : Array[Int] = []
    for source_system_i in set_systems {
      if source_system_i < source_to_execution_system.length() {
        let execution_system_i = source_to_execution_system[source_system_i]
        if execution_system_i >= 0 {
          ordered_set_systems.push(execution_system_i)
        }
      }
    }
    ordered_systems_in_sets_with_conditions.push(ordered_set_systems)
  }
  let ordered_invalid_system_errors : Array[(Int, String)] = []
  for invalid in invalid_system_errors {
    let source_system_i = invalid.0
    if source_system_i < source_to_execution_system.length() {
      let execution_system_i = source_to_execution_system[source_system_i]
      if execution_system_i >= 0 {
        ordered_invalid_system_errors.push((execution_system_i, invalid.1))
      }
    }
  }
  let execution_system_layers : Array[Int] = []
  for _ in 0..<execution_systems.length() {
    execution_system_layers.push(0)
  }
  for source_system_i in 0..<source_to_execution_system.length() {
    let execution_system_i = source_to_execution_system[source_system_i]
    if execution_system_i >= 0 && source_system_i < graph_plan.system_layers.length() {
      execution_system_layers[execution_system_i] = graph_plan.system_layers[source_system_i]
    }
  }
  let single_threaded_batches : Array[Array[ScheduleExecutionNode]] = []
  for node in ordered_execution_order {
    single_threaded_batches.push([node])
  }
  let multi_threaded_batches : Array[Array[ScheduleExecutionNode]] = []
  let current_batch_ref : Ref[Array[ScheduleExecutionNode]] = Ref::new([])
  let current_batch_layer_ref : Ref[Int?] = Ref::new(None)
  fn flush_current_batch() -> Unit {
    if current_batch_ref.val.length() > 0 {
      multi_threaded_batches.push(current_batch_ref.val)
      current_batch_ref.val = []
      current_batch_layer_ref.val = None
    }
  }
  for node in ordered_execution_order {
    match node {
      ScheduledSystem(system_i) => {
        if execution_systems[system_i].is_apply_deferred_node {
          flush_current_batch()
          multi_threaded_batches.push([node])
          continue
        }
        let system_layer = execution_system_layers[system_i]
        let access = execution_system_accesses[system_i]
        let can_join_current_batch = Ref::new(
          current_batch_ref.val.length() > 0 &&
          current_batch_layer_ref.val == Some(system_layer),
        )
        if can_join_current_batch.val {
          for existing_node in current_batch_ref.val {
            match existing_node {
              ScheduledSystem(existing_i) =>
                if !system_access_compatible(
                    execution_system_accesses[existing_i],
                    access,
                    allowed_ambiguous_components,
                  ) {
                  can_join_current_batch.val = false
                  break
                }
            }
          }
        }
        if current_batch_ref.val.length() == 0 {
          current_batch_ref.val = [node]
          current_batch_layer_ref.val = Some(system_layer)
        } else if can_join_current_batch.val {
          current_batch_ref.val.push(node)
        } else {
          multi_threaded_batches.push(current_batch_ref.val)
          current_batch_ref.val = [node]
          current_batch_layer_ref.val = Some(system_layer)
        }
      }
    }
  }
  flush_current_batch()
  {
    graph_generation: graph_plan.graph_generation,
    world_id,
    component_registration_generation,
    allowed_ambiguous_fingerprint,
    auto_insert_apply_deferred: build_settings.auto_insert_apply_deferred(),
    system_ids: execution_system_ids,
    systems: execution_systems,
    system_accesses: execution_system_accesses,
    system_dependencies,
    system_dependents,
    set_ids,
    sets_with_conditions_of_systems: ordered_sets_with_conditions_of_systems,
    systems_in_sets_with_conditions: ordered_systems_in_sets_with_conditions,
    execution_order: ordered_execution_order,
    invalid_system_errors: ordered_invalid_system_errors,
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
) -> ScheduleAccessPlan[W] {
  let world_id = world.world_id()
  let component_registration_generation = world.component_registration_generation()
  let allowed_ambiguous_fingerprint = schedule_allowed_ambiguous_fingerprint(
    allowed_ambiguous_components,
  )
  match schedule_entry.cached_access_plan {
    Some(plan) if plan.graph_generation == graph_plan.graph_generation &&
      plan.world_id == world_id &&
      plan.component_registration_generation ==
      component_registration_generation &&
      plan.auto_insert_apply_deferred ==
      build_settings.auto_insert_apply_deferred() &&
      plan.allowed_ambiguous_fingerprint == allowed_ambiguous_fingerprint =>
      plan
    _ => {
      let plan = schedule_build_access_plan(
        schedule_entry, graph_plan, build_settings, world, allowed_ambiguous_components,
        world_id, component_registration_generation, allowed_ambiguous_fingerprint,
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
    systems: access_plan.systems,
    execution_order: access_plan.execution_order,
    execution_batches,
    system_accesses: access_plan.system_accesses,
    set_ids: access_plan.set_ids,
    sets_with_conditions_of_systems: access_plan.sets_with_conditions_of_systems,
    systems_in_sets_with_conditions: access_plan.systems_in_sets_with_conditions,
    apply_final_deferred: schedule_entry.apply_final_deferred,
    set_run_conditions: schedule_entry.set_run_conditions,
    invalid_system_errors: access_plan.invalid_system_errors,
    report_invalid_system_errors: report_invalid_system_errors.val,
    build_error: graph_plan.build_error,
    report_build_error: report_build_error.val,
    executor_state: schedule_entry.executor_state,
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
  let member_sets : Array[SystemSet] = []
  for set in child.member_sets {
    if !member_sets.contains(set) {
      member_sets.push(set)
    }
  }
  for set in wrapper.member_sets {
    if !member_sets.contains(set) {
      member_sets.push(set)
    }
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
    member_sets,
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
        let member_sets : Array[SystemSet] = []
        for set in child_config.member_sets {
          if !member_sets.contains(set) {
            member_sets.push(set)
          }
        }
        match child_config.set {
          Some(set) =>
            if !member_sets.contains(set) && !set.has_prefix("__chain__:") {
              member_sets.push(set)
            }
          None => ()
        }
        let normalized_member = SystemConfig::{
          ..child_config,
          set: Some(schedule_next_chain_internal_set(entry_ref.val, stage)),
          member_sets,
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
fn[W] schedule_set_executor_kind(
  schedule_registry : ScheduleRegistry[W],
  stage : ScheduleStage,
  executor_kind : ExecutorKind,
) -> Unit {
  schedule_entry_ref(schedule_registry, stage).val.executor_kind = executor_kind
}

///|
fn[W] schedule_replace_entry(
  schedule_registry : ScheduleRegistry[W],
  schedule : Schedule,
) -> Unit {
  let key = schedule_stage_storage_key(schedule.label())
  let entry_ref = Ref::new(ScheduleEntry::new())
  entry_ref.val.executor_kind = schedule.get_executor_kind()
  entry_ref.val.build_settings = schedule.get_build_settings()
  entry_ref.val.build_passes = schedule_build_passes_for_settings(
    schedule.get_build_settings(),
  )
  entry_ref.val.apply_final_deferred = schedule.get_apply_final_deferred()
  schedule_registry.entries.set(key, entry_ref)
}

///|
pub fn[W] SubApp::add_schedule(
  self : SubApp[W],
  schedule : Schedule,
) -> SubApp[W] {
  schedule_replace_entry(self.schedule, schedule)
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
    run_conditions_ref.val.run_ifs.push(fn(world : W, _state : Ref[Json]) {
      cond(world)
    })
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
