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
priv struct NativeA11yNode {
  node_id : Int
  parent_id : Int
  role_id : Int
  x : Float
  y : Float
  width : Float
  height : Float
  name : String
  actions_mask : Int
}

///|
let current_root_id_ref : Ref[Int] = Ref::new(0)

///|
let current_nodes_ref : Ref[Array[NativeA11yNode]] = Ref::new([])

///|
let committed_nodes_ref : Ref[Array[NativeA11yNode]] = Ref::new([])

///|
let pending_actions_ref : Ref[Array[(Int, Int, String)]] = Ref::new([])

///|
let last_update_payload_ref : Ref[String] = Ref::new("")

///|
fn encode_node_snapshot(node : NativeA11yNode) -> String {
  "{\"node_id\":" +
  node.node_id.to_string() +
  ",\"parent_id\":" +
  node.parent_id.to_string() +
  ",\"role_id\":" +
  node.role_id.to_string() +
  ",\"x\":" +
  node.x.to_string() +
  ",\"y\":" +
  node.y.to_string() +
  ",\"width\":" +
  node.width.to_string() +
  ",\"height\":" +
  node.height.to_string() +
  ",\"name\":" +
  "\"" +
  node.name +
  "\"" +
  ",\"actions_mask\":" +
  node.actions_mask.to_string() +
  "}"
}

///|
fn build_snapshot_payload() -> String {
  let mut payload = "{\"root_id\":" +
    current_root_id_ref.val.to_string() +
    ",\"nodes\":["
  let nodes = committed_nodes_ref.val
  for i in 0..<nodes.length() {
    if i > 0 {
      payload = payload + ","
    }
    payload = payload + encode_node_snapshot(nodes[i])
  }
  payload = payload + "]}"
  payload
}

///|
pub fn begin_update(root_id : Int) -> Unit {
  current_root_id_ref.val = root_id
  current_nodes_ref.val = []
}

///|
pub fn push_node(
  node_id~ : Int,
  parent_id~ : Int,
  role_id~ : Int,
  x~ : Float,
  y~ : Float,
  width~ : Float,
  height~ : Float,
  name~ : String,
  actions_mask~ : Int,
) -> Unit {
  current_nodes_ref.val.push(NativeA11yNode::{
    node_id,
    parent_id,
    role_id,
    x,
    y,
    width,
    height,
    name,
    actions_mask,
  })
}

///|
pub fn end_update() -> Unit {
  committed_nodes_ref.val = current_nodes_ref.val
  last_update_payload_ref.val = build_snapshot_payload()
}

///|
pub fn actions_len() -> Int {
  pending_actions_ref.val.length()
}

///|
pub fn action_target(index : Int) -> Int {
  if index < 0 || index >= pending_actions_ref.val.length() {
    0
  } else {
    let (target, _, _) = pending_actions_ref.val[index]
    target
  }
}

///|
pub fn action_kind(index : Int) -> Int {
  if index < 0 || index >= pending_actions_ref.val.length() {
    0
  } else {
    let (_, kind, _) = pending_actions_ref.val[index]
    kind
  }
}

///|
pub fn action_value_len(index : Int) -> Int {
  if index < 0 || index >= pending_actions_ref.val.length() {
    0
  } else {
    let (_, _, value) = pending_actions_ref.val[index]
    value.length()
  }
}

///|
pub fn action_value_code_unit(index~ : Int, offset~ : Int) -> Int {
  if index < 0 || index >= pending_actions_ref.val.length() || offset < 0 {
    return 0
  }
  let (_, _, value) = pending_actions_ref.val[index]
  if offset >= value.length() {
    0
  } else {
    value.code_unit_at(offset).to_int()
  }
}

///|
pub fn actions_clear() -> Unit {
  pending_actions_ref.val.clear()
}

///|
pub fn apply_update(update_json~ : String) -> Unit {
  last_update_payload_ref.val = if update_json.length() == 0 {
    build_snapshot_payload()
  } else {
    update_json
  }
}
