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
// Bevy source: `bevy/crates/bevy_asset/src/io/processor_gated.rs`.

///|
pub struct ProcessorGatedAssetIo {
  enabled : Bool
  extension : String
}

///|
pub fn ProcessorGatedAssetIo::new(extension : String) -> ProcessorGatedAssetIo {
  ProcessorGatedAssetIo::{ enabled: true, extension }
}

///|
pub fn ProcessorGatedAssetIo::enabled(self : ProcessorGatedAssetIo) -> Bool {
  self.enabled
}

///|
pub fn ProcessorGatedAssetIo::extension(self : ProcessorGatedAssetIo) -> String {
  self.extension
}
