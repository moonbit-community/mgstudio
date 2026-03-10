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
  bound_accessibility_requested_ref.val = Some(requested)
  requested.val = detached_accessibility_requested_ref.val
}

///|
pub fn accessibility_requested() -> Bool {
  requested_ref().val
}

///|
pub fn set_accessibility_requested(requested : Bool) -> Unit {
  requested_ref().val = requested
  detached_accessibility_requested_ref.val = requested
}

///|
pub fn queue_accessibility_update(update : @moon_accesskit.TreeUpdate) -> Unit {
  queue_accessibility_update_payload(payload=update.to_json().stringify())
}

///|
pub fn queue_accessibility_update_payload(payload~ : String) -> Unit {
  pending_update_payload_ref.val = Some(payload)
}

///|
pub fn commit_pending_accessibility_update() -> Bool {
  guard accessibility_requested() else { return false }
  match pending_update_payload_ref.val {
    Some(payload) => {
      last_update_payload_ref.val = payload
      pending_update_payload_ref.val = None
      true
    }
    None => false
  }
}

///|
pub fn last_accessibility_update_payload() -> String {
  last_update_payload_ref.val
}

///|
pub fn enqueue_accessibility_action(
  action : @moon_accesskit.ActionRequest,
) -> Unit {
  pending_actions_ref.val.push(action)
  set_accessibility_requested(true)
}

///|
pub fn take_accessibility_actions() -> Array[@moon_accesskit.ActionRequest] {
  let actions = pending_actions_ref.val
  pending_actions_ref.val = []
  actions
}
