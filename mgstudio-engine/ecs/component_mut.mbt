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
pub struct ComponentMut[T] {
  value_ref : Ref[T]
  ticks : @core.ComponentTicks
  system : @core.SystemTicks
  original_payload : Json
  mut force_changed : Bool
}

///|
pub fn[T] ComponentMut::get(self : ComponentMut[T]) -> T {
  self.value_ref.val
}

///|
pub fn[T] ComponentMut::get_ref(self : ComponentMut[T]) -> Ref[T] {
  self.value_ref
}

///|
pub fn[T] ComponentMut::ticks(self : ComponentMut[T]) -> @core.ComponentTicks {
  self.ticks
}

///|
pub fn[T] ComponentMut::is_added(self : ComponentMut[T]) -> Bool {
  self.ticks.is_added(self.system)
}

///|
pub fn[T] ComponentMut::is_changed(self : ComponentMut[T]) -> Bool {
  self.ticks.is_changed(self.system)
}

///|
pub fn[T] ComponentMut::set_changed(self : ComponentMut[T]) -> Unit {
  self.force_changed = true
}
