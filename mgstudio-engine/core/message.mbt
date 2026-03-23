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
  mut previous_tick : Sequence?
  mut previous_messages : Array[T]
  mut current_tick : Sequence?
  mut current_messages : Array[T]
}

///|
pub struct MessageReader[T] {
  previous_tick : Sequence?
  previous_messages : Array[T]
  current_tick : Sequence?
  current_messages : Array[T]
  system : SystemSequence
  mut has_read : Bool
}

///|
pub struct MessageWriter[T] {
  messages : Messages[T]
  tick : Sequence
}

///|
pub(open) trait Message {
  reader(SystemSequence) -> MessageReader[Self]
  writer(Sequence) -> MessageWriter[Self]
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
fn message_tick_in_range(tick : Sequence, system : SystemSequence) -> Bool {
  let last_run = system.last_run
  let this_run = system.this_run
  if this_run >= last_run {
    tick > last_run && tick <= this_run
  } else {
    tick > last_run || tick <= this_run
  }
}

///|
pub fn[T] Messages::send(
  self : Messages[T],
  tick : Sequence,
  message : T,
) -> Unit {
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
pub fn[T] Messages::send_batch(
  self : Messages[T],
  tick : Sequence,
  messages : Array[T],
) -> Unit {
  for message in messages {
    self.send(tick, message)
  }
}

///|
pub fn[T] Messages::reader(
  self : Messages[T],
  system : SystemSequence,
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
pub fn[T] Messages::writer(
  self : Messages[T],
  tick : Sequence,
) -> MessageWriter[T] {
  MessageWriter::{ messages: self, tick }
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

///|
pub fn[T] MessageReader::len(self : MessageReader[T]) -> Int {
  if self.has_read {
    return 0
  }
  let mut total = 0
  if self.previous_tick is Some(tick) &&
    message_tick_in_range(tick, self.system) {
    total = total + self.previous_messages.length()
  }
  if self.current_tick is Some(tick) && message_tick_in_range(tick, self.system) {
    total = total + self.current_messages.length()
  }
  total
}

///|
pub fn[T] MessageReader::is_empty(self : MessageReader[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] MessageReader::clear(self : MessageReader[T]) -> Unit {
  self.has_read = true
}

///|
pub fn[T] MessageWriter::write(self : MessageWriter[T], message : T) -> Unit {
  self.messages.send(self.tick, message)
}

///|
pub fn[T] MessageWriter::write_batch(
  self : MessageWriter[T],
  messages : Array[T],
) -> Unit {
  self.messages.send_batch(self.tick, messages)
}
