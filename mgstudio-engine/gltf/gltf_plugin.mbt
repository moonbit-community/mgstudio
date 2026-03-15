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
pub type GltfLoaderRegistration = () -> Unit

///|
let gltf_loader_registration_ref : Ref[GltfLoaderRegistration?] = Ref::new(None)

///|
let gltf_loader_registered_ref : Ref[Bool] = Ref::new(false)

///|
let gltf_pbr_material_handler_enabled_ref : Ref[Bool] = Ref::new(true)

///|
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  gltf_pbr_material_handler_enabled_ref.val = enabled
}

///|
pub fn gltf_pbr_material_handler_enabled() -> Bool {
  gltf_pbr_material_handler_enabled_ref.val
}

///|
pub fn gltf_install_loader_registration(
  register : GltfLoaderRegistration,
) -> Unit {
  gltf_loader_registration_ref.val = Some(register)
  gltf_loader_registered_ref.val = false
}

///|
fn gltf_register_asset_loaders_once() -> Unit {
  if gltf_loader_registered_ref.val {
    return
  }
  let register = match gltf_loader_registration_ref.val {
    Some(value) => value
    None =>
      abort(
        "gltf plugin loader registration is not installed; add scene loader wiring before running gltf_plugin",
      )
  }
  register()
  gltf_loader_registered_ref.val = true
}

///|
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gltf_register_asset_loaders_once()
  app
}
