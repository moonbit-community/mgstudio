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
  mut previous_sequence : Sequence?
  mut previous_messages : Array[T]
  mut current_sequence : Sequence?
  mut current_messages : Array[T]
}

///|
pub struct MessageReader[T] {
  previous_sequence : Sequence?
  previous_messages : Array[T]
  current_sequence : Sequence?
  current_messages : Array[T]
  system : SystemSequence
  mut has_read : Bool
}

///|
pub struct MessageWriter[T] {
  messages : Messages[T]
  sequence : Sequence
}

///|
pub(open) trait Message {
  reader(SystemSequence) -> MessageReader[Self]
  writer(Sequence) -> MessageWriter[Self]
}

///|
pub fn[T] Messages::new() -> Messages[T] {
  Messages::{
    previous_sequence: None,
    previous_messages: [],
    current_sequence: None,
    current_messages: [],
  }
}

///|
fn message_sequence_in_range(
  sequence : Sequence,
  system : SystemSequence,
) -> Bool {
  let last_run = system.last_run
  let this_run = system.this_run
  if this_run >= last_run {
    sequence > last_run && sequence <= this_run
  } else {
    sequence > last_run || sequence <= this_run
  }
}

///|
pub fn[T] Messages::send(
  self : Messages[T],
  sequence : Sequence,
  message : T,
) -> Unit {
  if self.current_sequence is Some(current_sequence) {
    if current_sequence != sequence {
      self.previous_sequence = Some(current_sequence)
      self.previous_messages = self.current_messages
      self.current_sequence = Some(sequence)
      self.current_messages = []
    }
  } else {
    self.current_sequence = Some(sequence)
  }
  self.current_messages.push(message)
}

///|
pub fn[T] Messages::send_batch(
  self : Messages[T],
  sequence : Sequence,
  messages : Array[T],
) -> Unit {
  for message in messages {
    self.send(sequence, message)
  }
}

///|
pub fn[T] Messages::reader(
  self : Messages[T],
  system : SystemSequence,
) -> MessageReader[T] {
  let previous_messages = if self.previous_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, system) {
    self.previous_messages.copy()
  } else {
    []
  }
  let current_messages = if self.current_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, system) {
    self.current_messages.copy()
  } else {
    []
  }
  MessageReader::{
    previous_sequence: self.previous_sequence,
    previous_messages,
    current_sequence: self.current_sequence,
    current_messages,
    system,
    has_read: false,
  }
}

///|
pub fn[T] Messages::clear(self : Messages[T]) -> Unit {
  self.previous_sequence = None
  self.previous_messages.clear()
  self.current_sequence = None
  self.current_messages.clear()
}

///|
pub fn[T] Messages::writer(
  self : Messages[T],
  sequence : Sequence,
) -> MessageWriter[T] {
  MessageWriter::{ messages: self, sequence }
}

///|
pub fn[T] MessageReader::read(self : MessageReader[T]) -> Array[T] {
  if self.has_read {
    return []
  }
  self.has_read = true
  let out : Array[T] = []
  if self.previous_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, self.system) {
    for message in self.previous_messages {
      out.push(message)
    }
  }
  if self.current_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, self.system) {
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
  if self.previous_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, self.system) {
    total = total + self.previous_messages.length()
  }
  if self.current_sequence is Some(sequence) &&
    message_sequence_in_range(sequence, self.system) {
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
  self.messages.send(self.sequence, message)
}

///|
pub fn[T] MessageWriter::write_batch(
  self : MessageWriter[T],
  messages : Array[T],
) -> Unit {
  self.messages.send_batch(self.sequence, messages)
}
