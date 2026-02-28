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
/// Minimal Bevy-aligned animation runtime core.

///|
const ANIMATION_TARGET_NAMESPACE : String = "bevy_animation_target"

///|
const HASH_A_OFFSET : UInt = 0x811C9DC5U

///|
const HASH_A_PRIME : UInt = 0x01000193U

///|
const HASH_B_OFFSET : UInt = 0x9E3779B9U

///|
const HASH_B_PRIME : UInt = 0x85EBCA6BU

///|
pub type AnimationMask = UInt

///|
fn animation_hash_update(hash : UInt, byte : Int, prime : UInt) -> UInt {
  (hash ^ (byte & 0xFF).reinterpret_as_uint()) * prime
}

///|
fn animation_hash_update_len(hash : UInt, len : Int, prime : UInt) -> UInt {
  let value = len.reinterpret_as_uint()
  let b0 = (value & 0xFFU).reinterpret_as_int()
  let b1 = ((value >> 8) & 0xFFU).reinterpret_as_int()
  let b2 = ((value >> 16) & 0xFFU).reinterpret_as_int()
  let b3 = ((value >> 24) & 0xFFU).reinterpret_as_int()
  let h0 = animation_hash_update(hash, b0, prime)
  let h1 = animation_hash_update(h0, b1, prime)
  let h2 = animation_hash_update(h1, b2, prime)
  animation_hash_update(h2, b3, prime)
}

///|
fn animation_hash_namespace() -> (UInt, UInt) {
  let mut a = HASH_A_OFFSET
  let mut b = HASH_B_OFFSET
  let n = ANIMATION_TARGET_NAMESPACE.length()
  for i in 0..<n {
    let code = ANIMATION_TARGET_NAMESPACE.code_unit_at(i).to_int()
    a = animation_hash_update(a, code, HASH_A_PRIME)
    b = animation_hash_update(b, code, HASH_B_PRIME)
  }
  (a, b)
}

///|
fn animation_hash_names(names : Array[String]) -> (UInt, UInt) {
  let mut state = animation_hash_namespace()
  for name in names {
    let len = name.length()
    let a0 = animation_hash_update_len(state.0, len, HASH_A_PRIME)
    let b0 = animation_hash_update_len(state.1, len, HASH_B_PRIME)
    let mut a = a0
    let mut b = b0
    for i in 0..<len {
      let code = name.code_unit_at(i).to_int()
      a = animation_hash_update(a, code, HASH_A_PRIME)
      b = animation_hash_update(b, code, HASH_B_PRIME)
    }
    state = (a, b)
  }
  state
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimationTargetId {
  high : Int
  low : Int
} derive(Eq, Show)

///|
pub fn AnimationTargetId::new(high : Int, low : Int) -> AnimationTargetId {
  AnimationTargetId::{ high, low }
}

///|
pub fn AnimationTargetId::from_names(
  names : Array[String],
) -> AnimationTargetId {
  let (high, low) = animation_hash_names(names)
  AnimationTargetId::new(high.reinterpret_as_int(), low.reinterpret_as_int())
}

///|
pub fn AnimationTargetId::from_name(name : String) -> AnimationTargetId {
  AnimationTargetId::from_names([name])
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimatedBy {
  player : @core.Entity
}

///|
pub fn AnimatedBy::new(player : @core.Entity) -> AnimatedBy {
  AnimatedBy::{ player, }
}

///|
pub fn AnimatedBy::player(self : AnimatedBy) -> @core.Entity {
  self.player
}

///|
pub struct KeyframeVec3 {
  time : Float
  value : @math.Vec3
}

///|
pub fn KeyframeVec3::new(time : Float, value : @math.Vec3) -> KeyframeVec3 {
  KeyframeVec3::{ time, value }
}

///|
pub struct KeyframeQuat {
  time : Float
  value : @math.Quat
}

///|
pub fn KeyframeQuat::new(time : Float, value : @math.Quat) -> KeyframeQuat {
  KeyframeQuat::{ time, value }
}

///|
pub struct KeyframeWeights {
  time : Float
  value : Array[Float]
}

///|
pub fn KeyframeWeights::new(
  time : Float,
  value : Array[Float],
) -> KeyframeWeights {
  KeyframeWeights::{ time, value }
}

///|
pub struct AnimationTargetCurves {
  translation : Array[KeyframeVec3]
  rotation : Array[KeyframeQuat]
  scale : Array[KeyframeVec3]
  weights : Array[KeyframeWeights]
}

///|
fn animation_target_curves_new() -> AnimationTargetCurves {
  AnimationTargetCurves::{
    translation: [],
    rotation: [],
    scale: [],
    weights: [],
  }
}

///|
pub struct AnimationTargetBinding {
  target_id : AnimationTargetId
  curves : AnimationTargetCurves
}

///|
fn animation_target_binding_new(
  target_id : AnimationTargetId,
) -> AnimationTargetBinding {
  AnimationTargetBinding::{ target_id, curves: animation_target_curves_new() }
}

///|
pub struct AnimationClipEvent {
  time : Float
  label : String
  payload : String
  callback_id : Int?
}

///|
pub fn AnimationClipEvent::new(
  time : Float,
  label : String,
  payload : String,
) -> AnimationClipEvent {
  AnimationClipEvent::{ time, label, payload, callback_id: None }
}

///|
pub fn AnimationClipEvent::new_callback(
  time : Float,
  callback_id : Int,
) -> AnimationClipEvent {
  AnimationClipEvent::{
    time,
    label: "",
    payload: "",
    callback_id: Some(callback_id),
  }
}

///|
pub fn AnimationClipEvent::time(self : AnimationClipEvent) -> Float {
  self.time
}

///|
pub fn AnimationClipEvent::label(self : AnimationClipEvent) -> String {
  self.label
}

///|
pub fn AnimationClipEvent::payload(self : AnimationClipEvent) -> String {
  self.payload
}

///|
pub fn AnimationClipEvent::callback_id(self : AnimationClipEvent) -> Int? {
  self.callback_id
}

///|
pub struct AnimationClip {
  mut duration_seconds : Float
  targets : Array[AnimationTargetBinding]
  events_root : Array[AnimationClipEvent]
  events_targets : Array[(AnimationTargetId, Array[AnimationClipEvent])]
}

///|
pub fn AnimationClip::new() -> AnimationClip {
  AnimationClip::{
    duration_seconds: 0.0F,
    targets: [],
    events_root: [],
    events_targets: [],
  }
}

///|
pub fn AnimationClip::duration(self : AnimationClip) -> Float {
  self.duration_seconds
}

///|
pub fn AnimationClip::set_duration(
  self : AnimationClip,
  duration_seconds : Float,
) -> AnimationClip {
  self.duration_seconds = if duration_seconds < 0.0F {
    0.0F
  } else {
    duration_seconds
  }
  self
}

///|
fn animation_clip_find_target(
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> Int? {
  let mut i = 0
  while i < clip.targets.length() {
    if clip.targets[i].target_id == target_id {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn animation_clip_get_or_insert_target(
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> Int {
  if animation_clip_find_target(clip, target_id) is Some(index) {
    return index
  }
  clip.targets.push(animation_target_binding_new(target_id))
  clip.targets.length() - 1
}

///|
fn keyframe_vec3_sort(keyframes : Array[KeyframeVec3]) -> Unit {
  let mut i = 1
  while i < keyframes.length() {
    let cur = keyframes[i]
    let mut j = i
    while j > 0 && keyframes[j - 1].time > cur.time {
      keyframes[j] = keyframes[j - 1]
      j = j - 1
    }
    keyframes[j] = cur
    i = i + 1
  }
}

///|
fn keyframe_quat_sort(keyframes : Array[KeyframeQuat]) -> Unit {
  let mut i = 1
  while i < keyframes.length() {
    let cur = keyframes[i]
    let mut j = i
    while j > 0 && keyframes[j - 1].time > cur.time {
      keyframes[j] = keyframes[j - 1]
      j = j - 1
    }
    keyframes[j] = cur
    i = i + 1
  }
}

///|
fn keyframe_weights_sort(keyframes : Array[KeyframeWeights]) -> Unit {
  let mut i = 1
  while i < keyframes.length() {
    let cur = keyframes[i]
    let mut j = i
    while j > 0 && keyframes[j - 1].time > cur.time {
      keyframes[j] = keyframes[j - 1]
      j = j - 1
    }
    keyframes[j] = cur
    i = i + 1
  }
}

///|
fn animation_clip_update_duration_from_vec3(
  clip : AnimationClip,
  keyframes : Array[KeyframeVec3],
) -> Unit {
  for keyframe in keyframes {
    if keyframe.time > clip.duration_seconds {
      clip.duration_seconds = keyframe.time
    }
  }
}

///|
fn animation_clip_update_duration_from_quat(
  clip : AnimationClip,
  keyframes : Array[KeyframeQuat],
) -> Unit {
  for keyframe in keyframes {
    if keyframe.time > clip.duration_seconds {
      clip.duration_seconds = keyframe.time
    }
  }
}

///|
fn animation_clip_update_duration_from_weights(
  clip : AnimationClip,
  keyframes : Array[KeyframeWeights],
) -> Unit {
  for keyframe in keyframes {
    if keyframe.time > clip.duration_seconds {
      clip.duration_seconds = keyframe.time
    }
  }
}

///|
pub fn AnimationClip::add_translation_curve(
  self : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeVec3],
) -> AnimationClip {
  let target_index = animation_clip_get_or_insert_target(self, target_id)
  let curves = self.targets[target_index].curves
  curves.translation.clear()
  for keyframe in keyframes {
    curves.translation.push(keyframe)
  }
  keyframe_vec3_sort(curves.translation)
  animation_clip_update_duration_from_vec3(self, curves.translation)
  self
}

///|
pub fn AnimationClip::add_rotation_curve(
  self : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeQuat],
) -> AnimationClip {
  let target_index = animation_clip_get_or_insert_target(self, target_id)
  let curves = self.targets[target_index].curves
  curves.rotation.clear()
  for keyframe in keyframes {
    curves.rotation.push(keyframe)
  }
  keyframe_quat_sort(curves.rotation)
  animation_clip_update_duration_from_quat(self, curves.rotation)
  self
}

///|
pub fn AnimationClip::add_scale_curve(
  self : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeVec3],
) -> AnimationClip {
  let target_index = animation_clip_get_or_insert_target(self, target_id)
  let curves = self.targets[target_index].curves
  curves.scale.clear()
  for keyframe in keyframes {
    curves.scale.push(keyframe)
  }
  keyframe_vec3_sort(curves.scale)
  animation_clip_update_duration_from_vec3(self, curves.scale)
  self
}

///|
pub fn AnimationClip::add_weights_curve(
  self : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeWeights],
) -> AnimationClip {
  let target_index = animation_clip_get_or_insert_target(self, target_id)
  let curves = self.targets[target_index].curves
  curves.weights.clear()
  for keyframe in keyframes {
    curves.weights.push(keyframe)
  }
  keyframe_weights_sort(curves.weights)
  animation_clip_update_duration_from_weights(self, curves.weights)
  self
}

///|
fn animation_clip_event_insert_sorted(
  events : Array[AnimationClipEvent],
  event : AnimationClipEvent,
) -> Unit {
  let mut index = 0
  while index < events.length() && events[index].time <= event.time {
    index = index + 1
  }
  events.push(event)
  let mut i = events.length() - 1
  while i > index {
    let prev = i - 1
    let value = events[i]
    events[i] = events[prev]
    events[prev] = value
    i = prev
  }
}

///|
fn animation_clip_target_events_get_or_insert(
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> Array[AnimationClipEvent] {
  let mut i = 0
  while i < clip.events_targets.length() {
    if clip.events_targets[i].0 == target_id {
      return clip.events_targets[i].1
    }
    i = i + 1
  }
  let events : Array[AnimationClipEvent] = []
  clip.events_targets.push((target_id, events))
  events
}

///|
pub fn AnimationClip::add_event(
  self : AnimationClip,
  time : Float,
  label : String,
  payload : String,
) -> AnimationClip {
  let event = AnimationClipEvent::new(time, label, payload)
  animation_clip_event_insert_sorted(self.events_root, event)
  if time > self.duration_seconds {
    self.duration_seconds = time
  }
  self
}

///|
pub fn AnimationClip::add_event_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  time : Float,
  label : String,
  payload : String,
) -> AnimationClip {
  let event = AnimationClipEvent::new(time, label, payload)
  let events = animation_clip_target_events_get_or_insert(self, target_id)
  animation_clip_event_insert_sorted(events, event)
  if time > self.duration_seconds {
    self.duration_seconds = time
  }
  self
}

///|
pub fn AnimationClip::add_event_fn(
  self : AnimationClip,
  time : Float,
  callback_id : Int,
) -> AnimationClip {
  let event = AnimationClipEvent::new_callback(time, callback_id)
  animation_clip_event_insert_sorted(self.events_root, event)
  if time > self.duration_seconds {
    self.duration_seconds = time
  }
  self
}

///|
pub fn AnimationClip::add_event_fn_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  time : Float,
  callback_id : Int,
) -> AnimationClip {
  let event = AnimationClipEvent::new_callback(time, callback_id)
  let events = animation_clip_target_events_get_or_insert(self, target_id)
  animation_clip_event_insert_sorted(events, event)
  if time > self.duration_seconds {
    self.duration_seconds = time
  }
  self
}

///|
fn animation_clip_events_for_target(
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> Array[AnimationClipEvent]? {
  for entry in clip.events_targets {
    if entry.0 == target_id {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn AnimationClip::events(self : AnimationClip) -> Array[AnimationClipEvent] {
  self.events_root
}

///|
pub fn AnimationClip::events_for_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
) -> Array[AnimationClipEvent]? {
  animation_clip_events_for_target(self, target_id)
}

///|
pub fn AnimationClip::triggered_root_events(
  self : AnimationClip,
  active : ActiveAnimation,
) -> Array[AnimationClipEvent] {
  animation_clip_collect_triggered_events(self.events_root, active)
}

///|
pub fn AnimationClip::triggered_target_events(
  self : AnimationClip,
  target_id : AnimationTargetId,
  active : ActiveAnimation,
) -> Array[AnimationClipEvent] {
  match animation_clip_events_for_target(self, target_id) {
    Some(events) => animation_clip_collect_triggered_events(events, active)
    None => []
  }
}

///|
struct AnimationSample {
  translation : @math.Vec3?
  rotation : @math.Quat?
  scale : @math.Vec3?
  weights : Array[Float]?
}

///|
pub fn AnimationSample::translation(self : AnimationSample) -> @math.Vec3? {
  self.translation
}

///|
pub fn AnimationSample::rotation(self : AnimationSample) -> @math.Quat? {
  self.rotation
}

///|
pub fn AnimationSample::scale(self : AnimationSample) -> @math.Vec3? {
  self.scale
}

///|
pub fn AnimationSample::weights(self : AnimationSample) -> Array[Float]? {
  self.weights
}

///|
fn animation_float_lerp(a : Float, b : Float, t : Float) -> Float {
  a + (b - a) * t
}

///|
fn animation_saturate(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn animation_vec3_lerp(a : @math.Vec3, b : @math.Vec3, t : Float) -> @math.Vec3 {
  @math.Vec3::new(
    animation_float_lerp(a.x, b.x, t),
    animation_float_lerp(a.y, b.y, t),
    animation_float_lerp(a.z, b.z, t),
  )
}

///|
fn animation_quat_normalized(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> @math.Quat {
  let len_sq = x * x + y * y + z * z + w * w
  if len_sq <= 1.0e-12F {
    return @math.Quat::identity()
  }
  @math.Quat::new(x, y, z, w).normalize()
}

///|
fn animation_quat_nlerp(
  a : @math.Quat,
  b : @math.Quat,
  t : Float,
) -> @math.Quat {
  let dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
  let bx = if dot < 0.0F { -b.x } else { b.x }
  let by = if dot < 0.0F { -b.y } else { b.y }
  let bz = if dot < 0.0F { -b.z } else { b.z }
  let bw = if dot < 0.0F { -b.w } else { b.w }
  animation_quat_normalized(
    animation_float_lerp(a.x, bx, t),
    animation_float_lerp(a.y, by, t),
    animation_float_lerp(a.z, bz, t),
    animation_float_lerp(a.w, bw, t),
  )
}

///|
fn animation_weights_lerp(
  a : Array[Float],
  b : Array[Float],
  t : Float,
) -> Array[Float] {
  let len = if a.length() > b.length() { a.length() } else { b.length() }
  let out : Array[Float] = []
  for i in 0..<len {
    let av = match a.get(i) {
      Some(value) => value
      None => 0.0F
    }
    let bv = match b.get(i) {
      Some(value) => value
      None => 0.0F
    }
    out.push(animation_float_lerp(av, bv, t))
  }
  out
}

///|
fn animation_sample_vec3(
  keyframes : Array[KeyframeVec3],
  time_seconds : Float,
) -> @math.Vec3? {
  if keyframes.length() == 0 {
    return None
  }
  if keyframes.length() == 1 {
    return Some(keyframes[0].value)
  }
  if time_seconds <= keyframes[0].time {
    return Some(keyframes[0].value)
  }
  let mut i = 1
  while i < keyframes.length() {
    let right = keyframes[i]
    let left = keyframes[i - 1]
    if time_seconds <= right.time {
      let span = right.time - left.time
      if span <= 0.0F {
        return Some(right.value)
      }
      let t = animation_saturate((time_seconds - left.time) / span)
      return Some(animation_vec3_lerp(left.value, right.value, t))
    }
    i = i + 1
  }
  Some(keyframes[keyframes.length() - 1].value)
}

///|
fn animation_sample_quat(
  keyframes : Array[KeyframeQuat],
  time_seconds : Float,
) -> @math.Quat? {
  if keyframes.length() == 0 {
    return None
  }
  if keyframes.length() == 1 {
    return Some(keyframes[0].value)
  }
  if time_seconds <= keyframes[0].time {
    return Some(keyframes[0].value)
  }
  let mut i = 1
  while i < keyframes.length() {
    let right = keyframes[i]
    let left = keyframes[i - 1]
    if time_seconds <= right.time {
      let span = right.time - left.time
      if span <= 0.0F {
        return Some(right.value)
      }
      let t = animation_saturate((time_seconds - left.time) / span)
      return Some(animation_quat_nlerp(left.value, right.value, t))
    }
    i = i + 1
  }
  Some(keyframes[keyframes.length() - 1].value)
}

///|
fn animation_sample_weights(
  keyframes : Array[KeyframeWeights],
  time_seconds : Float,
) -> Array[Float]? {
  if keyframes.length() == 0 {
    return None
  }
  if keyframes.length() == 1 {
    return Some(keyframes[0].value)
  }
  if time_seconds <= keyframes[0].time {
    return Some(keyframes[0].value)
  }
  let mut i = 1
  while i < keyframes.length() {
    let right = keyframes[i]
    let left = keyframes[i - 1]
    if time_seconds <= right.time {
      let span = right.time - left.time
      if span <= 0.0F {
        return Some(right.value)
      }
      let t = animation_saturate((time_seconds - left.time) / span)
      return Some(animation_weights_lerp(left.value, right.value, t))
    }
    i = i + 1
  }
  Some(keyframes[keyframes.length() - 1].value)
}

///|
pub fn AnimationClip::sample_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  time_seconds : Float,
) -> AnimationSample? {
  guard animation_clip_find_target(self, target_id) is Some(index) else {
    return None
  }
  let curves = self.targets[index].curves
  let translation = animation_sample_vec3(curves.translation, time_seconds)
  let rotation = animation_sample_quat(curves.rotation, time_seconds)
  let scale = animation_sample_vec3(curves.scale, time_seconds)
  let weights = animation_sample_weights(curves.weights, time_seconds)
  if translation is Some(_) ||
    rotation is Some(_) ||
    scale is Some(_) ||
    weights is Some(_) {
    Some(AnimationSample::{ translation, rotation, scale, weights })
  } else {
    None
  }
}

///|
pub(all) enum AnimationEventTarget {
  Root
  Node(AnimationTargetId)
}

///|
pub struct AnimationTriggeredEvent {
  player : @core.Entity
  target : @core.Entity
  target_id : AnimationTargetId?
  time : Float
  weight : Float
  label : String
  payload : String
}

///|
pub fn AnimationTriggeredEvent::player(
  self : AnimationTriggeredEvent,
) -> @core.Entity {
  self.player
}

///|
pub fn AnimationTriggeredEvent::target(
  self : AnimationTriggeredEvent,
) -> @core.Entity {
  self.target
}

///|
pub fn AnimationTriggeredEvent::target_id(
  self : AnimationTriggeredEvent,
) -> AnimationTargetId? {
  self.target_id
}

///|
pub fn AnimationTriggeredEvent::time(self : AnimationTriggeredEvent) -> Float {
  self.time
}

///|
pub fn AnimationTriggeredEvent::weight(self : AnimationTriggeredEvent) -> Float {
  self.weight
}

///|
pub fn AnimationTriggeredEvent::label(self : AnimationTriggeredEvent) -> String {
  self.label
}

///|
pub fn AnimationTriggeredEvent::payload(
  self : AnimationTriggeredEvent,
) -> String {
  self.payload
}

///|
pub struct AnimationNodeIndex {
  index : Int
} derive(Eq, Show)

///|
pub fn AnimationNodeIndex::new(index : Int) -> AnimationNodeIndex {
  AnimationNodeIndex::{ index, }
}

///|
pub fn AnimationNodeIndex::index(self : AnimationNodeIndex) -> Int {
  self.index
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
}

///|
pub fn AnimationGraph::new() -> AnimationGraph {
  let root = AnimationNodeIndex::new(0)
  AnimationGraph::{
    root,
    nodes: [animation_graph_node_new(AnimationNodeType::Blend, 0U, 1.0F, None)],
    mask_groups: [],
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
  let nodes : Array[AnimationNodeIndex] = []
  for clip in clips {
    nodes.push(graph.add_clip(clip, 1.0F, graph.root))
  }
  (graph, nodes)
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
  let mut i = 0
  while i < graph.mask_groups.length() {
    if graph.mask_groups[i].0 == target_id {
      return Some(i)
    }
    i = i + 1
  }
  None
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
let animation_clip_assets : Ref[@asset.Assets[AnimationClip]] = Ref::new(
  @asset.Assets::new(),
)

///|
let animation_graph_assets : Ref[@asset.Assets[AnimationGraph]] = Ref::new(
  @asset.Assets::new(),
)

///|
pub type AnimationEventCallback = (@core.Entity, Float, Float) -> Unit

///|
let animation_event_callbacks : Ref[Array[AnimationEventCallback]] = Ref::new([])

///|
pub fn animation_register_event_callback(
  callback : AnimationEventCallback,
) -> Int {
  animation_event_callbacks.val.push(callback)
  animation_event_callbacks.val.length() - 1
}

///|
fn animation_event_callback_get(callback_id : Int) -> AnimationEventCallback? {
  animation_event_callbacks.val.get(callback_id)
}

///|
let animation_triggered_events : Ref[@core.Messages[AnimationTriggeredEvent]] = Ref::new(
  @core.Messages::new(),
)

///|
pub impl @core.Message for AnimationTriggeredEvent with reader(
  ticks : @core.SystemTicks,
) {
  animation_triggered_events.val.reader(ticks)
}

///|
pub impl @core.Message for AnimationTriggeredEvent with writer(
  tick : @core.Tick,
) {
  animation_triggered_events.val.writer(tick)
}

///|
pub fn animation_clip_add(clip : AnimationClip) -> @asset.Handle[AnimationClip] {
  animation_clip_assets.val.add(clip)
}

///|
pub fn animation_clip_get(
  handle : @asset.Handle[AnimationClip],
) -> AnimationClip? {
  animation_clip_assets.val.get(handle)
}

///|
pub fn animation_clip_set(
  handle : @asset.Handle[AnimationClip],
  clip : AnimationClip,
) -> Bool {
  animation_clip_assets.val.set(handle, clip)
}

///|
pub fn animation_graph_add(
  graph : AnimationGraph,
) -> @asset.Handle[AnimationGraph] {
  animation_graph_assets.val.add(graph)
}

///|
pub fn animation_graph_get(
  handle : @asset.Handle[AnimationGraph],
) -> AnimationGraph? {
  animation_graph_assets.val.get(handle)
}

///|
pub fn animation_graph_set(
  handle : @asset.Handle[AnimationGraph],
  graph : AnimationGraph,
) -> Bool {
  animation_graph_assets.val.set(handle, graph)
}

///|
pub(all) enum RepeatAnimation {
  Never
  Count(Int)
  Forever
}

///|
pub struct ActiveAnimation {
  mut weight : Float
  mut repeat : RepeatAnimation
  mut speed : Float
  mut elapsed : Float
  mut seek_time : Float
  mut last_seek_time : Float?
  mut completions : Int
  mut just_completed : Bool
  mut paused : Bool
}

///|
pub fn ActiveAnimation::default() -> ActiveAnimation {
  ActiveAnimation::{
    weight: 1.0F,
    repeat: RepeatAnimation::Never,
    speed: 1.0F,
    elapsed: 0.0F,
    seek_time: 0.0F,
    last_seek_time: None,
    completions: 0,
    just_completed: false,
    paused: false,
  }
}

///|
pub fn ActiveAnimation::weight(self : ActiveAnimation) -> Float {
  self.weight
}

///|
pub fn ActiveAnimation::seek_time(self : ActiveAnimation) -> Float {
  self.seek_time
}

///|
pub fn ActiveAnimation::completions(self : ActiveAnimation) -> Int {
  self.completions
}

///|
pub fn ActiveAnimation::just_completed(self : ActiveAnimation) -> Bool {
  self.just_completed
}

///|
pub fn ActiveAnimation::is_paused(self : ActiveAnimation) -> Bool {
  self.paused
}

///|
pub fn ActiveAnimation::is_finished(self : ActiveAnimation) -> Bool {
  match self.repeat {
    RepeatAnimation::Forever => false
    RepeatAnimation::Never => self.completions >= 1
    RepeatAnimation::Count(n) => self.completions >= n
  }
}

///|
pub fn ActiveAnimation::set_weight(
  self : ActiveAnimation,
  weight : Float,
) -> ActiveAnimation {
  ActiveAnimation::{ ..self, weight: if weight < 0.0F { 0.0F } else { weight } }
}

///|
pub fn ActiveAnimation::set_repeat(
  self : ActiveAnimation,
  repeat : RepeatAnimation,
) -> ActiveAnimation {
  ActiveAnimation::{ ..self, repeat, }
}

///|
pub fn ActiveAnimation::repeat_forever(
  self : ActiveAnimation,
) -> ActiveAnimation {
  self.set_repeat(RepeatAnimation::Forever)
}

///|
pub fn ActiveAnimation::repeat(self : ActiveAnimation) -> ActiveAnimation {
  self.repeat_forever()
}

///|
pub fn ActiveAnimation::repeat_mode(self : ActiveAnimation) -> RepeatAnimation {
  self.repeat
}

///|
pub fn ActiveAnimation::set_speed(
  self : ActiveAnimation,
  speed : Float,
) -> ActiveAnimation {
  ActiveAnimation::{ ..self, speed, }
}

///|
pub fn ActiveAnimation::speed(self : ActiveAnimation) -> Float {
  self.speed
}

///|
pub fn ActiveAnimation::elapsed(self : ActiveAnimation) -> Float {
  self.elapsed
}

///|
pub fn ActiveAnimation::is_playback_reversed(self : ActiveAnimation) -> Bool {
  self.speed < 0.0F
}

///|
pub fn ActiveAnimation::pause(self : ActiveAnimation) -> ActiveAnimation {
  ActiveAnimation::{ ..self, paused: true }
}

///|
pub fn ActiveAnimation::unpause(self : ActiveAnimation) -> ActiveAnimation {
  ActiveAnimation::{ ..self, paused: false }
}

///|
pub fn ActiveAnimation::resume_playback(
  self : ActiveAnimation,
) -> ActiveAnimation {
  self.unpause()
}

///|
pub fn ActiveAnimation::set_seek_time(
  self : ActiveAnimation,
  seek_time : Float,
) -> ActiveAnimation {
  ActiveAnimation::{ ..self, seek_time, last_seek_time: Some(seek_time) }
}

///|
pub fn ActiveAnimation::seek_to(
  self : ActiveAnimation,
  seek_time : Float,
) -> ActiveAnimation {
  ActiveAnimation::{ ..self, seek_time, last_seek_time: Some(self.seek_time) }
}

///|
pub fn ActiveAnimation::rewind(self : ActiveAnimation) -> ActiveAnimation {
  self.seek_to(0.0F)
}

///|
pub fn ActiveAnimation::replay(self : ActiveAnimation) -> ActiveAnimation {
  ActiveAnimation::{
    ..self,
    elapsed: 0.0F,
    seek_time: 0.0F,
    last_seek_time: None,
    completions: 0,
    just_completed: false,
    paused: false,
  }
}

///|
fn active_animation_wrap_time(seek_time : Float, duration : Float) -> Float {
  if duration <= 0.0F {
    return 0.0F
  }
  let mut out = seek_time
  while out >= duration {
    out = out - duration
  }
  while out < 0.0F {
    out = out + duration
  }
  out
}

///|
pub fn ActiveAnimation::update(
  self : ActiveAnimation,
  delta_seconds : Float,
  clip_duration_seconds : Float,
) -> ActiveAnimation {
  let out = ActiveAnimation::{
    ..self,
    just_completed: false,
    last_seek_time: Some(self.seek_time),
  }
  if out.paused || out.is_finished() {
    return out
  }
  if clip_duration_seconds <= 0.0F {
    out.elapsed = out.elapsed + delta_seconds
    return out
  }

  out.elapsed = out.elapsed + delta_seconds
  out.seek_time = out.seek_time + delta_seconds * out.speed

  let passed_end = out.speed >= 0.0F && out.seek_time >= clip_duration_seconds
  let passed_start = out.speed < 0.0F && out.seek_time < 0.0F

  if passed_end || passed_start {
    out.just_completed = true
    out.completions = out.completions + 1
    if out.is_finished() {
      out.seek_time = if out.speed >= 0.0F {
        clip_duration_seconds
      } else {
        0.0F
      }
      return out
    }
  }

  out.seek_time = active_animation_wrap_time(
    out.seek_time,
    clip_duration_seconds,
  )
  out
}

///|
fn animation_player_find(
  player : AnimationPlayer,
  node : AnimationNodeIndex,
) -> Int? {
  let mut i = 0
  while i < player.active_animations.length() {
    if player.active_animations[i].0 == node {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimationPlayer {
  active_animations : Array[(AnimationNodeIndex, ActiveAnimation)]
}

///|
pub fn AnimationPlayer::default() -> AnimationPlayer {
  AnimationPlayer::{ active_animations: [] }
}

///|
pub fn AnimationPlayer::playing_animations(
  self : AnimationPlayer,
) -> Array[(AnimationNodeIndex, ActiveAnimation)] {
  self.active_animations
}

///|
pub fn AnimationPlayer::animation(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> ActiveAnimation? {
  if animation_player_find(self, node) is Some(index) {
    Some(self.active_animations[index].1)
  } else {
    None
  }
}

///|
pub fn AnimationPlayer::is_playing_animation(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> Bool {
  self.animation(node) is Some(_)
}

///|
pub fn AnimationPlayer::set_weight(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
  weight : Float,
) -> AnimationPlayer {
  guard self.animation(node) is Some(active) else { return self }
  self.set_animation(node, active.set_weight(weight))
}

///|
pub fn AnimationPlayer::set_speed(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
  speed : Float,
) -> AnimationPlayer {
  guard self.animation(node) is Some(active) else { return self }
  self.set_animation(node, active.set_speed(speed))
}

///|
pub fn AnimationPlayer::seek_to(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
  seek_time : Float,
) -> AnimationPlayer {
  guard self.animation(node) is Some(active) else { return self }
  self.set_animation(node, active.seek_to(seek_time))
}

///|
pub fn AnimationPlayer::set_animation(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
  active : ActiveAnimation,
) -> AnimationPlayer {
  if animation_player_find(self, node) is Some(index) {
    self.active_animations[index] = (node, active)
  } else {
    self.active_animations.push((node, active))
  }
  self
}

///|
pub fn AnimationPlayer::start(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayer {
  let active = match self.animation(node) {
    Some(existing) => existing.replay()
    None => ActiveAnimation::default()
  }
  self.set_animation(node, active)
}

///|
pub fn AnimationPlayer::play(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayer {
  if self.animation(node) is Some(_) {
    return self
  }
  self.active_animations.push((node, ActiveAnimation::default()))
  self
}

///|
pub fn AnimationPlayer::stop(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayer {
  if animation_player_find(self, node) is Some(index) {
    let last = self.active_animations.length() - 1
    self.active_animations[index] = self.active_animations[last]
    self.active_animations.pop() |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::stop_all(self : AnimationPlayer) -> AnimationPlayer {
  self.active_animations.clear()
  self
}

///|
pub fn AnimationPlayer::all_finished(self : AnimationPlayer) -> Bool {
  for pair in self.active_animations {
    if !pair.1.is_finished() {
      return false
    }
  }
  true
}

///|
fn animation_player_tick(
  player : AnimationPlayer,
  graph : AnimationGraph,
  delta_seconds : Float,
) -> AnimationPlayer {
  let mut i = 0
  while i < player.active_animations.length() {
    let (node, active) = player.active_animations[i]
    let mut next_active = active
    if active.is_paused() {
      ()
    } else if graph.get(node) is Some(graph_node) {
      if graph_node.node_type is Clip(clip_handle) {
        if animation_clip_get(clip_handle) is Some(clip) {
          next_active = active.update(delta_seconds, clip.duration())
        }
      }
    }
    player.active_animations[i] = (node, next_active)
    i = i + 1
  }
  player
}

///|
pub struct AnimationTransition {
  mut current_weight : Float
  weight_decline_per_sec : Float
  animation : AnimationNodeIndex
}

///|
fn animation_transition_new(
  current_weight : Float,
  weight_decline_per_sec : Float,
  animation : AnimationNodeIndex,
) -> AnimationTransition {
  AnimationTransition::{ current_weight, weight_decline_per_sec, animation }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimationTransitions {
  mut main_animation : AnimationNodeIndex?
  transitions : Array[AnimationTransition]
}

///|
pub fn AnimationTransitions::new() -> AnimationTransitions {
  AnimationTransitions::{ main_animation: None, transitions: [] }
}

///|
pub fn AnimationTransitions::main_animation(
  self : AnimationTransitions,
) -> AnimationNodeIndex? {
  self.main_animation
}

///|
fn animation_transitions_remove_for_animation(
  transitions : AnimationTransitions,
  node : AnimationNodeIndex,
) -> Unit {
  let mut i = 0
  while i < transitions.transitions.length() {
    if transitions.transitions[i].animation == node {
      let last = transitions.transitions.length() - 1
      transitions.transitions[i] = transitions.transitions[last]
      transitions.transitions.pop() |> ignore
    } else {
      i = i + 1
    }
  }
}

///|
pub fn AnimationTransitions::play(
  self : AnimationTransitions,
  player : AnimationPlayer,
  new_animation : AnimationNodeIndex,
  transition_duration_seconds : Float,
) -> (AnimationTransitions, AnimationPlayer) {
  let mut next_player = player
  if self.main_animation is Some(old_animation) {
    if old_animation != new_animation {
      if next_player.animation(old_animation) is Some(old_active) {
        if !old_active.is_paused() {
          if transition_duration_seconds <= 0.0F {
            next_player = next_player.stop(old_animation)
          } else {
            self.transitions.push(
              animation_transition_new(
                old_active.weight(),
                1.0F / transition_duration_seconds,
                old_animation,
              ),
            )
          }
        }
      }
    }
  }

  self.main_animation = Some(new_animation)
  animation_transitions_remove_for_animation(self, new_animation)
  next_player = next_player.start(new_animation)
  (self, next_player)
}

///|
fn animation_transitions_advance(
  transitions : AnimationTransitions,
  player : AnimationPlayer,
  delta_seconds : Float,
) -> (AnimationTransitions, AnimationPlayer) {
  let mut next_player = player
  let mut remaining_weight = 1.0F
  let mut i = transitions.transitions.length() - 1
  while i >= 0 && i < transitions.transitions.length() {
    let transition = transitions.transitions[i]
    transition.current_weight = transition.current_weight -
      transition.weight_decline_per_sec * delta_seconds
    if transition.current_weight < 0.0F {
      transition.current_weight = 0.0F
    }

    if next_player.animation(transition.animation) is Some(active) {
      let weight = transition.current_weight * remaining_weight
      next_player = next_player.set_animation(
        transition.animation,
        active.set_weight(weight),
      )
      remaining_weight = remaining_weight - weight
      if remaining_weight < 0.0F {
        remaining_weight = 0.0F
      }
    }

    if i == 0 {
      break
    }
    i = i - 1
  }

  if transitions.main_animation is Some(main_animation) {
    if next_player.animation(main_animation) is Some(active) {
      next_player = next_player.set_animation(
        main_animation,
        active.set_weight(remaining_weight),
      )
    }
  }

  (transitions, next_player)
}

///|
fn animation_transitions_expire(
  transitions : AnimationTransitions,
  player : AnimationPlayer,
) -> (AnimationTransitions, AnimationPlayer) {
  let mut next_player = player
  let mut i = 0
  while i < transitions.transitions.length() {
    let transition = transitions.transitions[i]
    if transition.current_weight <= 0.0F {
      next_player = next_player.stop(transition.animation)
      let last = transitions.transitions.length() - 1
      transitions.transitions[i] = transitions.transitions[last]
      transitions.transitions.pop() |> ignore
    } else {
      i = i + 1
    }
  }
  (transitions, next_player)
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimationGraphHandle {
  graph : @asset.Handle[AnimationGraph]
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
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct AnimationWeights {
  values : Array[Float]
}

///|
pub fn AnimationWeights::new(values : Array[Float]) -> AnimationWeights {
  AnimationWeights::{ values, }
}

///|
pub fn AnimationWeights::values(self : AnimationWeights) -> Array[Float] {
  self.values
}

///|
fn animation_weights_accumulate(
  accum : Array[Float],
  values : Array[Float],
  weight : Float,
) -> Unit {
  let mut i = 0
  while i < values.length() {
    if i >= accum.length() {
      accum.push(0.0F)
    }
    accum[i] = accum[i] + values[i] * weight
    i = i + 1
  }
}

///|
fn animation_weights_blend(
  base : Array[Float],
  accum : Array[Float],
  total_weight : Float,
) -> Array[Float] {
  let base_weight = animation_saturate(1.0F - total_weight)
  let len = if base.length() > accum.length() {
    base.length()
  } else {
    accum.length()
  }
  let out : Array[Float] = []
  for i in 0..<len {
    let base_value = match base.get(i) {
      Some(value) => value * base_weight
      None => 0.0F
    }
    let accum_value = match accum.get(i) {
      Some(value) => value
      None => 0.0F
    }
    out.push(base_value + accum_value)
  }
  out
}

///|
fn animation_apply_player_to_target(
  target_id : AnimationTargetId,
  target_mask : AnimationMask,
  player : AnimationPlayer,
  graph : AnimationGraph,
  base_transform : @math.Transform?,
  base_weights : AnimationWeights?,
) -> (@math.Transform?, AnimationWeights?) {
  let mut has_translation = false
  let mut has_rotation = false
  let mut has_scale = false
  let mut has_weights = false

  let mut translation_weight = 0.0F
  let mut rotation_weight = 0.0F
  let mut scale_weight = 0.0F
  let mut weights_weight = 0.0F

  let mut translation_acc = @math.Vec3::zero()
  let mut scale_acc = @math.Vec3::zero()

  let mut rotation_acc_x = 0.0F
  let mut rotation_acc_y = 0.0F
  let mut rotation_acc_z = 0.0F
  let mut rotation_acc_w = 0.0F

  let weights_acc : Array[Float] = []

  for pair in player.playing_animations() {
    let node_index = pair.0
    let active = pair.1
    guard graph.get(node_index) is Some(node) else { continue }
    guard node.node_type is Clip(clip_handle) else { continue }
    guard animation_clip_get(clip_handle) is Some(clip) else { continue }

    let computed_mask = graph.computed_mask(node_index)
    if (target_mask & computed_mask) != 0U {
      continue
    }

    let combined_weight = active.weight() * graph.effective_weight(node_index)
    if combined_weight <= 0.0F {
      continue
    }

    guard clip.sample_target(target_id, active.seek_time()) is Some(sample) else {
      continue
    }

    if sample.translation is Some(translation) {
      has_translation = true
      translation_weight = translation_weight + combined_weight
      translation_acc = translation_acc.add(
        translation.mul_scalar(combined_weight),
      )
    }

    if sample.rotation is Some(rotation) {
      has_rotation = true
      rotation_weight = rotation_weight + combined_weight
      rotation_acc_x = rotation_acc_x + rotation.x * combined_weight
      rotation_acc_y = rotation_acc_y + rotation.y * combined_weight
      rotation_acc_z = rotation_acc_z + rotation.z * combined_weight
      rotation_acc_w = rotation_acc_w + rotation.w * combined_weight
    }

    if sample.scale is Some(scale) {
      has_scale = true
      scale_weight = scale_weight + combined_weight
      scale_acc = scale_acc.add(scale.mul_scalar(combined_weight))
    }

    if sample.weights is Some(weights) {
      has_weights = true
      weights_weight = weights_weight + combined_weight
      animation_weights_accumulate(weights_acc, weights, combined_weight)
    }
  }

  let transform_out = if has_translation || has_rotation || has_scale {
    let base = match base_transform {
      Some(transform) => transform
      None => @math.Transform::identity()
    }
    let translation = if has_translation {
      let base_weight = animation_saturate(1.0F - translation_weight)
      base.translation.mul_scalar(base_weight).add(translation_acc)
    } else {
      base.translation
    }
    let scale = if has_scale {
      let base_weight = animation_saturate(1.0F - scale_weight)
      base.scale.mul_scalar(base_weight).add(scale_acc)
    } else {
      base.scale
    }
    let rotation = if has_rotation {
      let base_weight = animation_saturate(1.0F - rotation_weight)
      let x = base.rotation.x * base_weight + rotation_acc_x
      let y = base.rotation.y * base_weight + rotation_acc_y
      let z = base.rotation.z * base_weight + rotation_acc_z
      let w = base.rotation.w * base_weight + rotation_acc_w
      animation_quat_normalized(x, y, z, w)
    } else {
      base.rotation
    }
    Some(@math.Transform::new(translation, rotation, scale))
  } else {
    None
  }

  let weights_out = if has_weights {
    let base_values = match base_weights {
      Some(weights) => weights.values
      None => []
    }
    Some(
      AnimationWeights::new(
        animation_weights_blend(base_values, weights_acc, weights_weight),
      ),
    )
  } else {
    None
  }

  (transform_out, weights_out)
}

///|
pub(all) enum AnimationTriggeredEventsDirection {
  Forward
  Reverse
  ForwardLooping
  ReverseLooping
}

///|
fn animation_clip_collect_triggered_events(
  events : Array[AnimationClipEvent],
  active : ActiveAnimation,
) -> Array[AnimationClipEvent] {
  let triggered : Array[AnimationClipEvent] = []
  if events.length() == 0 {
    return triggered
  }

  let reverse = active.is_playback_reversed()
  let finished = active.is_finished()
  if finished && !active.just_completed() {
    return triggered
  }
  guard active.last_seek_time is Some(last_time) else { return triggered }
  let this_time = active.seek_time()
  let looping = active.just_completed() && !finished
  let direction = match (reverse, looping) {
    (false, false) => AnimationTriggeredEventsDirection::Forward
    (false, true) => AnimationTriggeredEventsDirection::ForwardLooping
    (true, false) => AnimationTriggeredEventsDirection::Reverse
    (true, true) => AnimationTriggeredEventsDirection::ReverseLooping
  }

  match direction {
    Forward =>
      for event in events {
        if event.time >= last_time && (finished || event.time < this_time) {
          triggered.push(event)
        }
      }
    Reverse => {
      let mut i = events.length() - 1
      while i < events.length() {
        let event = events[i]
        if event.time <= last_time && (finished || event.time > this_time) {
          triggered.push(event)
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
    }
    ForwardLooping => {
      for event in events {
        if event.time >= last_time {
          triggered.push(event)
        }
      }
      for event in events {
        if event.time < this_time {
          triggered.push(event)
        }
      }
    }
    ReverseLooping => {
      let mut i = events.length() - 1
      while i < events.length() {
        let event = events[i]
        if event.time <= last_time {
          triggered.push(event)
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
      let mut j = events.length() - 1
      while j < events.length() {
        let event = events[j]
        if event.time > this_time {
          triggered.push(event)
        }
        if j == 0 {
          break
        }
        j = j - 1
      }
    }
  }

  triggered
}

///|
fn animation_emit_triggered_events(
  writer : @core.MessageWriter[AnimationTriggeredEvent],
  player_entity : @core.Entity,
  target_entity : @core.Entity,
  target_id : AnimationTargetId?,
  active : ActiveAnimation,
  events : Array[AnimationClipEvent],
) -> Unit {
  for event in events {
    if event.callback_id is Some(callback_id) {
      if animation_event_callback_get(callback_id) is Some(callback) {
        callback(target_entity, event.time, active.weight())
      }
    }
    writer.write({
      player: player_entity,
      target: target_entity,
      target_id,
      time: event.time,
      weight: active.weight(),
      label: event.label,
      payload: event.payload,
    })
  }
}

///|
pub let animation_set_thread : @app.SystemSet = @app.system_set(
  "mgstudio.animation.thread",
)

///|
pub let animation_set_advance_transitions : @app.SystemSet = @app.system_set(
  "mgstudio.animation.advance_transitions",
)

///|
pub let animation_set_advance_animations : @app.SystemSet = @app.system_set(
  "mgstudio.animation.advance_animations",
)

///|
pub let animation_set_animate_targets : @app.SystemSet = @app.system_set(
  "mgstudio.animation.animate_targets",
)

///|
pub let animation_set_trigger_events : @app.SystemSet = @app.system_set(
  "mgstudio.animation.trigger_events",
)

///|
pub let animation_set_expire_transitions : @app.SystemSet = @app.system_set(
  "mgstudio.animation.expire_transitions",
)

///|
pub(open) trait AdvanceTransitionsWorld: Has_AnimationTransitions + Has_AnimationPlayer + @core.ChangeTickWorld {
}

///|
pub(open) trait AdvanceAnimationsWorld: Has_AnimationPlayer + Has_AnimationGraphHandle + @core.ChangeTickWorld {
}

///|
pub(open) trait AnimateTargetsWorld: Has_AnimationTargetId + Has_AnimatedBy + Has_AnimationPlayer + Has_AnimationGraphHandle + @math.Has_Transform + Has_AnimationWeights + @core.ChangeTickWorld {
}

///|
pub(open) trait TriggerEventsWorld: Has_AnimationPlayer + Has_AnimationGraphHandle + Has_AnimationTargetId + Has_AnimatedBy + @core.ChangeTickWorld {
}

///|
pub(open) trait ExpireTransitionsWorld: Has_AnimationTransitions + Has_AnimationPlayer + @core.ChangeTickWorld {
}

///|
pub(open) trait AnimationPluginWorld: AdvanceTransitionsWorld + AdvanceAnimationsWorld + AnimateTargetsWorld + TriggerEventsWorld + ExpireTransitionsWorld {
}

///|
pub fn[W] thread_animation_graphs(_world : W) -> Unit {
  // Stub for future threaded graph acceleration structures.
}

///|
pub fn[W : AdvanceTransitionsWorld] advance_transitions(world : W) -> Unit {
  let transitions_store = world.get_animation_transitions_store()
  let player_store = world.get_animation_player_store()
  let tick = world.read_change_tick()
  let delta_seconds = @time.time_delta_seconds()

  let updates : Array[(@core.Entity, AnimationTransitions, AnimationPlayer)] = []
  transitions_store.for_each(fn(entity, transitions) {
    guard player_store.get(entity) is Some(player) else { return }
    let (next_transitions, next_player) = animation_transitions_advance(
      transitions, player, delta_seconds,
    )
    updates.push((entity, next_transitions, next_player))
  })

  for update in updates {
    transitions_store.set(update.0, update.1, tick) |> ignore
    player_store.set(update.0, update.2, tick) |> ignore
  }
}

///|
pub fn[W : AdvanceAnimationsWorld] advance_animations(world : W) -> Unit {
  let player_store = world.get_animation_player_store()
  let graph_handle_store = world.get_animation_graph_handle_store()
  let tick = world.read_change_tick()
  let delta_seconds = @time.time_delta_seconds()

  let updates : Array[(@core.Entity, AnimationPlayer)] = []
  player_store.for_each(fn(entity, player) {
    guard graph_handle_store.get(entity) is Some(graph_handle) else { return }
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    updates.push((entity, animation_player_tick(player, graph, delta_seconds)))
  })

  for update in updates {
    player_store.set(update.0, update.1, tick) |> ignore
  }
}

///|
pub fn[W : AnimateTargetsWorld] animate_targets(world : W) -> Unit {
  let target_id_store = world.get_animation_target_id_store()
  let animated_by_store = world.get_animated_by_store()
  let player_store = world.get_animation_player_store()
  let graph_handle_store = world.get_animation_graph_handle_store()
  let transform_store = world.get_transform_store()
  let weights_store = world.get_animation_weights_store()
  let tick = world.read_change_tick()

  let transform_updates : Array[(@core.Entity, @math.Transform)] = []
  let weights_updates : Array[(@core.Entity, AnimationWeights)] = []

  target_id_store.for_each(fn(entity, target_id) {
    guard animated_by_store.get(entity) is Some(animated_by) else { return }
    guard player_store.get(animated_by.player()) is Some(player) else { return }
    guard graph_handle_store.get(animated_by.player()) is Some(graph_handle) else {
      return
    }
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    let target_mask = graph.target_mask(target_id)

    let (next_transform, next_weights) = animation_apply_player_to_target(
      target_id,
      target_mask,
      player,
      graph,
      transform_store.get(entity),
      weights_store.get(entity),
    )

    if next_transform is Some(transform) {
      transform_updates.push((entity, transform))
    }
    if next_weights is Some(weights) {
      weights_updates.push((entity, weights))
    }
  })

  for update in transform_updates {
    if transform_store.contains(update.0) {
      transform_store.set(update.0, update.1, tick) |> ignore
    } else {
      transform_store.insert(update.0, update.1, tick)
    }
  }

  for update in weights_updates {
    if weights_store.contains(update.0) {
      weights_store.set(update.0, update.1, tick) |> ignore
    } else {
      weights_store.insert(update.0, update.1, tick)
    }
  }
}

///|
pub fn[W : TriggerEventsWorld] trigger_events(world : W) -> Unit {
  let player_store = world.get_animation_player_store()
  let graph_handle_store = world.get_animation_graph_handle_store()
  let target_id_store = world.get_animation_target_id_store()
  let animated_by_store = world.get_animated_by_store()
  let tick = world.read_change_tick()
  let writer : @core.MessageWriter[AnimationTriggeredEvent] = @core.Message::writer(
    tick,
  )

  // Root (untargeted) events fire on the player entity.
  player_store.for_each(fn(player_entity, player) {
    guard graph_handle_store.get(player_entity) is Some(graph_handle) else {
      return
    }
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    for pair in player.playing_animations() {
      let node_index = pair.0
      let active = pair.1
      if active.is_paused() {
        continue
      }
      guard graph.get(node_index) is Some(node) else { continue }
      guard node.node_type is Clip(clip_handle) else { continue }
      guard animation_clip_get(clip_handle) is Some(clip) else { continue }
      let triggered = animation_clip_collect_triggered_events(
        clip.events_root,
        active,
      )
      if triggered.length() == 0 {
        continue
      }
      animation_emit_triggered_events(
        writer,
        player_entity,
        player_entity,
        None,
        active,
        triggered,
      )
    }
  })

  // Targeted events fire on the animated target entity.
  target_id_store.for_each(fn(target_entity, target_id) {
    guard animated_by_store.get(target_entity) is Some(animated_by) else {
      return
    }
    let player_entity = animated_by.player()
    guard player_store.get(player_entity) is Some(player) else { return }
    guard graph_handle_store.get(player_entity) is Some(graph_handle) else {
      return
    }
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    let target_mask = graph.target_mask(target_id)
    for pair in player.playing_animations() {
      let node_index = pair.0
      let active = pair.1
      if active.is_paused() {
        continue
      }
      guard graph.get(node_index) is Some(node) else { continue }
      guard node.node_type is Clip(clip_handle) else { continue }
      if (target_mask & graph.computed_mask(node_index)) != 0U {
        continue
      }
      let combined_weight = active.weight() * graph.effective_weight(node_index)
      if combined_weight <= 0.0F {
        continue
      }
      guard animation_clip_get(clip_handle) is Some(clip) else { continue }
      guard animation_clip_events_for_target(clip, target_id) is Some(events) else {
        continue
      }
      let triggered = animation_clip_collect_triggered_events(events, active)
      if triggered.length() == 0 {
        continue
      }
      animation_emit_triggered_events(
        writer,
        player_entity,
        target_entity,
        Some(target_id),
        active,
        triggered,
      )
    }
  })
}

///|
pub fn[W : ExpireTransitionsWorld] expire_transitions(world : W) -> Unit {
  let transitions_store = world.get_animation_transitions_store()
  let player_store = world.get_animation_player_store()
  let tick = world.read_change_tick()

  let updates : Array[(@core.Entity, AnimationTransitions, AnimationPlayer)] = []
  transitions_store.for_each(fn(entity, transitions) {
    guard player_store.get(entity) is Some(player) else { return }
    let (next_transitions, next_player) = animation_transitions_expire(
      transitions, player,
    )
    updates.push((entity, next_transitions, next_player))
  })

  for update in updates {
    transitions_store.set(update.0, update.1, tick) |> ignore
    player_store.set(update.0, update.2, tick) |> ignore
  }
}

///|
pub fn[W : AnimationPluginWorld] animation_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_post_update_system_config(
    @app.system(thread_animation_graphs).in_set(animation_set_thread),
  )
  .add_post_update_system_config(
    @app.system(advance_transitions).in_set(animation_set_advance_transitions),
  )
  .add_post_update_system_config(
    @app.system(advance_animations).in_set(animation_set_advance_animations),
  )
  .add_post_update_system_config(
    @app.system(animate_targets).in_set(animation_set_animate_targets),
  )
  .add_post_update_system_config(
    @app.system(trigger_events).in_set(animation_set_trigger_events),
  )
  .add_post_update_system_config(
    @app.system(expire_transitions).in_set(animation_set_expire_transitions),
  )
  .configure_set(@app.PostUpdate, animation_set_thread, before=[
    animation_set_advance_transitions,
  ])
  .configure_set(@app.PostUpdate, animation_set_advance_transitions, before=[
    animation_set_advance_animations,
  ])
  .configure_set(@app.PostUpdate, animation_set_advance_animations, before=[
    animation_set_animate_targets,
  ])
  .configure_set(@app.PostUpdate, animation_set_animate_targets, before=[
    animation_set_trigger_events,
  ])
  .configure_set(@app.PostUpdate, animation_set_trigger_events, before=[
    animation_set_expire_transitions,
  ])
}
