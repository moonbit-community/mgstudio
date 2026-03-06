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
pub struct MessageKey[T] {
  queue_key : ResourceKey[MessageQueueState]
  marker : T?
}

///|
pub fn[T] MessageKey::id(self : MessageKey[T]) -> Int {
  self.queue_key.id()
}

///|
pub fn[T] MessageKey::debug_name(self : MessageKey[T]) -> String {
  self.queue_key.debug_name()
}

///|
fn[T] MessageKey::queue_key(
  self : MessageKey[T],
) -> ResourceKey[MessageQueueState] {
  self.queue_key
}

///|
pub fn[T] register_message(debug_name? : String = "") -> MessageKey[T] {
  MessageKey::{ queue_key: register_resource(debug_name~), marker: None }
}

///|
pub(open) trait Message: ToJson + @json.FromJson {
  message() -> MessageKey[Self]
}

///|
pub struct MessageQueueState {
  mut messages_a_start : Int
  mut messages_a : Array[Json]
  mut messages_b_start : Int
  mut messages_b : Array[Json]
  mut message_count : Int
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn MessageQueueState::new() -> MessageQueueState {
  {
    messages_a_start: 0,
    messages_a: [],
    messages_b_start: 0,
    messages_b: [],
    message_count: 0,
  }
}

///|
pub fn MessageQueueState::len(self : MessageQueueState) -> Int {
  self.messages_a.length() + self.messages_b.length()
}

///|
pub fn MessageQueueState::oldest_message_count(self : MessageQueueState) -> Int {
  self.messages_a_start
}

///|
pub fn MessageQueueState::write_json(
  self : MessageQueueState,
  payload : Json,
) -> Int {
  let message_id = self.message_count
  self.messages_b.push(payload)
  self.message_count = self.message_count + 1
  message_id
}

///|
pub fn MessageQueueState::write_json_batch(
  self : MessageQueueState,
  payloads : Array[Json],
) -> Unit {
  for payload in payloads {
    ignore(self.write_json(payload))
  }
}

///|
pub fn MessageQueueState::update(self : MessageQueueState) -> Unit {
  let drained_messages = self.messages_b
  let drained_start = self.messages_b_start
  self.messages_b = []
  self.messages_b_start = self.message_count
  self.messages_a = drained_messages
  self.messages_a_start = drained_start
}

///|
pub fn MessageQueueState::clear(self : MessageQueueState) -> Unit {
  self.messages_a.clear()
  self.messages_b.clear()
  self.messages_a_start = self.message_count
  self.messages_b_start = self.message_count
}

///|
fn queue_start_offset(start : Int, last_message_count : Int) -> Int {
  if last_message_count <= start {
    0
  } else {
    last_message_count - start
  }
}

///|
fn queue_unread_len_for_segment(
  start : Int,
  values : Array[Json],
  last_message_count : Int,
) -> Int {
  if last_message_count >= start + values.length() {
    return 0
  }
  let offset = queue_start_offset(start, last_message_count)
  values.length() - offset
}

///|
fn MessageQueueState::unread_len(
  self : MessageQueueState,
  last_message_count : Int,
) -> Int {
  queue_unread_len_for_segment(
    self.messages_a_start,
    self.messages_a,
    last_message_count,
  ) +
  queue_unread_len_for_segment(
    self.messages_b_start,
    self.messages_b,
    last_message_count,
  )
}

///|
fn MessageQueueState::unread_json(
  self : MessageQueueState,
  last_message_count : Int,
) -> Array[(Int, Json)] {
  let unread : Array[(Int, Json)] = []
  if last_message_count < self.messages_a_start + self.messages_a.length() {
    let offset = queue_start_offset(self.messages_a_start, last_message_count)
    for i in offset..<self.messages_a.length() {
      unread.push((self.messages_a_start + i, self.messages_a[i]))
    }
  }
  if last_message_count < self.messages_b_start + self.messages_b.length() {
    let offset = queue_start_offset(self.messages_b_start, last_message_count)
    for i in offset..<self.messages_b.length() {
      unread.push((self.messages_b_start + i, self.messages_b[i]))
    }
  }
  unread
}

///|
priv struct MessageRegistryState {
  ids : Array[Int]
} derive(ToJson, FromJson)

///|
fn message_registry_resource_key() -> ResourceKey[MessageRegistryState] {
  register_resource(debug_name="bevy_ecs::message::MessageRegistry")
}

///|
fn world_message_registry(world : World) -> MessageRegistryState {
  match world.resource(message_registry_resource_key()).get() {
    Some(registry) => registry
    None => MessageRegistryState::{ ids: [] }
  }
}

///|
fn world_write_message_registry(
  world : World,
  registry : MessageRegistryState,
) -> Unit {
  world.insert_resource(message_registry_resource_key(), registry)
}

///|
fn[T] queue_missing_abort(key : MessageKey[T]) -> Unit {
  abort(
    "Unable to access message `" +
    key.debug_name() +
    "`\n\tMessages must be added to the app with `add_message()`",
  )
}

///|
pub fn[T] World::contains_message(self : World, key : MessageKey[T]) -> Bool {
  self.resource(key.queue_key()).is_present()
}

///|
pub fn[T] World::init_message(self : World, key : MessageKey[T]) -> Unit {
  if !self.contains_message(key) {
    self.insert_resource(key.queue_key(), MessageQueueState::new())
  }
  let registry = world_message_registry(self)
  for existing_id in registry.ids {
    if existing_id == key.id() {
      return
    }
  }
  registry.ids.push(key.id())
  world_write_message_registry(self, registry)
}

///|
pub fn[T : ToJson] World::send_message(
  self : World,
  key : MessageKey[T],
  message : T,
) -> Int {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  let access = self.resource(key.queue_key())
  let queue = access.get().unwrap_or(MessageQueueState::new())
  let message_id = queue.write_json(message.to_json())
  ignore(access.set(queue, self.read_change_tick()))
  message_id
}

///|
pub fn[T : ToJson] World::send_message_batch(
  self : World,
  key : MessageKey[T],
  messages : Array[T],
) -> Unit {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  let access = self.resource(key.queue_key())
  let queue = access.get().unwrap_or(MessageQueueState::new())
  let payloads : Array[Json] = []
  for message in messages {
    payloads.push(message.to_json())
  }
  queue.write_json_batch(payloads)
  ignore(access.set(queue, self.read_change_tick()))
}

///|
pub fn[T] World::clear_messages(self : World, key : MessageKey[T]) -> Unit {
  guard self.resource(key.queue_key()).get() is Some(queue) else { return }
  queue.clear()
  self.resource(key.queue_key()).set(queue, self.read_change_tick()) |> ignore
}

///|
pub fn World::update_messages(self : World) -> Unit {
  let registry = world_message_registry(self)
  for id in registry.ids {
    let key : ResourceKey[MessageQueueState] = resource_key_from_id(
      id,
      debug_name="bevy_ecs::message::Messages",
    )
    let access = self.resource(key)
    guard access.get() is Some(queue) else { continue }
    queue.update()
    access.set(queue, self.read_change_tick()) |> ignore
  }
}

///|
pub struct MessageReader[T] {
  world : World
  key : MessageKey[T]
  cursor_ref : Ref[Int]
}

///|
pub struct MessageWriter[T] {
  world : World
  key : MessageKey[T]
}

///|
fn[T : @json.FromJson] decode_message_payload(
  key : MessageKey[T],
  index : Int,
  payload : Json,
) -> T raise EcsError {
  @json.from_json(payload) catch {
    err => raise MessageDecodeFailed(key.id(), key.debug_name(), index, err)
  }
}

///|
pub fn[T] World::message_reader(
  self : World,
  key : MessageKey[T],
  cursor_ref : Ref[Int],
) -> MessageReader[T] {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  MessageReader::{ world: self, key, cursor_ref }
}

///|
pub fn[T] World::message_writer(
  self : World,
  key : MessageKey[T],
) -> MessageWriter[T] {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  MessageWriter::{ world: self, key }
}

///|
pub fn[T] MessageReader::len(self : MessageReader[T]) -> Int {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => queue.unread_len(self.cursor_ref.val)
    None => 0
  }
}

///|
pub fn[T] MessageReader::is_empty(self : MessageReader[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] MessageReader::clear(self : MessageReader[T]) -> Unit {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor_ref.val = queue.message_count
    None => self.cursor_ref.val = 0
  }
}

///|
pub fn[T] MessageReader::cursor(self : MessageReader[T]) -> Int {
  self.cursor_ref.val
}

///|
pub fn[T : @json.FromJson] MessageReader::read(
  self : MessageReader[T],
) -> Array[T] raise EcsError {
  let queue_access = self.world.resource(self.key.queue_key())
  let queue = queue_access.get().unwrap_or(MessageQueueState::new())
  let unread_json = queue.unread_json(self.cursor_ref.val)
  let unread : Array[T] = []
  for entry in unread_json {
    unread.push(decode_message_payload(self.key, entry.0, entry.1))
  }
  self.cursor_ref.val = queue.message_count
  unread
}

///|
pub fn[T : ToJson] MessageWriter::write(
  self : MessageWriter[T],
  message : T,
) -> Int {
  self.world.send_message(self.key, message)
}

///|
pub fn[T : ToJson] MessageWriter::write_batch(
  self : MessageWriter[T],
  messages : Array[T],
) -> Unit {
  self.world.send_message_batch(self.key, messages)
}
