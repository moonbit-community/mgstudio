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
  queue_key : ResourceKey[Messages[T]]
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
fn[T] MessageKey::queue_key(self : MessageKey[T]) -> ResourceKey[Messages[T]] {
  self.queue_key
}

///|
let named_message_queue_registry : @hashmap.HashMap[
  String,
  ResourceKey[Messages[Unit]],
] = @hashmap.HashMap::new()

///|
pub fn[T] register_message(debug_name? : String = "") -> MessageKey[T] {
  let queue_key : ResourceKey[Messages[T]] = if debug_name == "" {
    register_resource(debug_name~)
  } else {
    named_message_queue_registry
    .get_or_init(debug_name, fn() -> ResourceKey[Messages[Unit]] {
      register_resource(debug_name~)
    })
    .cast()
  }
  MessageKey::{ queue_key, marker: None }
}

///|
pub(open) trait Message {
  message() -> MessageKey[Self]
}

///|
pub struct MessageCursor[T] {
  mut last_message_count : Int
  marker : T?
}

///|
pub struct MessageQueueState {
  mut messages_a_start : Int
  mut messages_a : Array[ErasedValue]
  mut messages_b_start : Int
  mut messages_b : Array[ErasedValue]
  mut message_count : Int
}

///|
pub struct Messages[T] {
  state : MessageQueueState
  marker : T?
}

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
pub fn MessageQueueState::write(
  self : MessageQueueState,
  payload : ErasedValue,
) -> Int {
  let message_id = self.message_count
  self.messages_b.push(payload)
  self.message_count = self.message_count + 1
  message_id
}

///|
pub fn MessageQueueState::write_batch(
  self : MessageQueueState,
  payloads : Array[ErasedValue],
) -> Unit {
  for payload in payloads {
    ignore(self.write(payload))
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
pub fn[T] Messages::new() -> Messages[T] {
  { state: MessageQueueState::new(), marker: None }
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
  self.state.write(erased_value(message))
}

///|
pub fn[T] Messages::write_batch(
  self : Messages[T],
  messages : Array[T],
) -> Unit {
  let payloads : Array[ErasedValue] = []
  for message in messages {
    payloads.push(erased_value(message))
  }
  self.state.write_batch(payloads)
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
pub impl[T] Default for MessageCursor[T] with default() {
  { last_message_count: 0, marker: None }
}

///|
pub impl[T] ToJson for MessageCursor[T] with to_json(self) {
  self.last_message_count.to_json()
}

///|
pub impl[T] @json.FromJson for MessageCursor[T] with from_json(json, path) {
  let last_message_count : Int = @json.FromJson::from_json(json, path)
  { last_message_count, marker: None }
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
  values : Array[ErasedValue],
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
) -> Array[(Int, ErasedValue)] {
  let unread : Array[(Int, ErasedValue)] = []
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
priv struct MessageRegistryState {
  ids : Array[Int]
}

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
  ignore(access.set(queue, self.read_sequence()))
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
  ignore(access.set(queue, self.read_sequence()))
}

///|
pub fn[T] World::clear_messages(self : World, key : MessageKey[T]) -> Unit {
  guard self.resource(key.queue_key()).get() is Some(queue) else { return }
  queue.clear()
  self.resource(key.queue_key()).set(queue, self.read_sequence()) |> ignore
}

///|
pub fn World::update_messages(self : World) -> Unit {
  let registry = world_message_registry(self)
  for id in registry.ids {
    let key : ResourceKey[Messages[Unit]] = resource_key_from_id(
      id,
      debug_name="bevy_ecs::message::Messages",
    )
    let access = self.resource(key)
    guard access.get() is Some(queue) else { continue }
    queue.update()
    access.set(queue, self.read_sequence()) |> ignore
  }
}

///|
pub struct MessageReader[T] {
  world : World
  key : MessageKey[T]
  cursor_ref : Ref[Int]
}

///|
pub struct MessageMutator[T] {
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
fn[T] decode_message_payload(
  key : MessageKey[T],
  index : Int,
  payload : ErasedValue,
) -> T raise EcsError {
  payload.to_value() catch {
    _ =>
      raise MessageTypeMismatch(
        key.id(),
        key.debug_name(),
        index,
        payload.type_name(),
      )
  }
}

///|
fn[T] decode_message_ref(
  key : MessageKey[T],
  index : Int,
  payload : ErasedValue,
) -> Ref[T] raise EcsError {
  payload.to_ref() catch {
    _ =>
      raise MessageTypeMismatch(
        key.id(),
        key.debug_name(),
        index,
        payload.type_name(),
      )
  }
}

///|
pub fn[T] Messages::get_cursor(self : Messages[T]) -> MessageCursor[T] {
  ignore(self)
  MessageCursor::default()
}

///|
pub fn[T] Messages::get_cursor_current(self : Messages[T]) -> MessageCursor[T] {
  { last_message_count: self.state.message_count, marker: None }
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
pub fn[T : Message] MessageCursor::read(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Array[T] raise EcsError {
  let key : MessageKey[T] = Message::message()
  let unread_values = messages.unread(self.last_message_count)
  let unread : Array[T] = []
  for entry in unread_values {
    unread.push(decode_message_payload(key, entry.0, entry.1))
  }
  self.last_message_count = messages.state.message_count
  unread
}

///|
pub fn[T : Message] MessageCursor::read_mut(
  self : MessageCursor[T],
  messages : Messages[T],
) -> Array[Ref[T]] raise EcsError {
  let key : MessageKey[T] = Message::message()
  let unread_values = messages.unread(self.last_message_count)
  let unread : Array[Ref[T]] = []
  for entry in unread_values {
    unread.push(decode_message_ref(key, entry.0, entry.1))
  }
  self.last_message_count = messages.state.message_count
  unread
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
pub fn[T] World::message_mutator(
  self : World,
  key : MessageKey[T],
  cursor_ref : Ref[Int],
) -> MessageMutator[T] {
  if !self.contains_message(key) {
    queue_missing_abort(key)
  }
  MessageMutator::{ world: self, key, cursor_ref }
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
pub fn[T] MessageMutator::len(self : MessageMutator[T]) -> Int {
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
pub fn[T] MessageMutator::is_empty(self : MessageMutator[T]) -> Bool {
  self.len() == 0
}

///|
pub fn[T] MessageReader::clear(self : MessageReader[T]) -> Unit {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor_ref.val = queue.state.message_count
    None => self.cursor_ref.val = 0
  }
}

///|
pub fn[T] MessageMutator::clear(self : MessageMutator[T]) -> Unit {
  let queue = self.world.resource(self.key.queue_key()).get()
  match queue {
    Some(queue) => self.cursor_ref.val = queue.state.message_count
    None => self.cursor_ref.val = 0
  }
}

///|
pub fn[T] MessageReader::cursor(self : MessageReader[T]) -> Int {
  self.cursor_ref.val
}

///|
pub fn[T] MessageMutator::cursor(self : MessageMutator[T]) -> Int {
  self.cursor_ref.val
}

///|
pub fn[T] MessageReader::read(
  self : MessageReader[T],
) -> Array[T] raise EcsError {
  let queue_access = self.world.resource(self.key.queue_key())
  let queue = queue_access.get().unwrap_or(Messages::new())
  let unread_values = queue.unread(self.cursor_ref.val)
  let unread : Array[T] = []
  for entry in unread_values {
    unread.push(decode_message_payload(self.key, entry.0, entry.1))
  }
  self.cursor_ref.val = queue.state.message_count
  unread
}

///|
pub fn[T] MessageMutator::read(
  self : MessageMutator[T],
) -> Array[Ref[T]] raise EcsError {
  let queue_access = self.world.resource(self.key.queue_key())
  let queue = queue_access.get().unwrap_or(Messages::new())
  let unread_values = queue.unread(self.cursor_ref.val)
  let unread : Array[Ref[T]] = []
  for entry in unread_values {
    unread.push(decode_message_ref(self.key, entry.0, entry.1))
  }
  self.cursor_ref.val = queue.state.message_count
  unread
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
