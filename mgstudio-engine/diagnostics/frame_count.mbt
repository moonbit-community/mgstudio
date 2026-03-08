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
//
// Adapted from Bevy's `bevy_diagnostic` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub struct FrameCount {
  mut value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn FrameCount::default() -> FrameCount {
  FrameCount::{ value: 0 }
}

///|
let frame_count_resource_key : @ecs.ResourceKey[FrameCount] = @ecs.register_resource(
  debug_name="bevy_diagnostic::FrameCount",
)

///|
priv struct FrameCountPluginMarker {}

///|
let frame_count_plugin_marker_key : @ecs.ResourceKey[FrameCountPluginMarker] = @ecs.register_resource(
  debug_name="bevy_diagnostic::FrameCountPluginMarker",
)

///|
pub impl @app.Resource for FrameCount with resource() {
  frame_count_resource_key
}

///|
pub struct FrameCountPlugin {}

///|
pub fn FrameCountPlugin::default() -> FrameCountPlugin {
  FrameCountPlugin::{  }
}

///|
pub fn frame_count_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  frame_count_plugin_with(app, FrameCountPlugin::default())
}

///|
pub fn frame_count_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : FrameCountPlugin,
) -> @app.App[@ecs.World] {
  if app.contains_resource(frame_count_plugin_marker_key) {
    return app
  }
  app
  .insert_world_resource(frame_count_plugin_marker_key, FrameCountPluginMarker::{

  })
  .init_resource(fn() { FrameCount::default() })
  .add_last_system_param(update_frame_count)
}

///|
pub fn update_frame_count(frame_count : @app.ResMut[FrameCount]) -> Unit {
  let value_ref = frame_count.get_ref()
  if value_ref.val.value == @int.max_value {
    value_ref.val.value = 0
  } else {
    value_ref.val.value = value_ref.val.value + 1
  }
}
