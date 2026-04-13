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
// Bevy source: `bevy/crates/bevy_asset/src/asset_changed.rs`.
pub fn[T] asset_events_include_change(
  events : Array[AssetEvent[T]],
  handle : Handle[T],
) -> Bool {
  for event in events {
    match event {
      AssetEvent::Added(changed)
      | AssetEvent::Modified(changed)
      | AssetEvent::LoadedWithDependencies(changed) =>
        if changed.id() == handle.id() {
          return true
        }
      AssetEvent::Removed(_) => ()
    }
  }
  false
}

///|
pub fn[T] asset_events_include_removal(
  events : Array[AssetEvent[T]],
  handle : Handle[T],
) -> Bool {
  for event in events {
    if event is AssetEvent::Removed(changed) && changed.id() == handle.id() {
      return true
    }
  }
  false
}
