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
pub fn[T : ToJson] World::send_event(
  self : World,
  key : EventKey[T],
  event : T,
) -> Unit {
  let queue = self.current_events.get_or_init(key.id(), fn() { [] })
  queue.push(event.to_json())
}

///|
pub fn[T : @json.FromJson] World::read_events(
  self : World,
  key : EventKey[T],
) -> Array[T] raise EcsError {
  let out : Array[T] = []

  if self.previous_events.get(key.id()) is Some(queue) {
    for i in 0..<queue.length() {
      out.push(self.decode_event_payload(key, i, queue[i]))
    }
  }

  let offset = out.length()
  if self.current_events.get(key.id()) is Some(queue) {
    for i in 0..<queue.length() {
      out.push(self.decode_event_payload(key, offset + i, queue[i]))
    }
  }

  out
}

///|
pub fn[T] World::clear_events(self : World, key : EventKey[T]) -> Unit {
  self.previous_events.remove(key.id())
  self.current_events.remove(key.id())
}

///|
pub fn World::advance_event_frame(self : World) -> Unit {
  self.previous_events = self.current_events.copy()
  self.current_events.clear()
}

///|
fn[T : @json.FromJson] World::decode_event_payload(
  _self : World,
  key : EventKey[T],
  index : Int,
  payload : Json,
) -> T raise EcsError {
  @json.from_json(payload) catch {
    err => raise EventDecodeFailed(key.id(), key.debug_name(), index, err)
  }
}
