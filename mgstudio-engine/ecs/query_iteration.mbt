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
priv struct WorldQueryIterationState {
  mut active_count : Int
}

///|
fn world_query_iteration_state_new() -> WorldQueryIterationState {
  { active_count: 0 }
}

///|
fn WorldQueryIterationState::begin(self : WorldQueryIterationState) -> Unit {
  self.active_count = self.active_count + 1
}

///|
fn WorldQueryIterationState::end(self : WorldQueryIterationState) -> Unit {
  self.active_count = self.active_count - 1
}

///|
fn WorldQueryIterationState::has_active_iteration(
  self : WorldQueryIterationState,
) -> Bool {
  self.active_count > 0
}

///|
fn World::begin_query_iteration(self : World) -> Unit {
  self.query_iterations.begin()
}

///|
fn World::end_query_iteration(self : World) -> Unit {
  self.query_iterations.end()
}

///|
fn World::has_active_query_iteration(self : World) -> Bool {
  self.query_iterations.has_active_iteration()
}

///|
fn World::ensure_query_iteration_can_change_structure(
  self : World,
  operation : String,
) -> Unit raise EcsError {
  if self.has_active_query_iteration() {
    raise StructuralChangeDuringQueryIteration(operation)
  }
}

///|
fn World::abort_if_query_iteration_would_be_invalidated(
  self : World,
  operation : String,
) -> Unit {
  if self.has_active_query_iteration() {
    abort(
      "Structural ECS change during Query::view is not allowed: \{operation}",
    )
  }
}
