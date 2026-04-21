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
// Bevy source: `bevy/crates/bevy_app/src/hotpatch.rs`.

///|
pub struct HotPatchPlugin {}

///|
pub struct HotPatched {}

///|
pub struct HotPatchChanges {
  mut revision : Int
}

///|
pub fn HotPatchPlugin::default() -> HotPatchPlugin {
  HotPatchPlugin::{  }
}

///|
pub fn HotPatched::default() -> HotPatched {
  HotPatched::{  }
}

///|
pub fn HotPatchChanges::default() -> HotPatchChanges {
  HotPatchChanges::{ revision: 0 }
}

///|
let hot_patch_changes_key : @ecs.ResourceKey[HotPatchChanges] = @ecs.register_resource(
  debug_name="mgstudio_app::HotPatchChanges",
)

///|
pub impl Resource for HotPatchChanges with resource() {
  hot_patch_changes_key
}

///|
pub impl @ecs.Message for HotPatched with message() {
  @ecs.register_message(debug_name="mgstudio_app::HotPatched")
}

///|
fn hotpatch_ensure_resource(
  world : @ecs.World,
) -> @ecs.ResourceMut[HotPatchChanges] {
  if (try! world.get_resource(HotPatchChanges::resource())) is None {
    world.insert_resource(
      HotPatchChanges::resource(),
      HotPatchChanges::default(),
    )
  }
  match (try! world.get_resource_mut(HotPatchChanges::resource())) {
    Some(state) => state
    None => abort("Missing HotPatchChanges resource")
  }
}

///|
pub fn hotpatch_mark_patched(world : @ecs.World) -> Unit {
  let state = hotpatch_ensure_resource(world)
  state.modify(fn(value) { value.revision = value.revision + 1 })
  let key = HotPatched::message()
  if !world.contains_message(key) {
    world.init_message(key)
  }
  ignore(world.send_message(key, HotPatched::default()))
}

///|
fn hotpatch_forward_runtime_flag(world : @ecs.World) -> Unit {
  if app_rendering_enabled() {
    return
  }
  hotpatch_mark_patched(world)
}

///|
pub fn hotpatch_plugin(app : App[@ecs.World]) -> App[@ecs.World] {
  app
  .init_resource(fn() { HotPatchChanges::default() })
  .add_message(HotPatched::message())
  .add_last_system(hotpatch_forward_runtime_flag)
}

///|
pub fn hotpatch_reset_runtime() -> Unit {
  app_runtime_reset()
}

///|
pub fn hotpatch_stop_rendering() -> Unit {
  app_rendering_stop()
}

///|
pub fn hotpatch_resume_rendering() -> Unit {
  app_rendering_resume()
}

///|
pub fn hotpatch_restart_runtime() -> Unit {
  app_runtime_reset()
  app_rendering_resume()
}
