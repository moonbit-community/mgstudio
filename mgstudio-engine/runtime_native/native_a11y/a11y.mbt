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
let detached_accessibility_requested_ref : Ref[Bool] = Ref::new(false)

///|
let bound_accessibility_requested_ref : Ref[Ref[Bool]?] = Ref::new(None)

///|
let pending_update_payload_ref : Ref[String?] = Ref::new(None)

///|
let last_update_payload_ref : Ref[String] = Ref::new("")

///|
let pending_actions_ref : Ref[Array[@moon_accesskit.ActionRequest]] = Ref::new([])

///|
fn requested_ref() -> Ref[Bool] {
  match bound_accessibility_requested_ref.val {
    Some(requested) => requested
    None => detached_accessibility_requested_ref
  }
}

///|
pub fn bind_accessibility_requested(requested : Ref[Bool]) -> Unit {
  let merged_requested = requested.val || requested_ref().val
  requested.val = merged_requested
  detached_accessibility_requested_ref.val = merged_requested
  bound_accessibility_requested_ref.val = Some(requested)
}

///|
pub fn accessibility_requested() -> Bool {
  requested_ref().val
}

///|
pub fn set_accessibility_requested(requested : Bool) -> Unit {
  requested_ref().val = requested
}

///|
pub fn queue_update(update : @moon_accesskit.TreeUpdate) -> Unit {
  queue_update_payload(payload=update.to_json().stringify())
}

///|
pub fn queue_update_payload(payload~ : String) -> Unit {
  pending_update_payload_ref.val = Some(payload)
}

///|
pub fn commit_pending_update() -> Bool {
  if !accessibility_requested() {
    return false
  }
  guard pending_update_payload_ref.val is Some(payload) else { return false }
  last_update_payload_ref.val = payload
  pending_update_payload_ref.val = None
  true
}

///|
pub fn last_update_payload() -> String {
  last_update_payload_ref.val
}

///|
pub fn enqueue_action(action : @moon_accesskit.ActionRequest) -> Unit {
  set_accessibility_requested(true)
  pending_actions_ref.val.push(action)
}

///|
pub fn take_actions() -> Array[@moon_accesskit.ActionRequest] {
  let actions = pending_actions_ref.val
  pending_actions_ref.val = []
  actions
}
