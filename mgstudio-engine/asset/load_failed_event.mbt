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
let asset_load_failed_dispatch_registry : @hashmap.HashMap[
  String,
  AssetLoadFailedDispatch,
] = @hashmap.HashMap([])

///|
fn[T : Asset] registered_asset_load_failed_message_key() -> @ecs.MessageKey[
  AssetLoadFailedEvent[T],
] {
  T::asset_resource_keys().load_failed
}

///|
fn[T : Asset] register_asset_load_failed_dispatch_for_type_name(
  type_name : String,
  _probe : Assets[T],
) -> Unit {
  if asset_load_failed_dispatch_registry.contains(type_name) {
    return
  }
  let message_key : @ecs.MessageKey[AssetLoadFailedEvent[T]] = registered_asset_load_failed_message_key()
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
  asset_load_failed_dispatch_registry.set(type_name, dispatch)
}

///|
pub fn[T : Asset] asset_register_load_failed_event_for_asset_type(
  _sample : T?,
) -> Unit {
  ignore(_sample)
  let type_name = assets_type_name(_sample)
  let probe : Assets[T] = Assets::new()
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
  match asset_load_failed_dispatch_registry.get(failure.type_name) {
    Some(dispatch) => dispatch(world, failure)
    None => ()
  }
}

///|
pub impl[T : Asset] @ecs.Message for AssetLoadFailedEvent[T] with message() {
  let type_name = assets_type_name((None : T?))
  let probe : Assets[T] = Assets::new()
  register_asset_load_failed_dispatch_for_type_name(type_name, probe)
  registered_asset_load_failed_message_key()
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
pub fn[T : Asset] AssetLoadFailedEvent::untyped(
  self : AssetLoadFailedEvent[T],
) -> UntypedAssetLoadFailedEvent {
  UntypedAssetLoadFailedEvent::{
    type_name: assets_type_name((None : T?)),
    id: self.id.index(),
    path: self.path,
    error: self.error,
  }
}
