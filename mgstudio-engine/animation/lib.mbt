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
pub impl ToJson for AnimatedBy with to_json(self) {
  (self.player.id, self.player.generation).to_json()
}

///|
pub impl @json.FromJson for AnimatedBy with from_json(json, path) {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  AnimatedBy::new(@core.Entity::new(id, generation))
}

///|
fn animation_current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "animation asset helpers require an active app world; use the world-owned Assets<T> resources directly outside scheduled systems",
      )
  }
}

///|
fn[T] animation_asset_store_or_abort() -> @asset.Assets[T] {
  let world = animation_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None =>
      abort(
        "animation asset resource is missing; AnimationPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn[T] animation_asset_store_mut_or_abort() -> Ref[@asset.Assets[T]] {
  let world = animation_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets) => assets
    None =>
      abort(
        "animation asset resource is missing; AnimationPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
pub fn animation_clip_add(clip : AnimationClip) -> @asset.Handle[AnimationClip] {
  animation_asset_store_mut_or_abort().val.add(clip)
}

///|
pub fn animation_clip_get(
  handle : @asset.Handle[AnimationClip],
) -> AnimationClip? {
  animation_asset_store_or_abort().get(handle)
}

///|
pub fn animation_clip_set(
  handle : @asset.Handle[AnimationClip],
  clip : AnimationClip,
) -> Bool {
  animation_asset_store_mut_or_abort().val.set(handle, clip)
}

///|
pub(all) enum RepeatAnimation {
  Never
  Count(Int)
  Forever
}

///|
pub impl ToJson for RepeatAnimation with to_json(self) {
  match self {
    RepeatAnimation::Never => (0, 0).to_json()
    RepeatAnimation::Count(count) => (1, count).to_json()
    RepeatAnimation::Forever => (2, 0).to_json()
  }
}

///|
pub impl @json.FromJson for RepeatAnimation with from_json(json, path) {
  let (tag, payload) : (Int, Int) = @json.from_json(json, path~)
  match tag {
    0 => RepeatAnimation::Never
    1 => RepeatAnimation::Count(payload)
    2 => RepeatAnimation::Forever
    _ => RepeatAnimation::Never
  }
}

///|
pub struct ActiveAnimation {
  weight : Float
  repeat : RepeatAnimation
  speed : Float
  mut elapsed : Float
  mut seek_time : Float
  last_seek_time : Float?
  mut completions : Int
  mut just_completed : Bool
  paused : Bool
}

///|
pub impl ToJson for ActiveAnimation with to_json(self) {
  (
    self.weight,
    self.repeat,
    self.speed,
    self.elapsed,
    self.seek_time,
    self.last_seek_time,
    self.completions,
    self.just_completed,
    self.paused,
  ).to_json()
}

///|
pub impl @json.FromJson for ActiveAnimation with from_json(json, path) {
  let (
    weight,
    repeat,
    speed,
    elapsed,
    seek_time,
    last_seek_time,
    completions,
    just_completed,
    paused,
  ) : (Float, RepeatAnimation, Float, Float, Float, Float?, Int, Bool, Bool) = @json.from_json(
    json,
    path~,
  )
  ActiveAnimation::{
    weight,
    repeat,
    speed,
    elapsed,
    seek_time,
    last_seek_time,
    completions,
    just_completed,
    paused,
  }
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
  ActiveAnimation::{ ..self, weight, }
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
  }
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
  if out.is_finished() {
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
      return out
    }
  }

  if out.seek_time >= clip_duration_seconds {
    out.seek_time = out.seek_time % clip_duration_seconds
  }
  // Assumes delta_seconds >= -clip_duration_seconds, matching Bevy behavior.
  if out.seek_time < 0.0F {
    out.seek_time = out.seek_time + clip_duration_seconds
  }
  out
}

///|
fn animation_player_node_key(node : AnimationNodeIndex) -> Int {
  node.index()
}

///|
fn animation_player_sorted_node_keys(player : AnimationPlayer) -> Array[Int] {
  let keys : Array[Int] = []
  for entry in player.active_animations.iter() {
    let (node_key, _active) = entry
    keys.push(node_key)
  }
  keys.sort()
  keys
}

///|
fn animation_player_sorted_nodes(
  player : AnimationPlayer,
) -> Array[AnimationNodeIndex] {
  let nodes : Array[AnimationNodeIndex] = []
  for node_key in animation_player_sorted_node_keys(player) {
    nodes.push(AnimationNodeIndex::new(node_key))
  }
  nodes
}

///|
struct AnimationPlayer {
  active_animations : Map[Int, ActiveAnimation]
}

///|
struct AnimationPlayerEntry {
  player : AnimationPlayer
  node : AnimationNodeIndex
}

///|
fn animation_player_entry_new(
  player : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayerEntry {
  AnimationPlayerEntry::{ player, node }
}

///|
fn animation_player_entry_active_or_abort(
  entry : AnimationPlayerEntry,
) -> ActiveAnimation {
  match entry.player.animation(entry.node) {
    Some(active) => active
    None =>
      abort(
        "Missing active animation for node \{entry.node.index().to_string()}",
      )
  }
}

///|
pub impl ToJson for AnimationPlayer with to_json(self) {
  self.playing_animations().to_json()
}

///|
pub impl @json.FromJson for AnimationPlayer with from_json(json, path) {
  let active_animations : Array[(AnimationNodeIndex, ActiveAnimation)] = @json.from_json(
    json,
    path~,
  )
  let active_animations_map : Map[Int, ActiveAnimation] = {}
  for pair in active_animations {
    active_animations_map.set(animation_player_node_key(pair.0), pair.1)
  }
  AnimationPlayer::{ active_animations: active_animations_map }
}

///|
pub fn AnimationPlayer::default() -> AnimationPlayer {
  AnimationPlayer::{ active_animations: {} }
}

///|
pub fn AnimationPlayer::playing_animations(
  self : AnimationPlayer,
) -> Array[(AnimationNodeIndex, ActiveAnimation)] {
  let out : Array[(AnimationNodeIndex, ActiveAnimation)] = []
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    out.push((node, active))
  }
  out
}

///|
pub fn AnimationPlayer::playing_animations_mut(
  self : AnimationPlayer,
) -> Array[AnimationPlayerEntry] {
  let out : Array[AnimationPlayerEntry] = []
  for node in animation_player_sorted_nodes(self) {
    out.push(animation_player_entry_new(self, node))
  }
  out
}

///|
pub fn AnimationPlayer::animation(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> ActiveAnimation? {
  self.active_animations.get(animation_player_node_key(node))
}

///|
pub fn AnimationPlayer::animation_mut(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayerEntry? {
  if self.animation(node) is Some(_) {
    Some(animation_player_entry_new(self, node))
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
  self.active_animations.set(animation_player_node_key(node), active)
  self
}

///|
pub fn AnimationPlayer::all_paused(self : AnimationPlayer) -> Bool {
  for pair in self.playing_animations() {
    if !pair.1.is_paused() {
      return false
    }
  }
  true
}

///|
pub fn AnimationPlayer::pause_all(self : AnimationPlayer) -> AnimationPlayer {
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    self.set_animation(node, active.pause()) |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::resume_all(self : AnimationPlayer) -> AnimationPlayer {
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    self.set_animation(node, active.unpause()) |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::rewind_all(self : AnimationPlayer) -> AnimationPlayer {
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    self.set_animation(node, active.rewind()) |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::adjust_speeds(
  self : AnimationPlayer,
  factor : Float,
) -> AnimationPlayer {
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    self.set_animation(node, active.set_speed(active.speed() * factor))
    |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::seek_all_by(
  self : AnimationPlayer,
  amount : Float,
) -> AnimationPlayer {
  for node in animation_player_sorted_nodes(self) {
    guard self.animation(node) is Some(active) else { continue }
    self.set_animation(node, active.seek_to(active.seek_time() + amount))
    |> ignore
  }
  self
}

///|
pub fn AnimationPlayer::start(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayerEntry {
  if self.animation_mut(node) is Some(existing) {
    return existing.replay()
  }
  let active = ActiveAnimation::default()
  self.active_animations.set(animation_player_node_key(node), active)
  animation_player_entry_new(self, node)
}

///|
pub fn AnimationPlayer::play(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayerEntry {
  if self.animation_mut(node) is Some(existing) {
    return existing
  }
  let active = ActiveAnimation::default()
  self.active_animations.set(animation_player_node_key(node), active)
  animation_player_entry_new(self, node)
}

///|
pub fn AnimationPlayer::stop(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayer {
  ignore(self.active_animations.remove(animation_player_node_key(node)))
  self
}

///|
pub fn AnimationPlayer::stop_all(self : AnimationPlayer) -> AnimationPlayer {
  self.active_animations.clear()
  self
}

///|
pub fn AnimationPlayer::all_finished(self : AnimationPlayer) -> Bool {
  for pair in self.playing_animations() {
    if !pair.1.is_finished() {
      return false
    }
  }
  true
}

///|
pub fn AnimationPlayerEntry::node(
  self : AnimationPlayerEntry,
) -> AnimationNodeIndex {
  self.node
}

///|
pub fn AnimationPlayerEntry::is_finished(self : AnimationPlayerEntry) -> Bool {
  animation_player_entry_active_or_abort(self).is_finished()
}

///|
pub fn AnimationPlayerEntry::is_paused(self : AnimationPlayerEntry) -> Bool {
  animation_player_entry_active_or_abort(self).is_paused()
}

///|
pub fn AnimationPlayerEntry::weight(self : AnimationPlayerEntry) -> Float {
  animation_player_entry_active_or_abort(self).weight()
}

///|
pub fn AnimationPlayerEntry::seek_time(self : AnimationPlayerEntry) -> Float {
  animation_player_entry_active_or_abort(self).seek_time()
}

///|
pub fn AnimationPlayerEntry::repeat_mode(
  self : AnimationPlayerEntry,
) -> RepeatAnimation {
  animation_player_entry_active_or_abort(self).repeat_mode()
}

///|
pub fn AnimationPlayerEntry::speed(self : AnimationPlayerEntry) -> Float {
  animation_player_entry_active_or_abort(self).speed()
}

///|
pub fn AnimationPlayerEntry::elapsed(self : AnimationPlayerEntry) -> Float {
  animation_player_entry_active_or_abort(self).elapsed()
}

///|
pub fn AnimationPlayerEntry::completions(self : AnimationPlayerEntry) -> Int {
  animation_player_entry_active_or_abort(self).completions()
}

///|
pub fn AnimationPlayerEntry::just_completed(
  self : AnimationPlayerEntry,
) -> Bool {
  animation_player_entry_active_or_abort(self).just_completed()
}

///|
pub fn AnimationPlayerEntry::is_playback_reversed(
  self : AnimationPlayerEntry,
) -> Bool {
  animation_player_entry_active_or_abort(self).is_playback_reversed()
}

///|
pub fn AnimationPlayerEntry::set_weight(
  self : AnimationPlayerEntry,
  weight : Float,
) -> AnimationPlayerEntry {
  self.player.set_weight(self.node, weight) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::set_repeat(
  self : AnimationPlayerEntry,
  repeat : RepeatAnimation,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).set_repeat(repeat)
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::repeat_forever(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  self.set_repeat(RepeatAnimation::Forever)
}

///|
pub fn AnimationPlayerEntry::repeat(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  self.repeat_forever()
}

///|
pub fn AnimationPlayerEntry::set_speed(
  self : AnimationPlayerEntry,
  speed : Float,
) -> AnimationPlayerEntry {
  self.player.set_speed(self.node, speed) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::pause(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).pause()
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::unpause(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).unpause()
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::resume_playback(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  self.unpause()
}

///|
pub fn AnimationPlayerEntry::set_seek_time(
  self : AnimationPlayerEntry,
  seek_time : Float,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).set_seek_time(
    seek_time,
  )
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::seek_to(
  self : AnimationPlayerEntry,
  seek_time : Float,
) -> AnimationPlayerEntry {
  self.player.seek_to(self.node, seek_time) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::rewind(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).rewind()
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
pub fn AnimationPlayerEntry::replay(
  self : AnimationPlayerEntry,
) -> AnimationPlayerEntry {
  let active = animation_player_entry_active_or_abort(self).replay()
  self.player.set_animation(self.node, active) |> ignore
  self
}

///|
fn animation_player_tick(
  player : AnimationPlayer,
  graph : AnimationGraph,
  delta_seconds : Float,
) -> AnimationPlayer {
  for pair in player.playing_animations() {
    let node = pair.0
    let active = pair.1
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
    player.set_animation(node, next_active) |> ignore
  }
  player
}

///|
priv struct AnimationPreparedTargetSample {
  clip_id : Int
  seek_time : Float
  combined_weight : Float
  computed_mask : AnimationMask
}

///|
fn animation_clip_cached_or_load(
  handle : @asset.Handle[AnimationClip],
  clip_cache : Map[Int, AnimationClip],
) -> AnimationClip? {
  let clip_id = handle.id()
  if clip_id < 0 {
    return None
  }
  match clip_cache.get(clip_id) {
    Some(cached) => Some(cached)
    None =>
      match animation_clip_get(handle) {
        Some(clip) => {
          clip_cache.set(clip_id, clip)
          Some(clip)
        }
        None => None
      }
  }
}

///|
fn animation_prepare_player_target_samples(
  player : AnimationPlayer,
  graph : AnimationGraph,
  threaded_graph : ThreadedAnimationGraph,
  clip_cache : Map[Int, AnimationClip],
) -> Array[AnimationPreparedTargetSample] {
  let samples : Array[AnimationPreparedTargetSample] = []
  for pair in player.playing_animations() {
    let node_index = pair.0
    let active = pair.1
    guard graph.get(node_index) is Some(node) else { continue }
    guard node.node_type is Clip(clip_handle) else { continue }
    guard animation_clip_cached_or_load(clip_handle, clip_cache) is Some(_clip) else {
      continue
    }
    let node_i = node_index.index()
    let effective_weight = if node_i >= 0 &&
      node_i < threaded_graph.effective_weights.length() {
      threaded_graph.effective_weights[node_i]
    } else {
      graph.effective_weight(node_index)
    }
    let combined_weight = active.weight() * effective_weight
    if combined_weight <= 0.0F {
      continue
    }
    let computed_mask = if node_i >= 0 &&
      node_i < threaded_graph.computed_masks.length() {
      threaded_graph.computed_masks[node_i]
    } else {
      graph.computed_mask(node_index)
    }
    samples.push({
      clip_id: clip_handle.id(),
      seek_time: active.seek_time(),
      combined_weight,
      computed_mask,
    })
  }
  samples
}

///|
priv struct AnimationEvaluationState {
  mut has_translation : Bool
  mut has_rotation : Bool
  mut has_scale : Bool
  mut has_weights : Bool
  mut has_text_color : Bool
  mut translation_weight : Float
  mut rotation_weight : Float
  mut scale_weight : Float
  mut weights_weight : Float
  mut text_color_weight : Float
  mut translation_acc : @math.Vec3
  mut scale_acc : @math.Vec3
  mut rotation_acc_x : Float
  mut rotation_acc_y : Float
  mut rotation_acc_z : Float
  mut rotation_acc_w : Float
  weights_acc : Array[Float]
  mut text_color_acc_r : Float
  mut text_color_acc_g : Float
  mut text_color_acc_b : Float
  mut text_color_acc_a : Float
}

///|
fn animation_evaluation_state_new() -> AnimationEvaluationState {
  AnimationEvaluationState::{
    has_translation: false,
    has_rotation: false,
    has_scale: false,
    has_weights: false,
    has_text_color: false,
    translation_weight: 0.0F,
    rotation_weight: 0.0F,
    scale_weight: 0.0F,
    weights_weight: 0.0F,
    text_color_weight: 0.0F,
    translation_acc: @math.Vec3::zero(),
    scale_acc: @math.Vec3::zero(),
    rotation_acc_x: 0.0F,
    rotation_acc_y: 0.0F,
    rotation_acc_z: 0.0F,
    rotation_acc_w: 0.0F,
    weights_acc: [],
    text_color_acc_r: 0.0F,
    text_color_acc_g: 0.0F,
    text_color_acc_b: 0.0F,
    text_color_acc_a: 0.0F,
  }
}

///|
fn animation_evaluation_state_apply_sample(
  state : AnimationEvaluationState,
  clip_sample : AnimationSample,
  combined_weight : Float,
) -> Unit {
  if clip_sample.translation is Some(translation) {
    state.has_translation = true
    state.translation_weight = state.translation_weight + combined_weight
    state.translation_acc = state.translation_acc.add(
      translation.mul_scalar(combined_weight),
    )
  }

  if clip_sample.rotation is Some(rotation) {
    state.has_rotation = true
    state.rotation_weight = state.rotation_weight + combined_weight
    state.rotation_acc_x = state.rotation_acc_x + rotation.x * combined_weight
    state.rotation_acc_y = state.rotation_acc_y + rotation.y * combined_weight
    state.rotation_acc_z = state.rotation_acc_z + rotation.z * combined_weight
    state.rotation_acc_w = state.rotation_acc_w + rotation.w * combined_weight
  }

  if clip_sample.scale is Some(scale) {
    state.has_scale = true
    state.scale_weight = state.scale_weight + combined_weight
    state.scale_acc = state.scale_acc.add(scale.mul_scalar(combined_weight))
  }

  if clip_sample.weights is Some(weights) {
    state.has_weights = true
    state.weights_weight = state.weights_weight + combined_weight
    animation_weights_accumulate(state.weights_acc, weights, combined_weight)
  }

  if clip_sample.text_color is Some(text_color) {
    state.has_text_color = true
    state.text_color_weight = state.text_color_weight + combined_weight
    state.text_color_acc_r = state.text_color_acc_r +
      text_color.r * combined_weight
    state.text_color_acc_g = state.text_color_acc_g +
      text_color.g * combined_weight
    state.text_color_acc_b = state.text_color_acc_b +
      text_color.b * combined_weight
    state.text_color_acc_a = state.text_color_acc_a +
      text_color.a * combined_weight
  }
}

///|
fn animation_evaluation_state_commit(
  state : AnimationEvaluationState,
  base_transform : @transform.Transform?,
  base_weights : AnimationWeights?,
  base_text_color : @text.TextColor?,
) -> (@transform.Transform?, AnimationWeights?, @text.TextColor?) {
  let transform_out = if state.has_translation ||
    state.has_rotation ||
    state.has_scale {
    let base = match base_transform {
      Some(transform) => transform
      None => @transform.Transform::identity()
    }
    let translation = if state.has_translation {
      let base_weight = animation_saturate(1.0F - state.translation_weight)
      base.translation.mul_scalar(base_weight).add(state.translation_acc)
    } else {
      base.translation
    }
    let scale = if state.has_scale {
      let base_weight = animation_saturate(1.0F - state.scale_weight)
      base.scale.mul_scalar(base_weight).add(state.scale_acc)
    } else {
      base.scale
    }
    let rotation = if state.has_rotation {
      let base_weight = animation_saturate(1.0F - state.rotation_weight)
      let x = base.rotation.x * base_weight + state.rotation_acc_x
      let y = base.rotation.y * base_weight + state.rotation_acc_y
      let z = base.rotation.z * base_weight + state.rotation_acc_z
      let w = base.rotation.w * base_weight + state.rotation_acc_w
      animation_quat_normalized(x, y, z, w)
    } else {
      base.rotation
    }
    Some(@transform.Transform::new(translation, rotation, scale))
  } else {
    None
  }

  let weights_out = if state.has_weights {
    let base_values = match base_weights {
      Some(weights) => weights.values
      None => []
    }
    Some(
      AnimationWeights::new(
        animation_weights_blend(
          base_values,
          state.weights_acc,
          state.weights_weight,
        ),
      ),
    )
  } else {
    None
  }

  let text_color_out = if state.has_text_color {
    let base = match base_text_color {
      Some(color) => color.color
      None => @sprite.Color::white()
    }
    let base_weight = animation_saturate(1.0F - state.text_color_weight)
    Some(
      @text.TextColor::new(
        @sprite.Color::new(
          base.r * base_weight + state.text_color_acc_r,
          base.g * base_weight + state.text_color_acc_g,
          base.b * base_weight + state.text_color_acc_b,
          base.a * base_weight + state.text_color_acc_a,
        ),
      ),
    )
  } else {
    None
  }

  (transform_out, weights_out, text_color_out)
}

///|
fn animation_apply_prepared_player_to_target(
  target_id : AnimationTargetId,
  target_mask : AnimationMask,
  prepared_samples : Array[AnimationPreparedTargetSample],
  clip_cache : Map[Int, AnimationClip],
  base_transform : @transform.Transform?,
  base_weights : AnimationWeights?,
  base_text_color : @text.TextColor?,
) -> (@transform.Transform?, AnimationWeights?, @text.TextColor?) {
  let evaluation_state = animation_evaluation_state_new()

  for sample in prepared_samples {
    if (target_mask & sample.computed_mask) != 0U {
      continue
    }
    guard clip_cache.get(sample.clip_id) is Some(clip) else { continue }
    guard clip.sample_target(target_id, sample.seek_time) is Some(clip_sample) else {
      continue
    }
    animation_evaluation_state_apply_sample(
      evaluation_state,
      clip_sample,
      sample.combined_weight,
    )
  }

  animation_evaluation_state_commit(
    evaluation_state, base_transform, base_weights, base_text_color,
  )
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
pub let animation_set_trigger_untargeted_events : @app.SystemSet = @app.system_set(
  "mgstudio.animation.trigger_untargeted_events",
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
pub let ecs_key_animation_graph_handle : @ecs.ComponentKey[AnimationGraphHandle] = @ecs.register_component(
  debug_name="animation.animation_graph_handle",
)

///|
pub let ecs_key_animation_transitions : @ecs.ComponentKey[AnimationTransitions] = @ecs.register_component(
  debug_name="animation.animation_transitions",
)

///|
pub let ecs_key_animation_weights : @ecs.ComponentKey[AnimationWeights] = @ecs.register_component(
  debug_name="animation.animation_weights",
)

///|
pub impl @ecs.Component for AnimationGraphHandle with component() {
  ecs_key_animation_graph_handle
}

///|
pub impl @ecs.Component for AnimationTransitions with component() {
  ecs_key_animation_transitions
}

///|
pub impl @ecs.Component for AnimationWeights with component() {
  ecs_key_animation_weights
}

///|
fn animation_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in animation systems")
  }
}

///|
pub fn advance_animations(world : @ecs.World) -> Unit {
  let delta_seconds = animation_default_time_or_default(world).delta_seconds()

  let updates : Array[(@core.Entity, AnimationPlayer)] = []
  let player_query : @ecs.Query[@ecs.Comp[AnimationPlayer], @ecs.All] = @ecs.query(
    world,
  )
  try! player_query.view(fn(entity, player) {
    guard (try! world.get_by_key(entity, ecs_key_animation_graph_handle))
      is Some(graph_handle) else {
      return
    }
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    updates.push(
      (entity, animation_player_tick(player.value(), graph, delta_seconds)),
    )
  })

  for update in updates {
    try! world.set_by_key(update.0, ecs_key_animation_player, update.1)
  }
}

///|
pub fn animate_targets(world : @ecs.World) -> Unit {
  let transform_updates : Array[(@core.Entity, @transform.Transform)] = []
  let weights_updates : Array[(@core.Entity, AnimationWeights)] = []
  let text_color_updates : Array[(@core.Entity, @text.TextColor)] = []
  let prepared_player_cache : Map[
    Int,
    (Int, Array[AnimationPreparedTargetSample]),
  ] = {}
  let threaded_graphs = try! world.get_resource_ref(
    threaded_animation_graphs_key,
  )
  let graph_cache : Map[Int, AnimationGraph] = {}
  let clip_cache : Map[Int, AnimationClip] = {}
  let threaded_graph_cache : Map[Int, ThreadedAnimationGraph] = {}

  let player_query : @ecs.Query[
    (@core.Entity, @ecs.Comp[AnimationPlayer], @ecs.Comp[AnimationGraphHandle]),
    @ecs.All,
  ] = @ecs.query(world)
  try! player_query.view(fn(_entity, player_data) {
    let (player_entity, player_comp, graph_handle_comp) = player_data
    let player_id = player_entity.id
    if player_id < 0 {
      return
    }
    let graph_handle = graph_handle_comp.value()
    let graph_handle_id = graph_handle.graph().id()
    let graph = match graph_cache.get(graph_handle_id) {
      Some(cached_graph) => cached_graph
      None =>
        match animation_graph_get(graph_handle.graph()) {
          Some(loaded_graph) => {
            graph_cache.set(graph_handle_id, loaded_graph)
            loaded_graph
          }
          None => return
        }
    }
    let threaded_graph = match threaded_graphs {
      Some(threaded_graphs) =>
        match threaded_graphs.val.graphs.get(graph_handle_id) {
          Some(cached_threaded) => cached_threaded
          None =>
            match threaded_graph_cache.get(graph_handle_id) {
              Some(cached_threaded) => cached_threaded
              None => {
                let built = animation_thread_graph_build(graph)
                threaded_graph_cache.set(graph_handle_id, built)
                built
              }
            }
        }
      None =>
        match threaded_graph_cache.get(graph_handle_id) {
          Some(cached_threaded) => cached_threaded
          None => {
            let built = animation_thread_graph_build(graph)
            threaded_graph_cache.set(graph_handle_id, built)
            built
          }
        }
    }
    prepared_player_cache.set(
      player_id,
      (
        graph_handle_id,
        animation_prepare_player_target_samples(
          player_comp.value(),
          graph,
          threaded_graph,
          clip_cache,
        ),
      ),
    )
  })

  let target_query : @ecs.Query[
    (@ecs.Comp[AnimationTargetId], @ecs.Comp[AnimatedBy]),
    @ecs.All,
  ] = @ecs.query(world)
  try! target_query.view(fn(entity, target_data) {
    let (target_id_comp, animated_by_comp) = target_data
    let animated_by = animated_by_comp.value()
    let player_entity = animated_by.player()
    let player_id = player_entity.id
    if player_id < 0 {
      return
    }
    let (graph_id, prepared_samples) = match
      prepared_player_cache.get(player_id) {
      Some(cached) => cached
      None => return
    }
    if prepared_samples.length() == 0 {
      return
    }
    let graph = match graph_cache.get(graph_id) {
      Some(graph) => graph
      None => return
    }
    let target_id = target_id_comp.value()
    let target_mask = graph.target_mask(target_id)
    let (next_transform, next_weights, next_text_color) = animation_apply_prepared_player_to_target(
      target_id,
      target_mask,
      prepared_samples,
      clip_cache,
      try! world.get_by_key(entity, @transform.ecs_key_transform),
      try! world.get_by_key(entity, ecs_key_animation_weights),
      try! world.get_by_key(entity, @text.ecs_key_text_color),
    )

    if next_transform is Some(transform) {
      transform_updates.push((entity, transform))
    }
    if next_weights is Some(weights) {
      weights_updates.push((entity, weights))
    }
    if next_text_color is Some(text_color) {
      text_color_updates.push((entity, text_color))
    }
  })

  for update in transform_updates {
    try! world.set_by_key(update.0, @transform.ecs_key_transform, update.1)
  }

  for update in weights_updates {
    try! world.set_by_key(update.0, ecs_key_animation_weights, update.1)
  }

  for update in text_color_updates {
    try! world.set_by_key(update.0, @text.ecs_key_text_color, update.1)
  }
}

///|
fn animation_collect_players_with_target_events(
  world : @ecs.World,
) -> (Map[Int, (AnimationPlayer, AnimationGraph, ThreadedAnimationGraph)], Bool) {
  let players_with_target_events : Map[
    Int,
    (AnimationPlayer, AnimationGraph, ThreadedAnimationGraph),
  ] = {}
  let mut has_any_target_events = false
  let threaded_graphs = try! world.get_resource_ref(
    threaded_animation_graphs_key,
  )
  let player_query : @ecs.Query[@ecs.Comp[AnimationPlayer], @ecs.All] = @ecs.query(
    world,
  )
  try! player_query.view(fn(player_entity, player) {
    guard (try! world.get_by_key(player_entity, ecs_key_animation_graph_handle))
      is Some(graph_handle) else {
      return
    }
    let player = player.value()
    guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
      return
    }
    let graph_id = graph_handle.graph().id()
    let threaded_graph = match threaded_graphs {
      Some(threaded_graphs) =>
        match threaded_graphs.val.graphs.get(graph_id) {
          Some(cached_threaded) => cached_threaded
          None => animation_thread_graph_build(graph)
        }
      None => animation_thread_graph_build(graph)
    }
    let mut player_has_target_events = false
    for pair in player.playing_animations() {
      let node_index = pair.0
      guard graph.get(node_index) is Some(node) else { continue }
      guard node.node_type is Clip(clip_handle) else { continue }
      guard animation_clip_get(clip_handle) is Some(clip) else { continue }
      if clip.events_targets.length() > 0 {
        player_has_target_events = true
      }
    }
    if player_has_target_events {
      players_with_target_events.set(
        player_entity.id,
        (player, graph, threaded_graph),
      )
      has_any_target_events = true
    }
  })
  (players_with_target_events, has_any_target_events)
}

///|
pub fn trigger_untargeted_animation_events(world : @ecs.World) -> Unit {
  let writer : @core.MessageWriter[AnimationTriggeredEvent] = @core.Message::writer(
    @app.current_system_sequence().this_run,
  )
  let player_query : @ecs.Query[@ecs.Comp[AnimationPlayer], @ecs.All] = @ecs.query(
    world,
  )
  try! player_query.view(fn(player_entity, player) {
    guard (try! world.get_by_key(player_entity, ecs_key_animation_graph_handle))
      is Some(graph_handle) else {
      return
    }
    let player = player.value()
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
        world,
        writer,
        player_entity,
        player_entity,
        None,
        active,
        triggered,
      )
    }
  })
}

///|
pub fn trigger_events(world : @ecs.World) -> Unit {
  let writer : @core.MessageWriter[AnimationTriggeredEvent] = @core.Message::writer(
    @app.current_system_sequence().this_run,
  )
  let (players_with_target_events, has_any_target_events) = animation_collect_players_with_target_events(
    world,
  )
  if !has_any_target_events {
    return
  }
  let target_query : @ecs.Query[@ecs.Comp[AnimationTargetId], @ecs.All] = @ecs.query(
    world,
  )
  try! target_query.view(fn(target_entity, target_id) {
    guard (try! world.get_by_key(target_entity, ecs_key_animated_by))
      is Some(animated_by) else {
      return
    }
    let player_entity = animated_by.player()
    guard players_with_target_events.get(player_entity.id)
      is Some((player, graph, threaded_graph)) else {
      return
    }
    let target_id = target_id.value()
    let target_mask = graph.target_mask(target_id)
    for pair in player.playing_animations() {
      let node_index = pair.0
      let active = pair.1
      if active.is_paused() {
        continue
      }
      guard graph.get(node_index) is Some(node) else { continue }
      guard node.node_type is Clip(clip_handle) else { continue }
      let node_i = node_index.index()
      let computed_mask = if node_i >= 0 &&
        node_i < threaded_graph.computed_masks.length() {
        threaded_graph.computed_masks[node_i]
      } else {
        graph.computed_mask(node_index)
      }
      if (target_mask & computed_mask) != 0U {
        continue
      }
      let effective_weight = if node_i >= 0 &&
        node_i < threaded_graph.effective_weights.length() {
        threaded_graph.effective_weights[node_i]
      } else {
        graph.effective_weight(node_index)
      }
      let combined_weight = active.weight() * effective_weight
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
        world,
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
pub fn animation_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let animation_clip_event_key : @ecs.MessageKey[
    @asset.AssetEvent[AnimationClip],
  ] = @ecs.Message::message()
  let animation_graph_event_key : @ecs.MessageKey[
    @asset.AssetEvent[AnimationGraph],
  ] = @ecs.Message::message()
  @asset.init_asset_loader(
    app
    .init_resource(fn() {
      let assets : @asset.Assets[AnimationClip] = @asset.Assets::new()
      assets
    })
    .init_resource(fn() {
      let assets : @asset.Assets[AnimationGraph] = @asset.Assets::new()
      assets
    })
    .init_resource(fn() { ThreadedAnimationGraphs::{ graphs: {} } })
    .add_message(animation_clip_event_key)
    .add_message(animation_graph_event_key),
    animation_graph_asset_loader(),
  )
  .add_post_update_system_config(
    @app.system(@app.system_param3(thread_animation_graphs)).in_set(
      animation_set_thread,
    ),
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
    @app.system(trigger_untargeted_animation_events).in_set(
      animation_set_trigger_untargeted_events,
    ),
  )
  .add_post_update_system_config(
    @app.system(trigger_events).in_set(animation_set_trigger_events),
  )
  .add_post_update_system_config(
    @app.system(expire_completed_transitions).in_set(
      animation_set_expire_transitions,
    ),
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
    animation_set_trigger_untargeted_events,
  ])
  .configure_set(@app.PostUpdate, animation_set_trigger_untargeted_events, before=[
    animation_set_trigger_events,
  ])
  .configure_set(@app.PostUpdate, animation_set_animate_targets, before=[
    @transform.transform_set_mark_dirty_trees,
  ])
  .configure_set(@app.PostUpdate, animation_set_trigger_events, before=[
    animation_set_expire_transitions,
  ])
}
