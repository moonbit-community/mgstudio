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
extenum @ecs.EcsPayload += {
  EcsPayload_examples_animation_animation_graph_ExampleAnimationWeights(
    ExampleAnimationWeights
  )
  EcsPayload_examples_animation_animation_graph_ClipNode(ClipNode)
  EcsPayload_examples_animation_animation_graph_ClipNodeFill(ClipNodeFill)
  EcsPayload_examples_animation_animation_graph_ClipNodeLabel(ClipNodeLabel)
}

///|
impl @ecs.EcsPayloadCodec for ExampleAnimationWeights with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_graph_ExampleAnimationWeights(self)
}

///|
impl @ecs.EcsPayloadCodec for ExampleAnimationWeights with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_animation_animation_graph_ExampleAnimationWeights(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ClipNode with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_graph_ClipNode(self)
}

///|
impl @ecs.EcsPayloadCodec for ClipNode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_graph_ClipNode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ClipNodeFill with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_graph_ClipNodeFill(self)
}

///|
impl @ecs.EcsPayloadCodec for ClipNodeFill with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_graph_ClipNodeFill(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ClipNodeLabel with to_ecs_payload(self) {
  EcsPayload_examples_animation_animation_graph_ClipNodeLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for ClipNodeLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animation_graph_ClipNodeLabel(value) =>
      Some(value)
    _ => None
  }
}
