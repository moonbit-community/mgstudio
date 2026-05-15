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
const MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE_SYMBOL : UInt = 0x00000001U

///|
const MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE_SYMBOL : UInt = 0x00000002U

///|
const MESHLET_NATIVE_BRIDGE_REQUIRED_SYMBOL_MASK : UInt = MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE_SYMBOL |
  MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE_SYMBOL

///|
extern "C" fn meshlet_native_extension_bridge_symbol_mask_u32() -> UInt = "mgstudio_meshlet_native_extension_bridge_symbol_mask_u32"

///|
extern "C" fn meshlet_native_extension_bridge_available_u32() -> UInt = "mgstudio_meshlet_native_extension_bridge_available_u32"

///|
pub fn meshlet_native_extension_bridge_required_symbol_mask() -> UInt {
  MESHLET_NATIVE_BRIDGE_REQUIRED_SYMBOL_MASK
}

///|
pub fn meshlet_native_extension_bridge_symbol_mask() -> UInt {
  meshlet_native_extension_bridge_symbol_mask_u32()
}

///|
pub fn meshlet_native_extension_bridge_missing_symbol_mask() -> UInt {
  let present = meshlet_native_extension_bridge_symbol_mask()
  MESHLET_NATIVE_BRIDGE_REQUIRED_SYMBOL_MASK ^
  (MESHLET_NATIVE_BRIDGE_REQUIRED_SYMBOL_MASK & present)
}

///|
pub fn meshlet_native_extension_bridge_available() -> Bool {
  meshlet_native_extension_bridge_available_u32() != 0U
}

///|
pub fn meshlet_native_extension_bridge_missing_create_visibility_texture() -> Bool {
  (
    meshlet_native_extension_bridge_missing_symbol_mask() &
    MESHLET_NATIVE_BRIDGE_CREATE_VISIBILITY_TEXTURE_SYMBOL
  ) !=
  0U
}

///|
pub fn meshlet_native_extension_bridge_missing_visibility_storage_layout() -> Bool {
  (
    meshlet_native_extension_bridge_missing_symbol_mask() &
    MESHLET_NATIVE_BRIDGE_ADD_VISIBILITY_STORAGE_TEXTURE_SYMBOL
  ) !=
  0U
}
