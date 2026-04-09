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
// Bevy source: `bevy/crates/bevy_asset/src/io/file/file_watcher.rs`.

///|
pub struct FileWatcher {
  root_path : String
  recursive : Bool
  enabled : Bool
}

///|
pub fn FileWatcher::new(root_path : String) -> FileWatcher {
  FileWatcher::{ root_path, recursive: true, enabled: true }
}

///|
pub fn FileWatcher::with_recursive(
  self : FileWatcher,
  recursive : Bool,
) -> FileWatcher {
  FileWatcher::{ ..self, recursive, }
}

///|
pub fn FileWatcher::with_enabled(
  self : FileWatcher,
  enabled : Bool,
) -> FileWatcher {
  FileWatcher::{ ..self, enabled, }
}

///|
pub fn FileWatcher::should_watch(self : FileWatcher, path : String) -> Bool {
  self.enabled && (self.recursive || path == self.root_path)
}
