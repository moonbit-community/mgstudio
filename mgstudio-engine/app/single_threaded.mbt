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
priv struct SingleThreadedExecutorState {
  evaluated_sets : Array[Bool]
  completed_systems : Array[Bool]
  unapplied_systems : Array[Bool]
  mut apply_final_deferred : Bool
}

///|
fn single_threaded_executor_state_new(
  system_count : Int,
  set_count : Int,
  apply_final_deferred : Bool,
) -> SingleThreadedExecutorState {
  let state = {
    evaluated_sets: [],
    completed_systems: [],
    unapplied_systems: [],
    apply_final_deferred,
  }
  state.init(system_count, set_count, apply_final_deferred)
  state
}

///|
fn single_threaded_resize_bool_array(
  values : Array[Bool],
  len : Int,
  clear : Bool,
) -> Unit {
  while values.length() < len {
    values.push(false)
  }
  while values.length() > len {
    values.pop().unwrap() |> ignore
  }
  if clear {
    for i in 0..<values.length() {
      values[i] = false
    }
  }
}

///|
fn SingleThreadedExecutorState::init(
  self : SingleThreadedExecutorState,
  system_count : Int,
  set_count : Int,
  apply_final_deferred : Bool,
) -> Unit {
  single_threaded_resize_bool_array(self.evaluated_sets, set_count, true)
  single_threaded_resize_bool_array(self.completed_systems, system_count, true)
  single_threaded_resize_bool_array(self.unapplied_systems, system_count, true)
  self.apply_final_deferred = apply_final_deferred
}

///|
fn SingleThreadedExecutorState::prepare_run(
  self : SingleThreadedExecutorState,
  system_count : Int,
  set_count : Int,
  apply_final_deferred : Bool,
) -> Unit {
  single_threaded_resize_bool_array(self.evaluated_sets, set_count, true)
  single_threaded_resize_bool_array(self.completed_systems, system_count, true)
  if self.unapplied_systems.length() != system_count {
    single_threaded_resize_bool_array(self.unapplied_systems, system_count, true)
  }
  self.apply_final_deferred = apply_final_deferred
}

///|
fn SingleThreadedExecutorState::clear_run_state(
  self : SingleThreadedExecutorState,
) -> Unit {
  for i in 0..<self.evaluated_sets.length() {
    self.evaluated_sets[i] = false
  }
  for i in 0..<self.completed_systems.length() {
    self.completed_systems[i] = false
  }
}

///|
fn SingleThreadedExecutorState::mark_completed(
  self : SingleThreadedExecutorState,
  system_i : Int,
) -> Unit {
  if system_i >= 0 && system_i < self.completed_systems.length() {
    self.completed_systems[system_i] = true
  }
}

///|
fn SingleThreadedExecutorState::is_completed(
  self : SingleThreadedExecutorState,
  system_i : Int,
) -> Bool {
  system_i >= 0 &&
  system_i < self.completed_systems.length() &&
  self.completed_systems[system_i]
}

///|
fn SingleThreadedExecutorState::mark_unapplied(
  self : SingleThreadedExecutorState,
  system_i : Int,
) -> Unit {
  if system_i >= 0 && system_i < self.unapplied_systems.length() {
    self.unapplied_systems[system_i] = true
  }
}

///|
fn SingleThreadedExecutorState::apply_deferred(
  self : SingleThreadedExecutorState,
  world : @ecs.World,
  restart_batch? : Bool = true,
) -> Unit {
  let mut has_unapplied = false
  for unapplied in self.unapplied_systems {
    if unapplied {
      has_unapplied = true
      break
    }
  }
  if has_unapplied || deferred_command_batch_has_entries() {
    end_deferred_command_batch(world)
  }
  for i in 0..<self.unapplied_systems.length() {
    self.unapplied_systems[i] = false
  }
  if restart_batch {
    begin_deferred_command_batch()
  }
}
