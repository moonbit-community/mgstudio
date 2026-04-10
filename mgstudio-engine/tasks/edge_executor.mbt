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

// Bevy source: `bevy/crates/bevy_tasks/src/edge_executor.rs`.

///|
pub const EDGE_EXECUTOR_BACKEND : String = "edge_executor"

///|
pub struct EdgeExecutor {}

///|
pub fn EdgeExecutor::new() -> EdgeExecutor {
  EdgeExecutor::{  }
}

///|
pub fn EdgeExecutor::tick(self : EdgeExecutor) -> Unit {
  ignore(self)
}

///|
pub fn EdgeExecutor::run_once(self : EdgeExecutor) -> Unit {
  self.tick()
}
