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
// Bevy source: `bevy/crates/bevy_asset/src/processor/log.rs`.
// Bridge surface for processor error reporting.
pub using @asset {type AssetProcessError}

///|
pub fn asset_processor_error_message(error : AssetProcessError) -> String {
  error.message()
}

///|
pub fn asset_processor_log_line(
  processor_name : String,
  error : AssetProcessError,
) -> String {
  "asset_processor[\{processor_name}]: \{error.message()}"
}
