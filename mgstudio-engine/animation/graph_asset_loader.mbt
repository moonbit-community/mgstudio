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
// Bevy source: `bevy/crates/bevy_animation/src/graph.rs`.
// Runtime loader entry for `AnimationGraphAssetLoader`.

///|
priv enum SerializedAnimationNodeType {
  Clip(String)
  Blend
  Add
}

///|
priv struct SerializedAnimationGraphNode {
  node_type : SerializedAnimationNodeType
  mask : AnimationMask
  weight : Float
}

///|
priv struct SerializedAnimationGraph {
  nodes : Array[SerializedAnimationGraphNode]
  edges : Array[(Int, Int)]
  root : Int
  mask_groups : Array[(AnimationTargetId, AnimationMask)]
}

///|
pub fn animation_graph_asset_loader() -> @asset.AssetLoader[AnimationGraph] {
  @asset.AssetLoader::new_with_context(
    ["animgraph", "animgraph.ron"],
    animation_graph_load_asset,
  )
}

///|
fn animation_graph_load_asset(
  context : @asset.LoadContext,
  bytes : Bytes,
) -> AnimationGraph {
  let source = @utf8.decode_lossy(bytes[:], ignore_bom=true)
  guard animation_graph_try_parse_ron(source) is Some(serialized) else {
    let asset_path = @asset.asset_format_path(context.path())
    abort("Failed to parse animation graph RON asset: \{asset_path}")
  }
  animation_graph_from_serialized(context.asset_server(), serialized)
}

///|
fn animation_graph_from_serialized(
  asset_server : @asset.AssetServer,
  serialized : SerializedAnimationGraph,
) -> AnimationGraph {
  guard serialized.nodes.length() > 0 else { return AnimationGraph::new() }

  let node_count = serialized.nodes.length()
  let parent_by_index : Array[AnimationNodeIndex?] = []
  let children_by_index : Array[Array[AnimationNodeIndex]] = []
  for _ in 0..<node_count {
    parent_by_index.push(None)
    children_by_index.push([])
  }

  for edge in serialized.edges {
    let parent = edge.0
    let child = edge.1
    if parent < 0 ||
      child < 0 ||
      parent >= node_count ||
      child >= node_count ||
      parent == child {
      continue
    }

    let child_index = AnimationNodeIndex::new(child)
    let mut already_exists = false
    for existing in children_by_index[parent] {
      if existing == child_index {
        already_exists = true
        break
      }
    }
    if !already_exists {
      children_by_index[parent].push(child_index)
    }
    parent_by_index[child] = Some(AnimationNodeIndex::new(parent))
  }

  let nodes : Array[AnimationGraphNode] = []
  let mut i = 0
  while i < node_count {
    let serialized_node = serialized.nodes[i]
    let node_type = match serialized_node.node_type {
      Clip(path) => AnimationNodeType::Clip(asset_server.load(path))
      Blend => AnimationNodeType::Blend
      Add => AnimationNodeType::Add
    }
    let node = animation_graph_node_new(
      node_type,
      serialized_node.mask,
      serialized_node.weight,
      parent_by_index[i],
    )
    for child in children_by_index[i] {
      node.children.push(child)
    }
    nodes.push(node)
    i = i + 1
  }

  let root_index = if serialized.root >= 0 && serialized.root < node_count {
    serialized.root
  } else {
    0
  }

  let graph = AnimationGraph::{
    root: AnimationNodeIndex::new(root_index),
    nodes,
    mask_groups: serialized.mask_groups,
    target_mask_index_by_key: {},
  }
  animation_graph_rebuild_target_mask_index(graph)
  graph
}

///|
fn animation_graph_try_parse_ron(source : String) -> SerializedAnimationGraph? {
  guard animation_graph_parse_root_ron(source) is Some(root) else {
    return None
  }
  guard animation_graph_parse_nodes_ron(source) is Some(nodes) else {
    return None
  }
  guard animation_graph_parse_edges_ron(source) is Some(edges) else {
    return None
  }
  guard animation_graph_parse_mask_groups_ron(source) is Some(mask_groups) else {
    return None
  }
  Some(SerializedAnimationGraph::{ nodes, edges, root, mask_groups })
}

///|
fn animation_graph_parse_root_ron(source : String) -> Int? {
  let marker = animation_graph_find_substring(source, "root:", 0)
  guard marker >= 0 else { return None }
  guard animation_graph_parse_int_at(source, marker + 5) is Some(parsed) else {
    return None
  }
  Some(parsed.0)
}

///|
fn animation_graph_parse_nodes_ron(
  source : String,
) -> Array[SerializedAnimationGraphNode]? {
  let marker = animation_graph_find_substring(source, "nodes:", 0)
  guard marker >= 0 else { return None }
  let open = animation_graph_find_char(source, 91, marker)
  guard open >= 0 else { return None }
  let close = animation_graph_find_matching(source, open, 91, 93)
  guard close > open else { return None }
  let block = source[open + 1:close].to_string()

  let nodes : Array[SerializedAnimationGraphNode] = []
  let mut cursor = 0
  while true {
    let node_type_marker = animation_graph_find_substring(
      block, "node_type:", cursor,
    )
    if node_type_marker < 0 {
      break
    }
    guard animation_graph_parse_node_type_ron(block, node_type_marker + 10)
      is Some(parsed_node_type) else {
      return None
    }

    let mask_marker = animation_graph_find_substring(
      block,
      "mask:",
      parsed_node_type.1,
    )
    guard mask_marker >= 0 else { return None }
    guard animation_graph_parse_int_at(block, mask_marker + 5)
      is Some(parsed_mask) else {
      return None
    }
    guard parsed_mask.0 >= 0 else { return None }

    let weight_marker = animation_graph_find_substring(
      block,
      "weight:",
      parsed_mask.1,
    )
    guard weight_marker >= 0 else { return None }
    guard animation_graph_parse_float_at(block, weight_marker + 7)
      is Some(parsed_weight) else {
      return None
    }

    nodes.push(SerializedAnimationGraphNode::{
      node_type: parsed_node_type.0,
      mask: parsed_mask.0.reinterpret_as_uint(),
      weight: parsed_weight.0,
    })
    cursor = parsed_weight.1
  }
  Some(nodes)
}

///|
fn animation_graph_parse_edges_ron(source : String) -> Array[(Int, Int)]? {
  let marker = animation_graph_find_substring(source, "edges:", 0)
  guard marker >= 0 else { return Some([]) }
  let open = animation_graph_find_char(source, 91, marker)
  guard open >= 0 else { return None }
  let close = animation_graph_find_matching(source, open, 91, 93)
  guard close > open else { return None }
  let block = source[open + 1:close].to_string()

  let edges : Array[(Int, Int)] = []
  let mut cursor = 0
  while true {
    let entry_marker = animation_graph_find_substring(block, "Some((", cursor)
    if entry_marker < 0 {
      break
    }
    guard animation_graph_parse_int_at(block, entry_marker + 6)
      is Some(parsed_parent) else {
      return None
    }
    let comma = animation_graph_find_char(block, 44, parsed_parent.1)
    guard comma >= 0 else { return None }
    guard animation_graph_parse_int_at(block, comma + 1) is Some(parsed_child) else {
      return None
    }
    edges.push((parsed_parent.0, parsed_child.0))
    cursor = parsed_child.1
  }
  Some(edges)
}

///|
fn animation_graph_parse_mask_groups_ron(
  source : String,
) -> Array[(AnimationTargetId, AnimationMask)]? {
  let marker = animation_graph_find_substring(source, "mask_groups:", 0)
  if marker < 0 {
    return Some([])
  }

  let value_index = animation_graph_skip_whitespace(source, marker + 12)
  if value_index >= source.length() {
    return Some([])
  }

  if source.code_unit_at(value_index).to_int() != 123 {
    return None
  }

  let close = animation_graph_find_matching(source, value_index, 123, 125)
  guard close > value_index else { return None }
  let body = source[value_index + 1:close].to_string().trim().to_string()
  if body == "" {
    return Some([])
  }

  let out : Array[(AnimationTargetId, AnimationMask)] = []
  let mut cursor = 0
  while true {
    cursor = animation_graph_skip_whitespace(body, cursor)
    if cursor >= body.length() {
      break
    }
    if body.code_unit_at(cursor).to_int() == 44 {
      cursor = cursor + 1
      continue
    }

    guard animation_graph_parse_mask_group_key(body, cursor) is Some(parsed_key) else {
      return None
    }
    let colon = animation_graph_find_char(body, 58, parsed_key.1)
    guard colon >= 0 else { return None }

    guard animation_graph_parse_int_at(body, colon + 1) is Some(parsed_mask) else {
      return None
    }
    guard parsed_mask.0 >= 0 else { return None }
    out.push((parsed_key.0, parsed_mask.0.reinterpret_as_uint()))
    cursor = parsed_mask.1
  }
  Some(out)
}

///|
fn animation_graph_parse_mask_group_key(
  source : String,
  start : Int,
) -> (AnimationTargetId, Int)? {
  let i = animation_graph_skip_whitespace(source, start)
  if i >= source.length() {
    return None
  }

  if source.code_unit_at(i).to_int() == 34 {
    guard animation_graph_parse_quoted_string_ron(source, i)
      is Some(parsed_string) else {
      return None
    }
    return Some(
      (AnimationTargetId::from_name(parsed_string.0), parsed_string.1),
    )
  }

  if source.code_unit_at(i).to_int() == 40 {
    let close = animation_graph_find_matching(source, i, 40, 41)
    guard close > i else { return None }
    let pair = source[i + 1:close].to_string()
    guard animation_graph_parse_int_at(pair, 0) is Some(parsed_high) else {
      return None
    }
    let comma = animation_graph_find_char(pair, 44, parsed_high.1)
    guard comma >= 0 else { return None }
    guard animation_graph_parse_int_at(pair, comma + 1) is Some(parsed_low) else {
      return None
    }
    return Some(
      (AnimationTargetId::new(parsed_high.0, parsed_low.0), close + 1),
    )
  }
  None
}

///|
fn animation_graph_parse_node_type_ron(
  source : String,
  start : Int,
) -> (SerializedAnimationNodeType, Int)? {
  let i = animation_graph_skip_whitespace(source, start)
  if animation_graph_starts_with_at(source, i, "Blend") {
    return Some((Blend, i + 5))
  }
  if animation_graph_starts_with_at(source, i, "Add") {
    return Some((Add, i + 3))
  }
  if animation_graph_starts_with_at(source, i, "Clip") {
    let open = animation_graph_find_char(source, 40, i)
    guard open >= 0 else { return None }
    let quote_start = animation_graph_skip_whitespace(source, open + 1)
    let quote = animation_graph_find_char(source, 34, quote_start)
    guard quote >= 0 else { return None }
    guard animation_graph_parse_quoted_string_ron(source, quote)
      is Some(parsed_path) else {
      return None
    }
    return Some((Clip(parsed_path.0), parsed_path.1))
  }
  None
}

///|
fn animation_graph_parse_quoted_string_ron(
  source : String,
  start : Int,
) -> (String, Int)? {
  guard start < source.length() else { return None }
  guard source.code_unit_at(start).to_int() == 34 else { return None }

  let mut i = start + 1
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if code == 92 {
      if i + 1 >= source.length() {
        return None
      }
      i = i + 2
      continue
    }
    if code == 34 {
      return Some((source[start + 1:i].to_string(), i + 1))
    }
    i = i + 1
  }
  None
}

///|
fn animation_graph_parse_int_at(source : String, start : Int) -> (Int, Int)? {
  let mut i = animation_graph_skip_whitespace(source, start)
  let mut sign = 1
  if i < source.length() && source.code_unit_at(i).to_int() == 45 {
    sign = -1
    i = i + 1
  }

  let mut value = 0
  let mut has_digit = false
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if code < 48 || code > 57 {
      break
    }
    has_digit = true
    value = value * 10 + (code - 48)
    i = i + 1
  }

  if !has_digit {
    None
  } else {
    Some((sign * value, i))
  }
}

///|
fn animation_graph_parse_float_at(
  source : String,
  start : Int,
) -> (Float, Int)? {
  let mut i = animation_graph_skip_whitespace(source, start)
  let begin = i
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    let is_digit = code >= 48 && code <= 57
    let is_sign = code == 43 || code == 45
    let is_dot = code == 46
    let is_exp = code == 69 || code == 101
    if !(is_digit || is_sign || is_dot || is_exp) {
      break
    }
    i = i + 1
  }
  if begin == i {
    return None
  }

  let token = source[begin:i].to_string()
  let parsed = @json.parse(token[:]) catch { _ => return None }
  let value_opt : Float? = Some(@json.from_json(parsed)) catch { _ => None }
  match value_opt {
    Some(value) => Some((value, i))
    None => None
  }
}

///|
fn animation_graph_find_substring(
  source : String,
  pattern : String,
  start : Int,
) -> Int {
  let source_len = source.length()
  let pattern_len = pattern.length()
  if pattern_len <= 0 {
    return start
  }
  if start < 0 || start >= source_len || source_len < pattern_len {
    return -1
  }

  let last = source_len - pattern_len
  let mut i = start
  while i <= last {
    let mut matched = true
    let mut j = 0
    while j < pattern_len {
      if source.code_unit_at(i + j) != pattern.code_unit_at(j) {
        matched = false
        break
      }
      j = j + 1
    }
    if matched {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn animation_graph_find_char(source : String, code : Int, start : Int) -> Int {
  if start < 0 {
    return -1
  }
  let mut i = start
  while i < source.length() {
    if source.code_unit_at(i).to_int() == code {
      return i
    }
    i = i + 1
  }
  -1
}

///|
fn animation_graph_find_matching(
  source : String,
  open_index : Int,
  open_code : Int,
  close_code : Int,
) -> Int {
  if open_index < 0 || open_index >= source.length() {
    return -1
  }

  let mut depth = 0
  let mut in_string = false
  let mut i = open_index
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if in_string {
      if code == 92 {
        i = i + 2
        continue
      }
      if code == 34 {
        in_string = false
      }
      i = i + 1
      continue
    }
    if code == 34 {
      in_string = true
      i = i + 1
      continue
    }
    if code == open_code {
      depth = depth + 1
    } else if code == close_code {
      depth = depth - 1
      if depth == 0 {
        return i
      }
    }
    i = i + 1
  }
  -1
}

///|
fn animation_graph_starts_with_at(
  source : String,
  start : Int,
  pattern : String,
) -> Bool {
  if start < 0 || start + pattern.length() > source.length() {
    return false
  }

  let mut i = 0
  while i < pattern.length() {
    if source.code_unit_at(start + i) != pattern.code_unit_at(i) {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn animation_graph_skip_whitespace(source : String, start : Int) -> Int {
  let mut i = start
  while i < source.length() {
    let code = source.code_unit_at(i).to_int()
    if code == 32 || code == 9 || code == 10 || code == 13 {
      i = i + 1
      continue
    }
    break
  }
  i
}
