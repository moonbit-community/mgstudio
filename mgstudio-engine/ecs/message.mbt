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
  priv id : Int
  priv debug_name : String
  priv queue_key : ResourceKey[Messages[T]]
}

///|
pub fn[T] MessageKey::id(self : MessageKey[T]) -> Int {
  self.id
}

///|
pub fn[T] MessageKey::debug_name(self : MessageKey[T]) -> String {
  self.debug_name
}

///|
fn[T] MessageKey::queue_key(self : MessageKey[T]) -> ResourceKey[Messages[T]] {
  self.queue_key
}

///|
priv struct MessageUpdateOp {
  update : (World) -> Unit
}

///|
let message_update_ops : @hashmap.HashMap[Int, MessageUpdateOp] = @hashmap.HashMap([],
)

///|
fn[T] register_message_update_op(key : MessageKey[T]) -> Unit {
  if message_update_ops.contains(key.id()) {
    return
  }
  message_update_ops.set(key.id(), {
    update: fn(world) {
      let access = world.resource(key.queue_key())
      guard access.get() is Some(queue) else { return }
      queue.update()
      access.set(queue) |> ignore
    },
  })
}

///|
fn[T] message_queue_resource_key(
  id : Int,
  debug_name : String,
) -> ResourceKey[Messages[T]] {
  ResourceKey::{ id, debug_name, access: resource_access_ops_new() }
}

///|
fn[T] message_key_new(id : Int, debug_name : String) -> MessageKey[T] {
  let key = MessageKey::{
    id,
    debug_name,
    queue_key: message_queue_resource_key(id, debug_name),
  }
  register_message_update_op(key)
  key
}

///|
pub fn[T] register_message(debug_name? : String = "") -> MessageKey[T] {
  let id = allocate_resource_id(debug_name~)
  message_key_new(id, debug_name)
}

///|
pub(open) trait Message {
  fn message() -> MessageKey[Self]
}

///|
pub struct MessageCursor[_] {
  priv mut last_message_count : Int
}

///|
pub struct MessageQueueState[T] {
  priv mut messages_a_start : Int
  priv mut messages_a : Array[T]
  priv mut messages_b_start : Int
  priv mut messages_b : Array[T]
  priv mut message_count : Int
}

///|
pub struct Messages[T] {
  priv state : MessageQueueState[T]
}

///|
pub fn[T] MessageQueueState::new() -> MessageQueueState[T] {
  {
    messages_a_start: 0,
    messages_a: [],
    messages_b_start: 0,
    messages_b: [],
    message_count: 0,
  }
}

///|
pub fn[T] MessageQueueState::len(self : MessageQueueState[T]) -> Int {
  self.messages_a.length() + self.messages_b.length()
}

///|
pub fn[T] MessageQueueState::oldest_message_count(
  self : MessageQueueState[T],
) -> Int {
  self.messages_a_start
}

///|
pub fn[T] MessageQueueState::write(
  self : MessageQueueState[T],
  message : T,
) -> Int {
  let message_id = self.message_count
  self.messages_b.push(message)
  self.message_count = self.message_count + 1
  message_id
}

///|
pub fn[T] MessageQueueState::write_batch(
  self : MessageQueueState[T],
  messages : Array[T],
) -> Unit {
  for message in messages {
    ignore(self.write(message))
  }
}

///|
pub fn[T] MessageQueueState::update(self : MessageQueueState[T]) -> Unit {
  let drained_messages = self.messages_b
  let drained_start = self.messages_b_start
  self.messages_b = []
  self.messages_b_start = self.message_count
  self.messages_a = drained_messages
  self.messages_a_start = drained_start
}

///|
pub fn[T] MessageQueueState::clear(self : MessageQueueState[T]) -> Unit {
  self.messages_a.clear()
  self.messages_b.clear()
  self.messages_a_start = self.message_count
  self.messages_b_start = self.message_count
}

///|
pub fn[T] Messages::new() -> Messages[T] {
  { state: MessageQueueState::new() }
}

///|
pub fn[T] Messages::len(self : Messages[T]) -> Int {
  self.state.len()
}

///|
pub fn[T] Messages::oldest_message_count(self : Messages[T]) -> Int {
  self.state.oldest_message_count()
}

///|
pub fn[T] Messages::write(self : Messages[T], message : T) -> Int {
  self.state.write(message)
}

///|
pub fn[T] Messages::write_batch(
  self : Messages[T],
  messages : Array[T],
) -> Unit {
  self.state.write_batch(messages)
}

///|
pub fn[T : Default] Messages::write_default(self : Messages[T]) -> Int {
  self.write(T::default())
}

///|
pub fn[T] Messages::update(self : Messages[T]) -> Unit {
  self.state.update()
}

///|
pub fn[T] Messages::clear(self : Messages[T]) -> Unit {
  self.state.clear()
}

///|
pub fn[T] MessageCursor::MessageCursor() -> MessageCursor[T] {
  { last_message_count: 0 }
}

///|
pub impl[T] Default for MessageCursor[T] with fn default() {
  MessageCursor::MessageCursor()
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
fn[T] queue_unread_len_for_segment(
  start : Int,
  values : Array[T],
  last_message_count : Int,
) -> Int {
  if last_message_count >= start + values.length() {
    return 0
  }
  let offset = queue_start_offset(start, last_message_count)
  values.length() - offset
}

///|
fn[T] Messages::unread_len(self : Messages[T], last_message_count : Int) -> Int {
  queue_unread_len_for_segment(
    self.state.messages_a_start,
    self.state.messages_a,
    last_message_count,
  ) +
  queue_unread_len_for_segment(
    self.state.messages_b_start,
    self.state.messages_b,
    last_message_count,
  )
}

///|
fn[T] Messages::unread(
  self : Messages[T],
  last_message_count : Int,
) -> Array[(Int, T)] {
  let unread : Array[(Int, T)] = []
  if last_message_count <
    self.state.messages_a_start + self.state.messages_a.length() {
    let offset = queue_start_offset(
      self.state.messages_a_start,
      last_message_count,
    )
    for i in offset..<self.state.messages_a.length() {
      unread.push((self.state.messages_a_start + i, self.state.messages_a[i]))
    }
  }
  if last_message_count <
    self.state.messages_b_start + self.state.messages_b.length() {
    let offset = queue_start_offset(
      self.state.messages_b_start,
      last_message_count,
    )
    for i in offset..<self.state.messages_b.length() {
      unread.push((self.state.messages_b_start + i, self.state.messages_b[i]))
    }
  }
  unread
}

///|
fn[T] message_cursor_advance_after_unread(
  previous_count : Int,
  unread_values : Array[(Int, T)],
) -> Int {
  if unread_values.length() == 0 {
    previous_count
  } else {
    unread_values[unread_values.length() - 1].0 + 1
  }
}

///|
pub(all) struct MessageRegistryState {
  ids : Array[Int]
}

///|
let message_registry_resource_key : ResourceKey[MessageRegistryState] = register_resource(
  debug_name="mgstudio_ecs::message::MessageRegistry",
)

///|
fn world_message_registry(world : World) -> MessageRegistryState {
  match world.resource(message_registry_resource_key).get() {
    Some(registry) => registry
    None => MessageRegistryState::{ ids: [] }
  }
}

///|
fn world_write_message_registry(
  world : World,
  registry : MessageRegistryState,
) -> Unit {
  world.insert_resource(message_registry_resource_key, registry)
}

///|
fn[T] queue_missing_abort(key : MessageKey[T]) -> Unit {
  abort(
    "Unable to access message `\{key.debug_name()}`\n\tMessages must be added to the app with `add_message()`",
  )
}

///|
pub fn[T] MessageKey::messages_resource(
  self : MessageKey[T],
) -> ResourceKey[Messages[T]] {
  self.queue_key
}

///|
pub fn[T] World::contains_message(self : World, key : MessageKey[T]) -> Bool {
  self.resource(key.queue_key()).is_present()
}

///|
pub fn[T] World::init_message(self : World, key : MessageKey[T]) -> Unit {
  if !self.contains_message(key) {
    self.insert_resource(key.queue_key(), Messages::new())
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
pub fn[T] World::send_message(
  self : World,
  key : MessageKey[T],
  message : T,
) -> Int {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  let access = self.resource(key.queue_key())
  let queue = access.get().unwrap_or(Messages::new())
  let message_id = queue.write(message)
  ignore(access.set(queue))
  message_id
}

///|
pub fn[T] World::send_message_batch(
  self : World,
  key : MessageKey[T],
  messages : Array[T],
) -> Unit {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  let access = self.resource(key.queue_key())
  let queue = access.get().unwrap_or(Messages::new())
  queue.write_batch(messages)
  ignore(access.set(queue))
}

///|
pub fn[T] World::clear_messages(self : World, key : MessageKey[T]) -> Unit {
  guard self.resource(key.queue_key()).get() is Some(queue) else { return }
  queue.clear()
  self.resource(key.queue_key()).set(queue) |> ignore
}

///|
pub fn World::update_messages(self : World) -> Unit {
  let registry = world_message_registry(self)
  for id in registry.ids {
    guard message_update_ops.get(id) is Some(op) else { continue }
    (op.update)(self)
  }
}

///|
pub struct MessageReader[T] {
  priv world : World
  priv key : MessageKey[T]
  priv cursor : MessageCursor[T]
}

///|
pub struct MessageMutator[T] {
  priv world : World
  priv key : MessageKey[T]
  priv cursor : MessageCursor[T]
}

///|
pub struct MessageWriter[T] {
  priv world : World
  priv key : MessageKey[T]
}

///|
pub fn[T] Messages::get_cursor(self : Messages[T]) -> MessageCursor[T] {
  ignore(self)
  MessageCursor::MessageCursor()
}

///|
pub fn[T] Messages::get_cursor_current(self : Messages[T]) -> MessageCursor[T] {
  { last_message_count: self.state.message_count }
}

///|
pub fn[T] Messages::write_message(
  self : Messages[T],
  key : MessageKey[T],
  message : T,
) -> Int {
  ignore(key)
  self.write(message)
}

///|
pub fn[T] Messages::write_message_batch(
  self : Messages[T],
  key : MessageKey[T],
  messages : Array[T],
) -> Unit {
  ignore(key)
  self.write_batch(messages)
}

///|
pub fn[T : Default] Messages::write_message_default(
  self : Messages[T],
  key : MessageKey[T],
) -> Int {
  self.write_message(key, T::default())
}

///|
pub fn[T] MessageCursor::len(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Int {
  messages.unread_len(self.last_message_count)
}

///|
pub fn[T] MessageCursor::missed_messages(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Int {
  let oldest = messages.oldest_message_count()
  if oldest <= self.last_message_count {
    0
  } else {
    oldest - self.last_message_count
  }
}

///|
pub fn[T] MessageCursor::is_empty(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Bool {
  self.len(messages) == 0
}

///|
pub fn[T] MessageCursor::clear(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Unit {
  self.last_message_count = messages.state.message_count
}

///|
pub fn[T] MessageCursor::read(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Array[T] {
  let unread_values = messages.unread(self.last_message_count)
  let unread : Array[T] = []
  for entry in unread_values {
    unread.push(entry.1)
  }
  self.last_message_count = message_cursor_advance_after_unread(
    self.last_message_count,
    unread_values,
  )
  unread
}

///|
pub fn[T] MessageCursor::read_mut(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Array[T] {
  let unread_values = messages.unread(self.last_message_count)
  let unread : Array[T] = []
  for entry in unread_values {
    unread.push(entry.1)
  }
  self.last_message_count = message_cursor_advance_after_unread(
    self.last_message_count,
    unread_values,
  )
  unread
}

///|
pub fn[T] World::message_reader(
  self : World,
  key : MessageKey[T],
  cursor? : MessageCursor[T] = MessageCursor::MessageCursor(),
) -> MessageReader[T] {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  MessageReader::{ world: self, key, cursor }
}

///|
pub fn[T] World::message_mutator(
  self : World,
  key : MessageKey[T],
  cursor? : MessageCursor[T] = MessageCursor::MessageCursor(),
) -> MessageMutator[T] {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  MessageMutator::{ world: self, key, cursor }
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
    Some(queue) => self.cursor.len(queue)
    None => 0
  }
}

///|
pub fn[T] MessageMutator::len(self : MessageMutator[T]) -> Int {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor.len(queue)
    None => 0
  }
}

///|
pub fn[T] MessageReader::is_empty(self : MessageReader[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] MessageMutator::is_empty(self : MessageMutator[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] MessageReader::clear(self : MessageReader[T]) -> Unit {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor.clear(queue)
    None => self.cursor.last_message_count = 0
  }
}

///|
pub fn[T] MessageMutator::clear(self : MessageMutator[T]) -> Unit {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor.clear(queue)
    None => self.cursor.last_message_count = 0
  }
}

///|
pub fn[T] MessageReader::cursor(self : MessageReader[T]) -> MessageCursor[T] {
  self.cursor
}

///|
pub fn[T] MessageMutator::cursor(self : MessageMutator[T]) -> MessageCursor[T] {
  self.cursor
}

///|
pub fn[T] MessageReader::read(self : MessageReader[T]) -> Array[T] {
  let queue_access = self.world.resource(self.key.queue_key())
  let queue = queue_access.get().unwrap_or(Messages::new())
  self.cursor.read(queue)
}

///|
pub fn[T] MessageMutator::read(self : MessageMutator[T]) -> Array[T] {
  let queue_access = self.world.resource(self.key.queue_key())
  let queue = queue_access.get().unwrap_or(Messages::new())
  self.cursor.read_mut(queue)
}

///|
pub fn[T] MessageWriter::write(self : MessageWriter[T], message : T) -> Int {
  self.world.send_message(self.key, message)
}

///|
pub fn[T] MessageWriter::write_batch(
  self : MessageWriter[T],
  messages : Array[T],
) -> Unit {
  self.world.send_message_batch(self.key, messages)
}

///|
pub fn[T : Default] MessageWriter::write_default(
  self : MessageWriter[T],
) -> Int {
  self.write(T::default())
}
