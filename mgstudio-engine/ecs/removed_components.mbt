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
pub struct RemovedComponents[T] {
  reader : @core.MessageReader[@core.Entity]
  marker : T?
}

///|
pub fn[T] RemovedComponents::read(
  self : RemovedComponents[T],
) -> Array[@core.Entity] {
  self.reader.read()
}

///|
pub fn[T] RemovedComponents::len(self : RemovedComponents[T]) -> Int {
  self.reader.len()
}

///|
pub fn[T] RemovedComponents::is_empty(self : RemovedComponents[T]) -> Bool {
  self.reader.is_empty()
}

///|
pub fn[T] RemovedComponents::clear(self : RemovedComponents[T]) -> Unit {
  self.reader.clear()
}

///|
pub fn[T] World::removed_components(
  self : World,
  key : ComponentKey[T],
  system : @core.SystemSequence,
) -> RemovedComponents[T] {
  let reader = match self.removed_component_messages(key.id()) {
    Some(messages_ref) => messages_ref.val.reader(system)
    None => @core.Messages::new().reader(system)
  }
  RemovedComponents::{ reader, marker: None }
}
