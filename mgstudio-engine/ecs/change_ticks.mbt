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
struct ComponentTickMetadata {
  added_tick : @core.Tick?
  changed_tick : @core.Tick?
  changed_caller : String?
}

///|
fn component_tick_metadata_empty() -> ComponentTickMetadata {
  { added_tick: None, changed_tick: None, changed_caller: None }
}

///|
fn component_tick_metadata_with_added(
  previous : ComponentTickMetadata?,
  tick : @core.Tick,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_tick: Some(tick),
    changed_tick: match previous.changed_tick {
      Some(changed_tick) => Some(changed_tick)
      None => Some(tick)
    },
    changed_caller: caller,
  }
}

///|
fn component_tick_metadata_with_changed(
  previous : ComponentTickMetadata?,
  tick : @core.Tick,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_tick: previous.added_tick,
    changed_tick: Some(tick),
    changed_caller: caller,
  }
}

///|
fn component_tick_metadata_check_ticks(
  metadata : ComponentTickMetadata,
  present_tick : @core.Tick,
) -> ComponentTickMetadata {
  {
    added_tick: match metadata.added_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    },
    changed_tick: match metadata.changed_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    },
    changed_caller: metadata.changed_caller,
  }
}
