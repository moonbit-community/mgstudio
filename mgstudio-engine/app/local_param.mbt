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
pub(open) trait FromWorld {
  fn from_world(@ecs.World) -> Self
}

///|
pub struct Local[T] {
  priv mut value : T
}

///|
pub fn[T] Local::get(self : Local[T]) -> T {
  self.value
}

///|
pub fn[T] Local::set(self : Local[T], value : T) -> Unit {
  self.value = value
}

///|
pub impl FromWorld for Bool with fn from_world(_world) {
  false
}

///|
pub impl FromWorld for Int with fn from_world(_world) {
  0
}

///|
pub impl FromWorld for Float with fn from_world(_world) {
  0.0F
}

///|
pub impl FromWorld for String with fn from_world(_world) {
  ""
}

///|
pub impl[T] FromWorld for Array[T] with fn from_world(_world) {
  []
}

///|
pub impl[T : FromWorld] SystemParam for Local[T] with fn init_state(world) {
  let mut value = T::from_world(world)
  SystemParamState::new(fn() { { value, } }, fn(local_value : Local[T]) {
    value = local_value.value
  })
}

///|
pub impl[T : FromWorld] SystemParam for Local[T] with fn get(state) {
  state.get()
}

///|
pub impl[T : FromWorld] SystemParam for Local[T] with fn store(self, state) {
  state.store(self)
}

///|
pub impl[T : FromWorld] SystemParam for Local[T] with fn access(_world) {
  SystemAccess::new()
}
