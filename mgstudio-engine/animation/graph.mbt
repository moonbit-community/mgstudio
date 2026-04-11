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
// Graph handle + graph asset helpers + graph constructors.

pub struct AnimationNodeIndex {
  index : Int
} derive(Eq, Debug)

///|
pub fn AnimationNodeIndex::new(index : Int) -> AnimationNodeIndex {
  AnimationNodeIndex::{ index, }
}

///|
pub fn AnimationNodeIndex::index(self : AnimationNodeIndex) -> Int {
  self.index
}

///|
pub impl ToJson for AnimationNodeIndex with to_json(self) {
  self.index.to_json()
}

///|
pub impl @json.FromJson for AnimationNodeIndex with from_json(json, path) {
  AnimationNodeIndex::new(@json.from_json(json, path~))
}

///|
pub(all) enum AnimationNodeType {
  Clip(@asset.Handle[AnimationClip])
  Blend
  Add
}

///|
pub struct AnimationGraphNode {
  node_type : AnimationNodeType
  mut mask : AnimationMask
  mut weight : Float
  parent : AnimationNodeIndex?
  children : Array[AnimationNodeIndex]
}

///|
pub fn AnimationGraphNode::node_type(
  self : AnimationGraphNode,
) -> AnimationNodeType {
  self.node_type
}

///|
pub fn AnimationGraphNode::weight(self : AnimationGraphNode) -> Float {
  self.weight
}

///|
pub fn AnimationGraphNode::set_weight(
  self : AnimationGraphNode,
  weight : Float,
) -> AnimationGraphNode {
  self.weight = weight
  self
}

///|
pub fn AnimationGraphNode::mask(self : AnimationGraphNode) -> AnimationMask {
  self.mask
}

///|
pub fn AnimationGraphNode::add_mask(
  self : AnimationGraphNode,
  mask : AnimationMask,
) -> AnimationGraphNode {
  self.mask = self.mask | mask
  self
}

///|
pub fn AnimationGraphNode::remove_mask(
  self : AnimationGraphNode,
  mask : AnimationMask,
) -> AnimationGraphNode {
  self.mask = self.mask & (self.mask ^ mask)
  self
}

///|
pub fn AnimationGraphNode::add_mask_group(
  self : AnimationGraphNode,
  group : Int,
) -> AnimationGraphNode {
  self.add_mask(animation_mask_group_bit(group))
}

///|
pub fn AnimationGraphNode::remove_mask_group(
  self : AnimationGraphNode,
  group : Int,
) -> AnimationGraphNode {
  self.remove_mask(animation_mask_group_bit(group))
}

///|
fn animation_graph_node_new(
  node_type : AnimationNodeType,
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex?,
) -> AnimationGraphNode {
  AnimationGraphNode::{ node_type, mask, weight, parent, children: [] }
}

///|
pub struct AnimationGraph {
  root : AnimationNodeIndex
  nodes : Array[AnimationGraphNode]
  mask_groups : Array[(AnimationTargetId, AnimationMask)]
  target_mask_index_by_key : Map[UInt64, Int]
}

///|
pub fn AnimationGraph::new() -> AnimationGraph {
  let root = AnimationNodeIndex::new(0)
  AnimationGraph::{
    root,
    nodes: [animation_graph_node_new(AnimationNodeType::Blend, 0U, 1.0F, None)],
    mask_groups: [],
    target_mask_index_by_key: {},
  }
}

///|
pub fn AnimationGraph::root(self : AnimationGraph) -> AnimationNodeIndex {
  self.root
}

///|
pub fn AnimationGraph::from_clip(
  clip : @asset.Handle[AnimationClip],
) -> (AnimationGraph, AnimationNodeIndex) {
  let graph = AnimationGraph::new()
  let node = graph.add_clip(clip, 1.0F, graph.root)
  (graph, node)
}

///|
pub fn AnimationGraph::from_clips(
  clips : Array[@asset.Handle[AnimationClip]],
) -> (AnimationGraph, Array[AnimationNodeIndex]) {
  let graph = AnimationGraph::new()
  let nodes = graph.add_clips(clips, 1.0F, graph.root)
  (graph, nodes)
}

///|
pub fn AnimationGraph::add_clips(
  self : AnimationGraph,
  clips : Array[@asset.Handle[AnimationClip]],
  weight : Float,
  parent : AnimationNodeIndex,
) -> Array[AnimationNodeIndex] {
  let nodes : Array[AnimationNodeIndex] = []
  for clip in clips {
    nodes.push(self.add_clip(clip, weight, parent))
  }
  nodes
}

///|
fn animation_mask_group_bit(group : Int) -> AnimationMask {
  if group < 0 || group >= 64 {
    return 0U
  }
  let mut bit = 1U
  for _ in 0..<group {
    bit = bit << 1
  }
  bit
}

///|
fn animation_graph_find_target_mask_group(
  graph : AnimationGraph,
  target_id : AnimationTargetId,
) -> Int? {
  let target_key = animation_target_id_lookup_key(target_id)
  if graph.target_mask_index_by_key.get(target_key) is Some(index) &&
    index >= 0 &&
    index < graph.mask_groups.length() &&
    graph.mask_groups[index].0 == target_id {
    return Some(index)
  }
  let mut i = 0
  while i < graph.mask_groups.length() {
    if graph.mask_groups[i].0 == target_id {
      graph.target_mask_index_by_key.set(target_key, i)
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn animation_graph_rebuild_target_mask_index(graph : AnimationGraph) -> Unit {
  graph.target_mask_index_by_key.clear()
  let mut i = 0
  while i < graph.mask_groups.length() {
    let target_id = graph.mask_groups[i].0
    let target_key = animation_target_id_lookup_key(target_id)
    graph.target_mask_index_by_key.set(target_key, i)
    i = i + 1
  }
}

///|
pub fn AnimationGraph::add_target_to_mask_group(
  self : AnimationGraph,
  target_id : AnimationTargetId,
  mask_group : Int,
) -> AnimationGraph {
  let bit = animation_mask_group_bit(mask_group)
  if bit == 0U {
    return self
  }
  if animation_graph_find_target_mask_group(self, target_id) is Some(index) {
    let current = self.mask_groups[index]
    self.mask_groups[index] = (target_id, current.1 | bit)
  } else {
    self.mask_groups.push((target_id, bit))
    self.target_mask_index_by_key.set(
      animation_target_id_lookup_key(target_id),
      self.mask_groups.length() - 1,
    )
  }
  self
}

///|
pub fn AnimationGraph::target_mask(
  self : AnimationGraph,
  target_id : AnimationTargetId,
) -> AnimationMask {
  if animation_graph_find_target_mask_group(self, target_id) is Some(index) {
    self.mask_groups[index].1
  } else {
    0U
  }
}

///|
fn animation_graph_resolve_parent(
  graph : AnimationGraph,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  let index = parent.index()
  if index < 0 || index >= graph.nodes.length() {
    graph.root
  } else {
    parent
  }
}

///|
pub fn AnimationGraph::add(
  self : AnimationGraph,
  node_type : AnimationNodeType,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(node_type, 0U, weight, parent)
}

///|
pub fn AnimationGraph::add_with_mask(
  self : AnimationGraph,
  node_type : AnimationNodeType,
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  let resolved_parent = animation_graph_resolve_parent(self, parent)
  let node_index = AnimationNodeIndex::new(self.nodes.length())
  self.nodes.push(
    animation_graph_node_new(node_type, mask, weight, Some(resolved_parent)),
  )
  self.nodes[resolved_parent.index()].children.push(node_index)
  node_index
}

///|
pub fn AnimationGraph::add_clip(
  self : AnimationGraph,
  clip : @asset.Handle[AnimationClip],
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Clip(clip), 0U, weight, parent)
}

///|
pub fn AnimationGraph::add_clip_with_mask(
  self : AnimationGraph,
  clip : @asset.Handle[AnimationClip],
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Clip(clip), mask, weight, parent)
}

///|
pub fn AnimationGraph::add_blend(
  self : AnimationGraph,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Blend, 0U, weight, parent)
}

///|
pub fn AnimationGraph::add_blend_with_mask(
  self : AnimationGraph,
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Blend, mask, weight, parent)
}

///|
pub fn AnimationGraph::add_add(
  self : AnimationGraph,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Add, 0U, weight, parent)
}

///|
pub fn AnimationGraph::add_additive_blend(
  self : AnimationGraph,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_add(weight, parent)
}

///|
pub fn AnimationGraph::add_add_with_mask(
  self : AnimationGraph,
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_with_mask(AnimationNodeType::Add, mask, weight, parent)
}

///|
pub fn AnimationGraph::add_additive_blend_with_mask(
  self : AnimationGraph,
  mask : AnimationMask,
  weight : Float,
  parent : AnimationNodeIndex,
) -> AnimationNodeIndex {
  self.add_add_with_mask(mask, weight, parent)
}

///|
pub fn AnimationGraph::get(
  self : AnimationGraph,
  node : AnimationNodeIndex,
) -> AnimationGraphNode? {
  self.nodes.get(node.index())
}

///|
pub fn AnimationGraph::get_mut(
  self : AnimationGraph,
  node : AnimationNodeIndex,
) -> AnimationGraphNode? {
  self.get(node)
}

///|
pub fn AnimationGraph::nodes(
  self : AnimationGraph,
) -> Array[AnimationNodeIndex] {
  let out : Array[AnimationNodeIndex] = []
  for i in 0..<self.nodes.length() {
    out.push(AnimationNodeIndex::new(i))
  }
  out
}

///|
pub fn AnimationGraph::set(
  self : AnimationGraph,
  node : AnimationNodeIndex,
  graph_node : AnimationGraphNode,
) -> Bool {
  let index = node.index()
  if index < 0 || index >= self.nodes.length() {
    return false
  }
  self.nodes[index] = graph_node
  true
}

///|
pub fn AnimationGraph::add_node_mask(
  self : AnimationGraph,
  node : AnimationNodeIndex,
  mask : AnimationMask,
) -> Bool {
  guard self.get(node) is Some(current) else { return false }
  self.set(node, current.add_mask(mask))
}

///|
pub fn AnimationGraph::remove_node_mask(
  self : AnimationGraph,
  node : AnimationNodeIndex,
  mask : AnimationMask,
) -> Bool {
  guard self.get(node) is Some(current) else { return false }
  self.set(node, current.remove_mask(mask))
}

///|
pub fn AnimationGraph::add_node_mask_group(
  self : AnimationGraph,
  node : AnimationNodeIndex,
  group : Int,
) -> Bool {
  self.add_node_mask(node, animation_mask_group_bit(group))
}

///|
pub fn AnimationGraph::remove_node_mask_group(
  self : AnimationGraph,
  node : AnimationNodeIndex,
  group : Int,
) -> Bool {
  self.remove_node_mask(node, animation_mask_group_bit(group))
}

///|
pub fn AnimationGraph::computed_mask(
  self : AnimationGraph,
  node : AnimationNodeIndex,
) -> AnimationMask {
  let mut mask : AnimationMask = 0U
  let mut cursor = Some(node)
  while cursor is Some(index) {
    let i = index.index()
    guard self.nodes.get(i) is Some(current) else { break }
    mask = mask | current.mask
    cursor = current.parent
  }
  mask
}

///|
fn animation_graph_positive_weight(weight : Float) -> Float {
  if weight > 0.0F {
    weight
  } else {
    0.0F
  }
}

///|
fn animation_graph_child_weight_sum(
  graph : AnimationGraph,
  parent : AnimationNodeIndex,
) -> Float {
  guard graph.get(parent) is Some(node) else { return 0.0F }
  let mut sum = 0.0F
  for child in node.children {
    if graph.get(child) is Some(child_node) {
      sum = sum + animation_graph_positive_weight(child_node.weight)
    }
  }
  sum
}

///|
pub fn AnimationGraph::effective_weight(
  self : AnimationGraph,
  node : AnimationNodeIndex,
) -> Float {
  guard self.get(node) is Some(current_node) else { return 0.0F }
  let mut result = animation_graph_positive_weight(current_node.weight)
  let mut cursor = Some(node)
  while cursor is Some(index) {
    guard self.get(index) is Some(current) else { break }
    guard current.parent is Some(parent_index) else { break }
    guard self.get(parent_index) is Some(parent) else { break }

    let parent_weight = animation_graph_positive_weight(parent.weight)
    match parent.node_type {
      Blend => {
        let child_weight_sum = animation_graph_child_weight_sum(
          self, parent_index,
        )
        if child_weight_sum <= 0.0F {
          return 0.0F
        }
        result = result * parent_weight / child_weight_sum
      }
      Add => result = result * parent_weight
      Clip(_) => result = result * parent_weight
    }
    cursor = Some(parent_index)
  }
  result
}

///|
priv struct ThreadedAnimationGraph {
  threaded_graph : Array[AnimationNodeIndex]
  sorted_edge_ranges : Array[(Int, Int)]
  sorted_edges : Array[AnimationNodeIndex]
  computed_masks : Array[AnimationMask]
  effective_weights : Array[Float]
}

///|
priv struct ThreadedAnimationGraphs {
  graphs : Map[Int, ThreadedAnimationGraph]
}

///|
let threaded_animation_graphs_key : @ecs.ResourceKey[ThreadedAnimationGraphs] = @ecs.register_resource(
  debug_name="mgstudio_animation::ThreadedAnimationGraphs",
)

///|
impl @app.Resource for ThreadedAnimationGraphs with resource() {
  threaded_animation_graphs_key
}

///|
fn threaded_animation_graph_new(node_count : Int) -> ThreadedAnimationGraph {
  let sorted_edge_ranges : Array[(Int, Int)] = []
  let computed_masks : Array[AnimationMask] = []
  let effective_weights : Array[Float] = []
  for _ in 0..<node_count {
    sorted_edge_ranges.push((0, 0))
    computed_masks.push(0U)
    effective_weights.push(0.0F)
  }
  ThreadedAnimationGraph::{
    threaded_graph: [],
    sorted_edge_ranges,
    sorted_edges: [],
    computed_masks,
    effective_weights,
  }
}

///|
fn animation_graph_sorted_children(
  children : Array[AnimationNodeIndex],
) -> Array[AnimationNodeIndex] {
  let sorted : Array[AnimationNodeIndex] = []
  for child in children {
    sorted.push(child)
  }
  let mut i = 1
  while i < sorted.length() {
    let cur = sorted[i]
    let cur_index = cur.index()
    let mut j = i
    while j > 0 && sorted[j - 1].index() > cur_index {
      sorted[j] = sorted[j - 1]
      j = j - 1
    }
    sorted[j] = cur
    i = i + 1
  }
  sorted
}

///|
fn threaded_animation_graph_build_from(
  threaded : ThreadedAnimationGraph,
  graph : AnimationGraph,
  node_index : AnimationNodeIndex,
  inherited_mask : AnimationMask,
  parent_multiplier : Float,
) -> Unit {
  guard graph.get(node_index) is Some(node) else { return }
  let node_i = node_index.index()
  if node_i < 0 || node_i >= threaded.sorted_edge_ranges.length() {
    return
  }

  let node_mask = inherited_mask | node.mask
  threaded.computed_masks[node_i] = node_mask

  let node_weight = animation_graph_positive_weight(node.weight)
  threaded.effective_weights[node_i] = node_weight * parent_multiplier

  let sorted_children = animation_graph_sorted_children(node.children)
  let edge_start = threaded.sorted_edges.length()
  for child in sorted_children {
    threaded.sorted_edges.push(child)
  }
  let edge_end = threaded.sorted_edges.length()
  threaded.sorted_edge_ranges[node_i] = (edge_start, edge_end)

  let child_multiplier = match node.node_type {
    Blend => {
      let child_weight_sum = animation_graph_child_weight_sum(graph, node_index)
      if child_weight_sum <= 0.0F {
        0.0F
      } else {
        parent_multiplier * node_weight / child_weight_sum
      }
    }
    Add => parent_multiplier * node_weight
    Clip(_) => parent_multiplier * node_weight
  }

  let mut child_i = sorted_children.length()
  while child_i > 0 {
    child_i = child_i - 1
    threaded_animation_graph_build_from(
      threaded,
      graph,
      sorted_children[child_i],
      node_mask,
      child_multiplier,
    )
  }
  threaded.threaded_graph.push(node_index)
}

///|
fn animation_thread_graph_build(
  graph : AnimationGraph,
) -> ThreadedAnimationGraph {
  let threaded = threaded_animation_graph_new(graph.nodes.length())
  threaded_animation_graph_build_from(threaded, graph, graph.root, 0U, 1.0F)
  threaded
}

///|
pub struct AnimationGraphHandle {
  graph : @asset.Handle[AnimationGraph]
}

///|
pub impl ToJson for AnimationGraphHandle with to_json(self) {
  self.graph.to_json()
}

///|
pub impl @json.FromJson for AnimationGraphHandle with from_json(json, path) {
  AnimationGraphHandle::new(@json.from_json(json, path~))
}

///|
pub fn AnimationGraphHandle::new(
  graph : @asset.Handle[AnimationGraph],
) -> AnimationGraphHandle {
  AnimationGraphHandle::{ graph, }
}

///|
pub fn AnimationGraphHandle::graph(
  self : AnimationGraphHandle,
) -> @asset.Handle[AnimationGraph] {
  self.graph
}

///|
pub fn animation_graph_add(
  graph : AnimationGraph,
) -> @asset.Handle[AnimationGraph] {
  animation_asset_store_mut_or_abort().val.add(graph)
}

///|
pub fn animation_graph_get(
  handle : @asset.Handle[AnimationGraph],
) -> AnimationGraph? {
  animation_asset_store_or_abort().get(handle)
}

///|
pub fn animation_graph_set(
  handle : @asset.Handle[AnimationGraph],
  graph : AnimationGraph,
) -> Bool {
  animation_asset_store_mut_or_abort().val.set(handle, graph)
}

///|
fn thread_animation_graphs(
  graph_handles : @ecs.Query[@ecs.Comp[AnimationGraphHandle], @ecs.All],
  graph_events : @ecs.MessageReader[@asset.AssetEvent[AnimationGraph]],
  graph_assets : @app.Res[@asset.Assets[AnimationGraph]],
  threaded_graphs : @app.ResMut[ThreadedAnimationGraphs],
) -> Unit {
  let unique_handles : Map[Int, @asset.Handle[AnimationGraph]] = {}
  try! graph_handles.view(fn(_entity, graph_handle_comp) {
    let graph_handle = graph_handle_comp.value().graph()
    let graph_id = graph_handle.id()
    if graph_id >= 0 && !unique_handles.contains(graph_id) {
      unique_handles.set(graph_id, graph_handle)
    }
  })

  let graph_assets_value = graph_assets.get()
  let threaded_graphs_ref = threaded_graphs.get_ref()
  let changed_graph_ids : Map[Int, Bool] = {}

  for event in (try! graph_events.read()) {
    match event {
      @asset.AssetEvent::Added(handle) =>
        changed_graph_ids.set(handle.id(), true)
      @asset.AssetEvent::Modified(handle) =>
        changed_graph_ids.set(handle.id(), true)
      @asset.AssetEvent::LoadedWithDependencies(handle) =>
        changed_graph_ids.set(handle.id(), true)
      @asset.AssetEvent::Removed(handle) => {
        changed_graph_ids.remove(handle.id())
        ignore(threaded_graphs_ref.val.graphs.remove(handle.id()))
      }
    }
  }

  let stale_graph_ids : Array[Int] = []
  for entry in threaded_graphs_ref.val.graphs.iter() {
    let (graph_id, _threaded_graph) = entry
    if !unique_handles.contains(graph_id) {
      stale_graph_ids.push(graph_id)
    }
  }
  for graph_id in stale_graph_ids {
    ignore(threaded_graphs_ref.val.graphs.remove(graph_id))
  }

  for pair in unique_handles.iter() {
    let (graph_id, graph_handle) = pair
    if !changed_graph_ids.contains(graph_id) &&
      threaded_graphs_ref.val.graphs.contains(graph_id) {
      continue
    }
    if graph_assets_value.get(graph_handle) is Some(graph) {
      threaded_graphs_ref.val.graphs.set(
        graph_id,
        animation_thread_graph_build(graph),
      )
    }
  }
}

///|
pub fn animation_graph() -> AnimationGraph {
  AnimationGraph::new()
}

///|
pub fn animation_graph_root_node(graph : AnimationGraph) -> AnimationNodeIndex {
  graph.root()
}

///|
pub fn animation_graph_from_clip_handle(
  clip : @asset.Handle[AnimationClip],
) -> (AnimationGraph, AnimationNodeIndex) {
  AnimationGraph::from_clip(clip)
}
