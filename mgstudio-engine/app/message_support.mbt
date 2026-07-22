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
let message_update_marker_key : @ecs.ResourceKey[MessageUpdateMarker] = @ecs.register_resource(
  debug_name="mgstudio_app::MessageUpdateMarker",
)

///|
pub let message_update_system_set : SystemSet = system_set(
  "mgstudio.ecs.message.MessageUpdateSystems",
)

///|
fn message_update_system(world : @ecs.World) -> Unit {
  world.update_messages()
}

///|
priv struct MessageSystemParamState[M] {
  mut cursor : @ecs.MessageCursor[M]
}

///|
fn[M] message_system_param_state_new() -> MessageSystemParamState[M] {
  { cursor: MessageCursor() }
}

///|
#warnings("-unnecessary_annotation")
fn SubApp::install_message_update_system(
  self : SubApp[@ecs.World],
) -> SubApp[@ecs.World] {
  if self.world().resource(message_update_marker_key).is_present() {
    return self
  }
  self
  .world()
  .insert_resource(message_update_marker_key, MessageUpdateMarker::{  })
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
  state : RunConditionState[@ecs.MessageCursor[M]],
) -> Bool {
  let reader = world.message_reader(key, cursor=state.get())
  let has_messages = reader.len() > 0
  reader.clear()
  state.set(reader.cursor())
  has_messages
}

///|
pub fn[M] SystemConfig::run_if_on_message(
  self : SystemConfig[@ecs.World],
  key : @ecs.MessageKey[M],
) -> SystemConfig[@ecs.World] {
  let initial_cursor : @ecs.MessageCursor[M] = MessageCursor()
  SystemConfig::run_if_stateful(self, initial_cursor, fn(
    world : @ecs.World,
    state : RunConditionState[@ecs.MessageCursor[M]],
  ) -> Bool {
    on_message(world, key, state)
  })
}

///|
pub impl[T : @ecs.Message] Resource for @ecs.Messages[T] with fn resource() {
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  key.messages_resource()
}

///|
pub impl[T] FromWorld for @ecs.MessageCursor[T] with fn from_world(_world) {
  MessageCursor()
}

///|
pub fn[T : @ecs.Message] ResMut::write(
  self : ResMut[@ecs.Messages[T]],
  message : T,
) -> Int {
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  res_mut_world_or_abort(self).send_message(key, message)
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
  res_mut_world_or_abort(self).send_message(key, Default::default())
}

///|
pub fn[T] Local::read(
  self : Local[@ecs.MessageCursor[T]],
  messages : ResMut[@ecs.Messages[T]],
) -> Array[T] {
  let cursor = self.get()
  let unread = cursor.read(messages.peek())
  self.set(cursor)
  unread
}

///|
pub fn[T] Local::read_mut(
  self : Local[@ecs.MessageCursor[T]],
  messages : ResMut[@ecs.Messages[T]],
) -> Array[T] {
  let cursor = self.get()
  let unread = cursor.read_mut(messages.peek())
  self.set(cursor)
  unread
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with fn init_state(
  world,
) {
  ignore(world)
  let state : MessageSystemParamState[T] = message_system_param_state_new()
  SystemParamState::new(
    fn() {
      let world = system_param_abort_missing_world()
      let key : @ecs.MessageKey[T] = @ecs.Message::message()
      world.message_reader(key, cursor=state.cursor)
    },
    fn(reader : @ecs.MessageReader[T]) { state.cursor = reader.cursor() },
  )
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with fn get(
  state,
) {
  state.get()
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with fn store(
  self,
  state,
) {
  state.store(self)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageReader[T] with fn access(
  _world,
) {
  let access = SystemAccess::new()
  access.add_read_resource(T::message().id())
  access
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with fn init_state(
  world,
) {
  ignore(world)
  let state : MessageSystemParamState[T] = message_system_param_state_new()
  SystemParamState::new(
    fn() {
      let world = system_param_abort_missing_world()
      let key : @ecs.MessageKey[T] = @ecs.Message::message()
      world.message_mutator(key, cursor=state.cursor)
    },
    fn(mutator : @ecs.MessageMutator[T]) { state.cursor = mutator.cursor() },
  )
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with fn get(
  state,
) {
  state.get()
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with fn store(
  self,
  state,
) {
  state.store(self)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageMutator[T] with fn access(
  _world,
) {
  let access = SystemAccess::new()
  access.add_write_resource(T::message().id())
  access
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with fn init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with fn get(
  _state,
) {
  let world = system_param_abort_missing_world()
  let key : @ecs.MessageKey[T] = @ecs.Message::message()
  world.message_writer(key)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with fn store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[T : @ecs.Message] SystemParam for @ecs.MessageWriter[T] with fn access(
  _world,
) {
  let access = SystemAccess::new()
  access.add_write_resource(T::message().id())
  access
}
