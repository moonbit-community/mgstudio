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
// Bevy source: `bevy/crates/bevy_animation/src/graph.rs`.
// Runtime wrappers live in this file while the broader animation implementation stays split across the package.

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
