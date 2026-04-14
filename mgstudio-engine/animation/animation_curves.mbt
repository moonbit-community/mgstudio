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
  interpolation : GltfInterpolation
  in_tangent : @math.Vec3?
  out_tangent : @math.Vec3?
}

///|
pub fn KeyframeVec3::new(time : Float, value : @math.Vec3) -> KeyframeVec3 {
  KeyframeVec3::{
    time,
    value,
    interpolation: GltfInterpolation::Linear,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeVec3::new_stepped(
  time : Float,
  value : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::{
    time,
    value,
    interpolation: GltfInterpolation::Step,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeVec3::new_cubic(
  time : Float,
  value : @math.Vec3,
  in_tangent : @math.Vec3,
  out_tangent : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::{
    time,
    value,
    interpolation: GltfInterpolation::CubicSpline,
    in_tangent: Some(in_tangent),
    out_tangent: Some(out_tangent),
  }
}

///|
pub struct KeyframeQuat {
  time : Float
  value : @math.Quat
  interpolation : GltfInterpolation
  in_tangent : @math.Vec4?
  out_tangent : @math.Vec4?
}

///|
pub fn KeyframeQuat::new(time : Float, value : @math.Quat) -> KeyframeQuat {
  KeyframeQuat::{
    time,
    value,
    interpolation: GltfInterpolation::Linear,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeQuat::new_stepped(
  time : Float,
  value : @math.Quat,
) -> KeyframeQuat {
  KeyframeQuat::{
    time,
    value,
    interpolation: GltfInterpolation::Step,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeQuat::new_cubic(
  time : Float,
  value : @math.Quat,
  in_tangent : @math.Vec4,
  out_tangent : @math.Vec4,
) -> KeyframeQuat {
  KeyframeQuat::{
    time,
    value,
    interpolation: GltfInterpolation::CubicSpline,
    in_tangent: Some(in_tangent),
    out_tangent: Some(out_tangent),
  }
}

///|
pub struct KeyframeWeights {
  time : Float
  value : Array[Float]
  interpolation : GltfInterpolation
  in_tangent : Array[Float]?
  out_tangent : Array[Float]?
}

///|
pub fn KeyframeWeights::new(
  time : Float,
  value : Array[Float],
) -> KeyframeWeights {
  KeyframeWeights::{
    time,
    value,
    interpolation: GltfInterpolation::Linear,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeWeights::new_stepped(
  time : Float,
  value : Array[Float],
) -> KeyframeWeights {
  KeyframeWeights::{
    time,
    value,
    interpolation: GltfInterpolation::Step,
    in_tangent: None,
    out_tangent: None,
  }
}

///|
pub fn KeyframeWeights::new_cubic(
  time : Float,
  value : Array[Float],
  in_tangent : Array[Float],
  out_tangent : Array[Float],
) -> KeyframeWeights {
  KeyframeWeights::{
    time,
    value,
    interpolation: GltfInterpolation::CubicSpline,
    in_tangent: Some(in_tangent),
    out_tangent: Some(out_tangent),
  }
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
pub type VariableCurve = AnimatableCurve

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
  events : Array[(AnimationEventTarget, Array[AnimationClipEvent])]
}

///|
pub fn AnimationClip::new() -> AnimationClip {
  AnimationClip::{
    duration_seconds: 0.0F,
    targets: [],
    target_index_by_key: {},
    events: [],
  }
}

///|
pub fn AnimationClip::duration(self : AnimationClip) -> Float {
  self.duration_seconds
}

///|
pub fn AnimationClip::curves(
  self : AnimationClip,
) -> Array[(AnimationTargetId, AnimationTargetCurves)] {
  let curves : Array[(AnimationTargetId, AnimationTargetCurves)] = []
  for binding in self.targets {
    curves.push((binding.target_id, binding.curves))
  }
  curves
}

///|
pub fn AnimationClip::curves_mut(
  self : AnimationClip,
) -> Array[(AnimationTargetId, AnimationTargetCurves)] {
  self.curves()
}

///|
pub fn AnimationClip::curves_for_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
) -> AnimationTargetCurves? {
  if animation_clip_find_target(self, target_id) is Some(index) {
    Some(self.targets[index].curves)
  } else {
    None
  }
}

///|
pub fn AnimationClip::curves_for_target_mut(
  self : AnimationClip,
  target_id : AnimationTargetId,
) -> AnimationTargetCurves? {
  self.curves_for_target(target_id)
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
pub fn AnimationClip::add_variable_curve_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  variable_curve : VariableCurve,
  sample_count? : Int = 121,
) -> AnimationClip {
  self.add_curve_to_target(target_id, variable_curve, sample_count~)
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
fn animation_event_target_eq(
  lhs : AnimationEventTarget,
  rhs : AnimationEventTarget,
) -> Bool {
  match (lhs, rhs) {
    (Root, Root) => true
    (Node(lhs_id), Node(rhs_id)) => lhs_id == rhs_id
    (_, _) => false
  }
}

///|
fn animation_clip_events_get_or_insert(
  clip : AnimationClip,
  target : AnimationEventTarget,
) -> Array[AnimationClipEvent] {
  let mut i = 0
  while i < clip.events.length() {
    if animation_event_target_eq(clip.events[i].0, target) {
      return clip.events[i].1
    }
    i = i + 1
  }
  let events : Array[AnimationClipEvent] = []
  clip.events.push((target, events))
  events
}

///|
fn animation_clip_events_get(
  clip : AnimationClip,
  target : AnimationEventTarget,
) -> Array[AnimationClipEvent]? {
  for entry in clip.events {
    if animation_event_target_eq(entry.0, target) {
      return Some(entry.1)
    }
  }
  None
}

///|
fn animation_clip_has_target_events(clip : AnimationClip) -> Bool {
  for entry in clip.events {
    if entry.0 is Node(_) {
      return true
    }
  }
  false
}

///|
fn animation_clip_events_for_root(
  clip : AnimationClip,
) -> Array[AnimationClipEvent] {
  match animation_clip_events_get(clip, AnimationEventTarget::Root) {
    Some(events) => events
    None => []
  }
}

///|
pub fn AnimationClip::add_event(
  self : AnimationClip,
  time : Float,
  label : String,
  payload : String,
) -> AnimationClip {
  let event = AnimationClipEvent::new(time, label, payload)
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Root,
  )
  animation_clip_event_insert_sorted(events, event)
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
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Root,
  )
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
pub fn AnimationClip::add_event_to_target(
  self : AnimationClip,
  target_id : AnimationTargetId,
  time : Float,
  label : String,
  payload : String,
) -> AnimationClip {
  let event = AnimationClipEvent::new(time, label, payload)
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Node(target_id),
  )
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
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Node(target_id),
  )
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
  callback : AnimationEventTriggerFn,
) -> AnimationClip {
  let event = AnimationClipEvent::new_callback(time, callback)
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Root,
  )
  animation_clip_event_insert_sorted(events, event)
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
  callback : AnimationEventTriggerFn,
) -> AnimationClip {
  let event = AnimationClipEvent::new_callback(time, callback)
  let events = animation_clip_events_get_or_insert(
    self,
    AnimationEventTarget::Node(target_id),
  )
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
  animation_clip_events_get(clip, AnimationEventTarget::Node(target_id))
}

///|
pub fn AnimationClip::events(self : AnimationClip) -> Array[AnimationClipEvent] {
  animation_clip_events_for_root(self)
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
  animation_clip_collect_triggered_events(
    animation_clip_events_for_root(self),
    active,
  )
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
fn animation_step_or_linear_vec3(
  left_keyframe : KeyframeVec3,
  right_keyframe : KeyframeVec3,
  t : Float,
  span : Float,
) -> @math.Vec3 {
  match left_keyframe.interpolation {
    GltfInterpolation::Step =>
      if t >= 1.0F {
        right_keyframe.value
      } else {
        left_keyframe.value
      }
    GltfInterpolation::CubicSpline =>
      match (left_keyframe.out_tangent, right_keyframe.in_tangent) {
        (Some(out_tangent), Some(in_tangent)) =>
          animation_interpolate_with_cubic_bezier_vec3(
            left_keyframe.value,
            out_tangent,
            in_tangent,
            right_keyframe.value,
            t,
            span,
          )
        _ =>
          animation_interpolate_vec3_unclamped(
            left_keyframe.value,
            right_keyframe.value,
            t,
          )
      }
    GltfInterpolation::Linear =>
      animation_interpolate_vec3_unclamped(
        left_keyframe.value,
        right_keyframe.value,
        t,
      )
  }
}

///|
fn animation_step_or_linear_quat(
  left_keyframe : KeyframeQuat,
  right_keyframe : KeyframeQuat,
  t : Float,
  span : Float,
) -> @math.Quat {
  match left_keyframe.interpolation {
    GltfInterpolation::Step =>
      if t >= 1.0F {
        right_keyframe.value
      } else {
        left_keyframe.value
      }
    GltfInterpolation::CubicSpline =>
      match (left_keyframe.out_tangent, right_keyframe.in_tangent) {
        (Some(out_tangent), Some(in_tangent)) =>
          animation_interpolate_with_cubic_bezier_quat(
            left_keyframe.value,
            out_tangent,
            in_tangent,
            right_keyframe.value,
            t,
            span,
          )
        _ =>
          animation_interpolate_quat_unclamped(
            left_keyframe.value,
            right_keyframe.value,
            t,
          )
      }
    GltfInterpolation::Linear =>
      animation_interpolate_quat_unclamped(
        left_keyframe.value,
        right_keyframe.value,
        t,
      )
  }
}

///|
fn animation_step_or_linear_weights(
  left_keyframe : KeyframeWeights,
  right_keyframe : KeyframeWeights,
  t : Float,
  span : Float,
) -> Array[Float] {
  match left_keyframe.interpolation {
    GltfInterpolation::Step =>
      if t >= 1.0F {
        right_keyframe.value
      } else {
        left_keyframe.value
      }
    GltfInterpolation::CubicSpline =>
      match (left_keyframe.out_tangent, right_keyframe.in_tangent) {
        (Some(out_tangent), Some(in_tangent)) =>
          animation_interpolate_with_cubic_bezier_weights(
            left_keyframe.value,
            out_tangent,
            in_tangent,
            right_keyframe.value,
            t,
            span,
          )
        _ =>
          animation_interpolate_weights_unclamped(
            left_keyframe.value,
            right_keyframe.value,
            t,
          )
      }
    GltfInterpolation::Linear =>
      animation_interpolate_weights_unclamped(
        left_keyframe.value,
        right_keyframe.value,
        t,
      )
  }
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
  Some(animation_step_or_linear_vec3(left_keyframe, right_keyframe, t, span))
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
  Some(animation_step_or_linear_quat(left_keyframe, right_keyframe, t, span))
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
  Some(animation_step_or_linear_weights(left_keyframe, right_keyframe, t, span))
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
  Some(
    animation_interpolate_color_unclamped(
      left_keyframe.value,
      right_keyframe.value,
      t,
    ),
  )
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
