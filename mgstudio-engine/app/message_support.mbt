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
priv struct MessageUpdateMarker {}

///|
fn message_update_marker_key() -> @ecs.ResourceKey[MessageUpdateMarker] {
  @ecs.register_resource(debug_name="bevy_app::MessageUpdateMarker")
}

///|
pub let message_update_system_set : SystemSet = system_set(
  "bevy_ecs::message::MessageUpdateSystems",
)

///|
fn message_update_system(world : @ecs.World) -> Unit {
  world.update_messages()
}

///|
fn message_cursor_state(state : Ref[Json]) -> Int {
  try @json.from_json(state.val) catch {
    _ => 0
  } noraise {
    value => value
  }
}

///|
fn SubApp::install_message_update_system(
  self : SubApp[@ecs.World],
) -> SubApp[@ecs.World] {
  if self.world().resource(message_update_marker_key()).is_present() {
    return self
  }
  self
  .world()
  .insert_resource(message_update_marker_key(), MessageUpdateMarker::{  })
  self.add_systems(
    First,
    system(message_update_system).in_set(message_update_system_set),
  )
}

///|
pub fn[M] SubApp::add_message(
  self : SubApp[@ecs.World],
  key : @ecs.MessageKey[M],
) -> SubApp[@ecs.World] {
  self.world().init_message(key)
  self.install_message_update_system()
}

///|
pub fn[M] App::add_message(
  self : App[@ecs.World],
  key : @ecs.MessageKey[M],
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_message(key)
  self
}

///|
pub fn[M] on_message(
  world : @ecs.World,
  key : @ecs.MessageKey[M],
  state : Ref[Json],
) -> Bool {
  let reader = world.message_reader(key, Ref::new(message_cursor_state(state)))
  let has_messages = reader.len() > 0
  reader.clear()
  state.val = reader.cursor().to_json()
  has_messages
}

///|
pub fn[M] SystemConfig::run_if_on_message(
  self : SystemConfig[@ecs.World],
  key : @ecs.MessageKey[M],
) -> SystemConfig[@ecs.World] {
  SystemConfig::run_if_stateful(self, (0).to_json(), fn(
    world : @ecs.World,
    state : Ref[Json],
  ) -> Bool {
    on_message(world, key, state)
  })
}

///|
pub impl[T : @ecs.Message] Resource for @ecs.Messages[T] with resource() {
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  key.messages_resource()
}

///|
pub impl[T] FromWorld for @ecs.MessageCursor[T] with from_world(_world) {
  @ecs.MessageCursor::default()
}

///|
pub fn[T : @ecs.Message] ResMut::write(
  self : ResMut[@ecs.Messages[T]],
  message : T,
) -> Int {
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  self.get_ref().val.write_message(key, message)
}

///|
pub fn[T : @ecs.Message] ResMut::write_batch(
  self : ResMut[@ecs.Messages[T]],
  messages : Array[T],
) -> Unit {
  for message in messages {
    ignore(self.write(message))
  }
}

///|
pub fn[T : @ecs.Message + Default] ResMut::write_default(
  self : ResMut[@ecs.Messages[T]],
) -> Int {
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  self.get_ref().val.write_message_default(key)
}

///|
pub fn[T : @ecs.Message] Local::read(
  self : Local[@ecs.MessageCursor[T]],
  messages : ResMut[@ecs.Messages[T]],
) -> Array[T] raise @ecs.EcsError {
  let cursor = self.get()
  let unread = try! cursor.read(messages.get_ref().val)
  self.set(cursor)
  unread
}

///|
pub fn[T : @ecs.Message] Local::read_mut(
  self : Local[@ecs.MessageCursor[T]],
  messages : ResMut[@ecs.Messages[T]],
) -> Array[Ref[T]] raise @ecs.EcsError {
  let cursor = self.get()
  let unread = try! cursor.read_mut(messages.get_ref().val)
  self.set(cursor)
  unread
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with get(state) {
  let world = system_param_abort_missing_world()
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  world.message_reader(key, Ref::new(message_cursor_state(state)))
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with store(
  self,
  state,
) {
  state.val = self.cursor().to_json()
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with get(
  state,
) {
  let world = system_param_abort_missing_world()
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  world.message_mutator(key, Ref::new(message_cursor_state(state)))
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with store(
  self,
  state,
) {
  state.val = self.cursor().to_json()
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with get(
  _state,
) {
  let world = system_param_abort_missing_world()
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  world.message_writer(key)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}
