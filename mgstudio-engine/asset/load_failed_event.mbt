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
// Bevy source reference: `bevy/crates/bevy_asset/src/event.rs`.
pub struct AssetLoadFailedEvent[T] {
  id : AssetId[T]
  path : AssetPath
  error : String
}

///|
pub struct UntypedAssetLoadFailedEvent {
  type_name : String
  id : Int
  path : AssetPath
  error : String
}

///|
type AssetLoadFailedDispatch = (@ecs.World, UntypedAssetLoadFailedEvent) -> Unit

///|
let asset_load_failed_untyped_key : @ecs.MessageKey[UntypedAssetLoadFailedEvent] = @ecs.register_message(
  debug_name="mgstudio_asset::UntypedAssetLoadFailedEvent",
)

///|
let asset_load_failed_typed_message_registry : Ref[
  @hashmap.HashMap[String, @any.Any],
] = Ref::new(@hashmap.HashMap::new())

///|
let asset_load_failed_dispatch_registry : Ref[
  @hashmap.HashMap[String, AssetLoadFailedDispatch],
] = Ref::new(@hashmap.HashMap::new())

///|
fn[T] registered_asset_load_failed_message_key_with_type_name(
  type_name : String,
) -> @ecs.MessageKey[AssetLoadFailedEvent[T]] {
  match asset_load_failed_typed_message_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "asset load failed message registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.MessageKey[AssetLoadFailedEvent[T]] = @ecs.register_message(
        debug_name="mgstudio_asset::AssetLoadFailedEvent<\{type_name}>",
      )
      asset_load_failed_typed_message_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
fn[T] register_asset_load_failed_dispatch_for_type_name(
  type_name : String,
  _probe : Assets[T],
) -> Unit {
  if asset_load_failed_dispatch_registry.val.contains(type_name) {
    return
  }
  let message_key : @ecs.MessageKey[AssetLoadFailedEvent[T]] = registered_asset_load_failed_message_key_with_type_name(
    type_name,
  )
  let dispatch : AssetLoadFailedDispatch = fn(world, failure) {
    if !world.contains_message(message_key) {
      world.init_message(message_key)
    }
    ignore(
      world.send_message(message_key, AssetLoadFailedEvent::{
        id: AssetId::new(failure.id),
        path: failure.path,
        error: failure.error,
      }),
    )
  }
  asset_load_failed_dispatch_registry.val.set(type_name, dispatch)
}

///|
pub fn[T] asset_register_load_failed_event_for_asset_type(
  probe : Assets[T],
) -> Unit {
  let type_name = @any.of(probe).type_name()
  register_asset_load_failed_dispatch_for_type_name(type_name, probe)
}

///|
pub fn asset_dispatch_load_failed_event(
  world : @ecs.World,
  failure : UntypedAssetLoadFailedEvent,
) -> Unit {
  let untyped_key : @ecs.MessageKey[UntypedAssetLoadFailedEvent] = @ecs.Message::message()
  if !world.contains_message(untyped_key) {
    world.init_message(untyped_key)
  }
  ignore(world.send_message(untyped_key, failure))
  match asset_load_failed_dispatch_registry.val.get(failure.type_name) {
    Some(dispatch) => dispatch(world, failure)
    None => ()
  }
}

///|
pub impl[T] @ecs.Message for AssetLoadFailedEvent[T] with message() {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  register_asset_load_failed_dispatch_for_type_name(type_name, probe)
  registered_asset_load_failed_message_key_with_type_name(type_name)
}

///|
pub impl @ecs.Message for UntypedAssetLoadFailedEvent with message() {
  asset_load_failed_untyped_key
}

///|
pub fn UntypedAssetLoadFailedEvent::new(
  type_name : String,
  id : Int,
  path : AssetPath,
  error : String,
) -> UntypedAssetLoadFailedEvent {
  UntypedAssetLoadFailedEvent::{ type_name, id, path, error }
}

///|
pub fn[T] AssetLoadFailedEvent::untyped(
  self : AssetLoadFailedEvent[T],
) -> UntypedAssetLoadFailedEvent {
  let probe : Assets[T] = Assets::new()
  UntypedAssetLoadFailedEvent::{
    type_name: @any.of(probe).type_name(),
    id: self.id.index(),
    path: self.path,
    error: self.error,
  }
}
