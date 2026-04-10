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
// Bevy source: `bevy/crates/bevy_animation/src/animation_curves.rs`.
// Animation curve/keyframe runtime + clip curve APIs.

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
pub struct KeyframeColor {
  time : Float
  value : @sprite.Color
}

///|
pub fn KeyframeColor::new(time : Float, value : @sprite.Color) -> KeyframeColor {
  KeyframeColor::{ time, value }
}

///|
pub(all) enum AnimatableCurve {
  Translation(@math.Curve[@math.Vec3])
  Rotation(@math.Curve[@math.Quat])
  Scale(@math.Curve[@math.Vec3])
  TextColor(@math.Curve[@sprite.Color])
}

///|
pub struct AnimationTargetCurves {
  translation : Array[KeyframeVec3]
  rotation : Array[KeyframeQuat]
  scale : Array[KeyframeVec3]
  weights : Array[KeyframeWeights]
  text_color : Array[KeyframeColor]
}

///|
fn animation_target_curves_new() -> AnimationTargetCurves {
  AnimationTargetCurves::{
    translation: [],
    rotation: [],
    scale: [],
    weights: [],
    text_color: [],
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
pub struct AnimationClip {
  mut duration_seconds : Float
  targets : Array[AnimationTargetBinding]
  target_index_by_key : Map[UInt64, Int]
  events_root : Array[AnimationClipEvent]
  events_targets : Array[(AnimationTargetId, Array[AnimationClipEvent])]
}

///|
pub fn AnimationClip::new() -> AnimationClip {
  AnimationClip::{
    duration_seconds: 0.0F,
    targets: [],
    target_index_by_key: {},
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

fn animation_clip_find_target(
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> Int? {
  let target_key = animation_target_id_lookup_key(target_id)
  if clip.target_index_by_key.get(target_key) is Some(index) &&
    index >= 0 &&
    index < clip.targets.length() &&
    clip.targets[index].target_id == target_id {
    return Some(index)
  }
  let mut i = 0
  while i < clip.targets.length() {
    if clip.targets[i].target_id == target_id {
      clip.target_index_by_key.set(target_key, i)
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
  let index = clip.targets.length() - 1
  clip.target_index_by_key.set(animation_target_id_lookup_key(target_id), index)
  index
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
fn keyframe_color_sort(keyframes : Array[KeyframeColor]) -> Unit {
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
fn animation_clip_update_duration_from_color(
  clip : AnimationClip,
  keyframes : Array[KeyframeColor],
) -> Unit {
  for keyframe in keyframes {
    if keyframe.time > clip.duration_seconds {
      clip.duration_seconds = keyframe.time
    }
  }
}

///|
fn animation_curve_sample_times_or_abort(
  domain : @math.Interval,
  sample_count : Int,
) -> Array[Float] {
  let points = if sample_count < 2 { 2 } else { sample_count }
  domain.spaced_points(points) catch {
    _ => abort("animation curve authoring expects a bounded domain")
  }
}

///|
fn animation_curve_sample_vec3_keyframes(
  curve : @math.Curve[@math.Vec3],
  sample_count : Int,
) -> Array[KeyframeVec3] {
  let keyframes : Array[KeyframeVec3] = []
  for
    time in animation_curve_sample_times_or_abort(curve.domain(), sample_count) {
    keyframes.push(KeyframeVec3::new(time, curve.sample_clamped(time)))
  }
  keyframes
}

///|
fn animation_curve_sample_quat_keyframes(
  curve : @math.Curve[@math.Quat],
  sample_count : Int,
) -> Array[KeyframeQuat] {
  let keyframes : Array[KeyframeQuat] = []
  for
    time in animation_curve_sample_times_or_abort(curve.domain(), sample_count) {
    keyframes.push(KeyframeQuat::new(time, curve.sample_clamped(time)))
  }
  keyframes
}

///|
fn animation_curve_sample_color_keyframes(
  curve : @math.Curve[@sprite.Color],
  sample_count : Int,
) -> Array[KeyframeColor] {
  let keyframes : Array[KeyframeColor] = []
  for
    time in animation_curve_sample_times_or_abort(curve.domain(), sample_count) {
    keyframes.push(KeyframeColor::new(time, curve.sample_clamped(time)))
  }
  keyframes
}

///|
pub fn AnimationClip::add_curve_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  curve : AnimatableCurve,
  sample_count? : Int = 121,
) -> AnimationClip {
  match curve {
    Translation(translation_curve) =>
      self.add_translation_curve(
        target_id,
        animation_curve_sample_vec3_keyframes(translation_curve, sample_count),
      )
    Rotation(rotation_curve) =>
      self.add_rotation_curve(
        target_id,
        animation_curve_sample_quat_keyframes(rotation_curve, sample_count),
      )
    Scale(scale_curve) =>
      self.add_scale_curve(
        target_id,
        animation_curve_sample_vec3_keyframes(scale_curve, sample_count),
      )
    TextColor(text_color_curve) =>
      self.add_text_color_curve(
        target_id,
        animation_curve_sample_color_keyframes(text_color_curve, sample_count),
      )
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
pub fn AnimationClip::add_text_color_curve(
  self : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeColor],
) -> AnimationClip {
  let target_index = animation_clip_get_or_insert_target(self, target_id)
  let curves = self.targets[target_index].curves
  curves.text_color.clear()
  for keyframe in keyframes {
    curves.text_color.push(keyframe)
  }
  keyframe_color_sort(curves.text_color)
  animation_clip_update_duration_from_color(self, curves.text_color)
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
pub fn[T : AnimationEvent + @ecs.TriggerEvent] AnimationClip::add_typed_event(
  self : AnimationClip,
  time : Float,
  event : T,
) -> AnimationClip {
  let event = AnimationClipEvent::new_typed(time, event)
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
pub fn[T : AnimationEvent + @ecs.TriggerEvent] AnimationClip::add_typed_event_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  time : Float,
  event : T,
) -> AnimationClip {
  let events = animation_clip_target_events_get_or_insert(self, target_id)
  animation_clip_event_insert_sorted(
    events,
    AnimationClipEvent::new_typed(time, event),
  )
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
  text_color : @sprite.Color?
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
pub fn AnimationSample::text_color(self : AnimationSample) -> @sprite.Color? {
  self.text_color
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
fn animation_color_lerp(
  a : @sprite.Color,
  b : @sprite.Color,
  t : Float,
) -> @sprite.Color {
  let alpha = animation_saturate(t)
  let inv = 1.0F - alpha
  @sprite.Color::new(
    a.r * inv + b.r * alpha,
    a.g * inv + b.g * alpha,
    a.b * inv + b.b * alpha,
    a.a * inv + b.a * alpha,
  )
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
  let last_index = keyframes.length() - 1
  if time_seconds >= keyframes[last_index].time {
    return Some(keyframes[last_index].value)
  }
  let mut left = 1
  let mut right = last_index
  let mut segment_right = last_index
  while left <= right {
    let mid = left + (right - left) / 2
    if time_seconds <= keyframes[mid].time {
      segment_right = mid
      right = mid - 1
    } else {
      left = mid + 1
    }
  }
  let right_keyframe = keyframes[segment_right]
  let left_keyframe = keyframes[segment_right - 1]
  let span = right_keyframe.time - left_keyframe.time
  if span <= 0.0F {
    return Some(right_keyframe.value)
  }
  let t = animation_saturate((time_seconds - left_keyframe.time) / span)
  Some(animation_vec3_lerp(left_keyframe.value, right_keyframe.value, t))
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
  let last_index = keyframes.length() - 1
  if time_seconds >= keyframes[last_index].time {
    return Some(keyframes[last_index].value)
  }
  let mut left = 1
  let mut right = last_index
  let mut segment_right = last_index
  while left <= right {
    let mid = left + (right - left) / 2
    if time_seconds <= keyframes[mid].time {
      segment_right = mid
      right = mid - 1
    } else {
      left = mid + 1
    }
  }
  let right_keyframe = keyframes[segment_right]
  let left_keyframe = keyframes[segment_right - 1]
  let span = right_keyframe.time - left_keyframe.time
  if span <= 0.0F {
    return Some(right_keyframe.value)
  }
  let t = animation_saturate((time_seconds - left_keyframe.time) / span)
  Some(animation_quat_nlerp(left_keyframe.value, right_keyframe.value, t))
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
  let last_index = keyframes.length() - 1
  if time_seconds >= keyframes[last_index].time {
    return Some(keyframes[last_index].value)
  }
  let mut left = 1
  let mut right = last_index
  let mut segment_right = last_index
  while left <= right {
    let mid = left + (right - left) / 2
    if time_seconds <= keyframes[mid].time {
      segment_right = mid
      right = mid - 1
    } else {
      left = mid + 1
    }
  }
  let right_keyframe = keyframes[segment_right]
  let left_keyframe = keyframes[segment_right - 1]
  let span = right_keyframe.time - left_keyframe.time
  if span <= 0.0F {
    return Some(right_keyframe.value)
  }
  let t = animation_saturate((time_seconds - left_keyframe.time) / span)
  Some(animation_weights_lerp(left_keyframe.value, right_keyframe.value, t))
}

///|
fn animation_sample_color(
  keyframes : Array[KeyframeColor],
  time_seconds : Float,
) -> @sprite.Color? {
  if keyframes.length() == 0 {
    return None
  }
  if keyframes.length() == 1 {
    return Some(keyframes[0].value)
  }
  if time_seconds <= keyframes[0].time {
    return Some(keyframes[0].value)
  }
  let last_index = keyframes.length() - 1
  if time_seconds >= keyframes[last_index].time {
    return Some(keyframes[last_index].value)
  }
  let mut left = 1
  let mut right = last_index
  let mut segment_right = last_index
  while left <= right {
    let mid = left + (right - left) / 2
    if time_seconds <= keyframes[mid].time {
      segment_right = mid
      right = mid - 1
    } else {
      left = mid + 1
    }
  }
  let right_keyframe = keyframes[segment_right]
  let left_keyframe = keyframes[segment_right - 1]
  let span = right_keyframe.time - left_keyframe.time
  if span <= 0.0F {
    return Some(right_keyframe.value)
  }
  let t = animation_saturate((time_seconds - left_keyframe.time) / span)
  Some(animation_color_lerp(left_keyframe.value, right_keyframe.value, t))
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
  let text_color = animation_sample_color(curves.text_color, time_seconds)
  if translation is Some(_) ||
    rotation is Some(_) ||
    scale is Some(_) ||
    weights is Some(_) ||
    text_color is Some(_) {
    Some(AnimationSample::{ translation, rotation, scale, weights, text_color })
  } else {
    None
  }
}

///|
pub fn animation_clip_add_animatable_curve(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  curve : AnimatableCurve,
  sample_count? : Int = 121,
) -> AnimationClip {
  clip.add_curve_to_target(target_id, curve, sample_count~)
}

///|
pub fn animation_clip_sample(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  time_seconds : Float,
) -> AnimationSample? {
  clip.sample_target(target_id, time_seconds)
}
