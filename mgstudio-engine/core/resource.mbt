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
/// Resource container with change detection.

///|
pub struct Resource[T] {
  mut cell : Ref[T]?
  ticks : ComponentTicks
}

///|
pub fn[T] Resource::new() -> Resource[T] {
  { cell: None, ticks: ComponentTicks::new(0) }
}

///|
pub fn[T] Resource::is_present(self : Resource[T]) -> Bool {
  self.cell is Some(_)
}

///|
pub fn[T] Resource::insert(
  self : Resource[T],
  value : T,
  change_tick : Tick,
) -> Unit {
  self.cell = Some(Ref::new(value))
  self.ticks.added = change_tick
  self.ticks.changed = change_tick
}

///|
pub fn[T] Resource::remove(self : Resource[T]) -> T? {
  match self.cell {
    None => None
    Some(r) => {
      self.cell = None
      Some(r.val)
    }
  }
}

///|
pub fn[T] Resource::get(self : Resource[T]) -> T? {
  match self.cell {
    None => None
    Some(r) => Some(r.val)
  }
}

///|
pub fn[T] Resource::get_ref(self : Resource[T]) -> Ref[T]? {
  self.cell
}

///|
pub fn[T] Resource::get_ref_mut(
  self : Resource[T],
  change_tick : Tick,
) -> Ref[T]? {
  match self.cell {
    None => None
    Some(r) => {
      self.ticks.set_changed(change_tick)
      Some(r)
    }
  }
}

///|
pub fn[T] Resource::ticks(self : Resource[T]) -> ComponentTicks {
  self.ticks
}
