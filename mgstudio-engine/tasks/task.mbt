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

// Bevy source: `bevy/crates/bevy_tasks/src/task.rs`.

///|
pub struct Task[T] {
  value : T?
  detached : Bool
}

///|
pub fn[T] Task::ready(value : T) -> Task[T] {
  { value: Some(value), detached: false }
}

///|
pub fn[T] Task::poll(self : Task[T]) -> T? {
  self.value
}

///|
pub fn[T] Task::detach(self : Task[T]) -> Task[T] {
  Task::{ ..self, detached: true }
}

///|
pub fn[T] Task::cancel(self : Task[T]) -> T? {
  self.value
}

///|
pub fn[T] Task::is_finished(self : Task[T]) -> Bool {
  self.value is Some(_)
}
