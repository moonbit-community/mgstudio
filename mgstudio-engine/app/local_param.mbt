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
  from_world(@ecs.World) -> Self
}

///|
pub struct Local[T] {
  value_ref : Ref[T]
}

///|
pub fn[T] Local::get(self : Local[T]) -> T {
  self.value_ref.val
}

///|
pub fn[T] Local::get_ref(self : Local[T]) -> Ref[T] {
  self.value_ref
}

///|
pub fn[T] Local::set(self : Local[T], value : T) -> Unit {
  self.value_ref.val = value
}

///|
pub impl FromWorld for Bool with from_world(_world) {
  false
}

///|
pub impl[T] FromWorld for Array[T] with from_world(_world) {
  []
}

///|
fn[T : @json.FromJson] local_param_decode_state(state : Ref[Json]) -> T {
  try @json.from_json(state.val) catch {
    _ => abort("Failed to decode Local system parameter state")
  } noraise {
    value => value
  }
}

///|
pub impl[T : FromWorld + ToJson + @json.FromJson] SystemParam for Local[T] with init_state(
  world,
) {
  T::from_world(world).to_json()
}

///|
pub impl[T : FromWorld + ToJson + @json.FromJson] SystemParam for Local[T] with get(
  state,
) {
  Local::{ value_ref: Ref::new(local_param_decode_state(state)) }
}

///|
pub impl[T : FromWorld + ToJson + @json.FromJson] SystemParam for Local[T] with store(
  self,
  state,
) {
  state.val = self.value_ref.val.to_json()
}
