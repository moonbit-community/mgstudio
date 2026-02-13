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
pub struct Messages[T] {
  mut previous_tick : Tick?
  mut previous_messages : Array[T]
  mut current_tick : Tick?
  mut current_messages : Array[T]
}

///|
pub struct MessageReader[T] {
  previous_tick : Tick?
  previous_messages : Array[T]
  current_tick : Tick?
  current_messages : Array[T]
  system : SystemTicks
  mut has_read : Bool
}

///|
pub(open) trait Message {
  reader(SystemTicks) -> MessageReader[Self]
}

///|
pub fn[T] Messages::new() -> Messages[T] {
  Messages::{
    previous_tick: None,
    previous_messages: [],
    current_tick: None,
    current_messages: [],
  }
}

///|
fn message_tick_in_range(tick : Tick, system : SystemTicks) -> Bool {
  let last_run = system.last_run
  let this_run = system.this_run
  if this_run >= last_run {
    tick > last_run && tick <= this_run
  } else {
    tick > last_run || tick <= this_run
  }
}

///|
pub fn[T] Messages::send(self : Messages[T], tick : Tick, message : T) -> Unit {
  if self.current_tick is Some(current_tick) {
    if current_tick != tick {
      self.previous_tick = Some(current_tick)
      self.previous_messages = self.current_messages
      self.current_tick = Some(tick)
      self.current_messages = []
    }
  } else {
    self.current_tick = Some(tick)
  }
  self.current_messages.push(message)
}

///|
pub fn[T] Messages::reader(
  self : Messages[T],
  system : SystemTicks,
) -> MessageReader[T] {
  MessageReader::{
    previous_tick: self.previous_tick,
    previous_messages: self.previous_messages.copy(),
    current_tick: self.current_tick,
    current_messages: self.current_messages.copy(),
    system,
    has_read: false,
  }
}

///|
pub fn[T] Messages::clear(self : Messages[T]) -> Unit {
  self.previous_tick = None
  self.previous_messages.clear()
  self.current_tick = None
  self.current_messages.clear()
}

///|
pub fn[T] MessageReader::read(self : MessageReader[T]) -> Array[T] {
  if self.has_read {
    return []
  }
  self.has_read = true
  let out : Array[T] = []
  if self.previous_tick is Some(tick) &&
    message_tick_in_range(tick, self.system) {
    for message in self.previous_messages {
      out.push(message)
    }
  }
  if self.current_tick is Some(tick) && message_tick_in_range(tick, self.system) {
    for message in self.current_messages {
      out.push(message)
    }
  }
  out
}
