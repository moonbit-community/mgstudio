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
const ANIMATION_PLUGIN_NAME : String = "mgstudio.animation.AnimationPlugin"

///|
pub struct AnimatedBy {
  player : @core.Entity
}

///|
pub fn AnimatedBy::new(player : @core.Entity) -> AnimatedBy {
  { player, }
}

///|
pub fn AnimatedBy::player(self : AnimatedBy) -> @core.Entity {
  self.player
}

///|
pub impl ToJson for AnimatedBy with fn to_json(self) {
  (self.player.id, self.player.generation) |> ToJson::to_json
}

///|
pub impl @json.FromJson for AnimatedBy with fn from_json(json, path) {
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
fn[T : @asset.Asset] animation_asset_store_or_abort() -> @asset.Assets[T] {
  let world = animation_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match world.get_resource(key) {
    Some(assets) => assets
    None =>
      abort(
        "animation asset resource is missing; AnimationPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn[T : @asset.Asset] animation_asset_store_mut_or_abort() -> @ecs.ResourceMut[
  @asset.Assets[T],
] {
  let world = animation_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None =>
      abort(
        "animation asset resource is missing; AnimationPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
pub fn animation_clip_add(clip : AnimationClip) -> @asset.Handle[AnimationClip] {
  let assets = animation_asset_store_mut_or_abort()
  assets.modify(fn(store) { store.add(clip) })
}

///|
pub fn animation_clip_reserve_handle() -> @asset.Handle[AnimationClip] {
  let assets = animation_asset_store_mut_or_abort()
  assets.modify(fn(store) { store.reserve_handle() })
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
  let assets = animation_asset_store_mut_or_abort()
  assets.modify(fn(store) { store.set(handle, clip) })
}

///|
pub(all) enum RepeatAnimation {
  Never
  Count(Int)
  Forever
}

///|
pub impl ToJson for RepeatAnimation with fn to_json(self) {
  match self {
    Never => (0, 0) |> ToJson::to_json
    Count(count) => (1, count) |> ToJson::to_json
    Forever => (2, 0) |> ToJson::to_json
  }
}

///|
pub impl @json.FromJson for RepeatAnimation with fn from_json(json, path) {
  let (tag, payload) : (Int, Int) = @json.from_json(json, path~)
  match tag {
    0 => Never
    1 => Count(payload)
    2 => Forever
    _ => Never
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
pub impl ToJson for ActiveAnimation with fn to_json(self) {
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
  )
  |> ToJson::to_json
}

///|
pub impl @json.FromJson for ActiveAnimation with fn from_json(json, path) {
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
  {
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
pub fn ActiveAnimation::ActiveAnimation() -> ActiveAnimation {
  {
    weight: 1.0F,
    repeat: Never,
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
    Forever => false
    Never => self.completions >= 1
    Count(n) => self.completions >= n
  }
}

///|
pub fn ActiveAnimation::set_weight(
  self : ActiveAnimation,
  weight : Float,
) -> ActiveAnimation {
  { ..self, weight, }
}

///|
pub fn ActiveAnimation::set_repeat(
  self : ActiveAnimation,
  repeat : RepeatAnimation,
) -> ActiveAnimation {
  { ..self, repeat, }
}

///|
pub fn ActiveAnimation::repeat_forever(
  self : ActiveAnimation,
) -> ActiveAnimation {
  self.set_repeat(Forever)
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
  { ..self, speed, }
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
  { ..self, paused: true }
}

///|
pub fn ActiveAnimation::unpause(self : ActiveAnimation) -> ActiveAnimation {
  { ..self, paused: false }
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
  { ..self, seek_time, last_seek_time: Some(seek_time) }
}

///|
pub fn ActiveAnimation::seek_to(
  self : ActiveAnimation,
  seek_time : Float,
) -> ActiveAnimation {
  { ..self, seek_time, last_seek_time: Some(self.seek_time) }
}

///|
pub fn ActiveAnimation::rewind(self : ActiveAnimation) -> ActiveAnimation {
  self.seek_to(0.0F)
}

///|
pub fn ActiveAnimation::replay(self : ActiveAnimation) -> ActiveAnimation {
  {
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

  out.elapsed = out.elapsed + delta_seconds
  out.seek_time = out.seek_time + delta_seconds * out.speed

  let passed_end = out.speed > 0.0F && out.seek_time >= clip_duration_seconds
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
  for node_key in 0..<player.active_animations.length() {
    if player.active_animations[node_key] is Some(_) {
      keys.push(node_key)
    }
  }
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
  active_animations : Array[ActiveAnimation?]
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
  { player, node }
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
pub impl ToJson for AnimationPlayer with fn to_json(self) {
  self.playing_animations() |> ToJson::to_json
}

///|
pub impl @json.FromJson for AnimationPlayer with fn from_json(json, path) {
  let active_animations : Array[(AnimationNodeIndex, ActiveAnimation)] = @json.from_json(
    json,
    path~,
  )
  let active_animations_dense : Array[ActiveAnimation?] = []
  for pair in active_animations {
    let node_key = animation_player_node_key(pair.0)
    if node_key >= 0 {
      while active_animations_dense.length() <= node_key {
        active_animations_dense.push(None)
      }
      active_animations_dense[node_key] = Some(pair.1)
    }
  }
  { active_animations: active_animations_dense }
}

///|
pub fn AnimationPlayer::AnimationPlayer() -> AnimationPlayer {
  { active_animations: [] }
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
  let node_key = animation_player_node_key(node)
  if node_key >= 0 && node_key < self.active_animations.length() {
    self.active_animations[node_key]
  } else {
    None
  }
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
  let node_key = animation_player_node_key(node)
  if node_key >= 0 {
    while self.active_animations.length() <= node_key {
      self.active_animations.push(None)
    }
    self.active_animations[node_key] = Some(active)
  }
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
  let active = ActiveAnimation::ActiveAnimation()
  self.set_animation(node, active) |> ignore
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
  let active = ActiveAnimation::ActiveAnimation()
  self.set_animation(node, active) |> ignore
  animation_player_entry_new(self, node)
}

///|
pub fn AnimationPlayer::stop(
  self : AnimationPlayer,
  node : AnimationNodeIndex,
) -> AnimationPlayer {
  let node_key = animation_player_node_key(node)
  if node_key >= 0 && node_key < self.active_animations.length() {
    self.active_animations[node_key] = None
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
  self.set_repeat(Forever)
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
  ignore(animation_player_tick_in_place(player, graph, delta_seconds))
  player
}

///|
fn animation_player_tick_in_place(
  player : AnimationPlayer,
  graph : AnimationGraph,
  delta_seconds : Float,
) -> Bool {
  let mut changed = false
  for node_i in 0..<graph.nodes.length() {
    guard node_i < player.active_animations.length() &&
      player.active_animations[node_i] is Some(active) else {
      continue
    }
    let mut next_active = active
    if active.is_paused() {
      ()
    } else if graph.nodes[node_i].node_type is Clip(clip_handle) {
      if animation_clip_get(clip_handle) is Some(clip) {
        next_active = active.update(delta_seconds, clip.duration())
      }
    }
    player.active_animations[node_i] = Some(next_active)
    changed = true
  }
  changed
}

///|
priv struct AnimationPreparedPlayer {
  graph_id : Int
  graph : AnimationGraph
  active_by_node : Array[ActiveAnimation?]
  threaded_graph : ThreadedAnimationGraph
}

///|
priv struct AnimationFrameCurveCache {
  mut stamp : Int
  mut len : Int
  stamps : Array[Int]
  clip_ids : Array[Int]
  target_highs : Array[UInt64]
  target_lows : Array[UInt64]
  curves : Array[AnimationTargetCurves?]
  mut hits : Int
  mut misses : Int
  mut empty_hits : Int
}

///|
fn animation_frame_curve_cache_new() -> AnimationFrameCurveCache {
  {
    stamp: 1,
    len: 0,
    stamps: [],
    clip_ids: [],
    target_highs: [],
    target_lows: [],
    curves: [],
    hits: 0,
    misses: 0,
    empty_hits: 0,
  }
}

///|
fn animation_frame_curve_cache_ensure_capacity(
  cache : AnimationFrameCurveCache,
  capacity : Int,
) -> Unit {
  while cache.stamps.length() < capacity {
    cache.stamps.push(0)
    cache.clip_ids.push(-1)
    cache.target_highs.push(0UL)
    cache.target_lows.push(0UL)
    cache.curves.push(None)
  }
}

///|
fn animation_frame_curve_cache_clear(cache : AnimationFrameCurveCache) -> Unit {
  cache.stamp = cache.stamp + 1
  cache.len = 0
  cache.hits = 0
  cache.misses = 0
  cache.empty_hits = 0
  if cache.stamp <= 0 {
    cache.stamp = 1
    for i in 0..<cache.stamps.length() {
      cache.stamps[i] = 0
    }
  }
}

///|
fn animation_frame_curve_cache_hash(
  clip_id : Int,
  target_high : UInt64,
  target_low : UInt64,
  capacity : Int,
) -> Int {
  if capacity <= 0 {
    return 0
  }
  let mut hash = clip_id * 16777619
  hash = hash ^ target_high.to_int()
  hash = hash ^ (target_low.to_int() * 31)
  let index = hash % capacity
  if index < 0 {
    index + capacity
  } else {
    index
  }
}

///|
fn animation_frame_curve_cache_insert_known(
  cache : AnimationFrameCurveCache,
  clip_id : Int,
  target_high : UInt64,
  target_low : UInt64,
  curves : AnimationTargetCurves?,
) -> Unit {
  let capacity = cache.stamps.length()
  if capacity == 0 {
    return
  }
  let mut index = animation_frame_curve_cache_hash(
    clip_id, target_high, target_low, capacity,
  )
  while cache.stamps[index] == cache.stamp {
    index = (index + 1) % capacity
  }
  cache.stamps[index] = cache.stamp
  cache.clip_ids[index] = clip_id
  cache.target_highs[index] = target_high
  cache.target_lows[index] = target_low
  cache.curves[index] = curves
  cache.len = cache.len + 1
}

///|
fn animation_frame_curve_cache_grow(cache : AnimationFrameCurveCache) -> Unit {
  let old_capacity = cache.stamps.length()
  let new_capacity = if old_capacity <= 0 { 256 } else { old_capacity * 2 }
  let old_stamp = cache.stamp
  let old_stamps = cache.stamps.copy()
  let old_clip_ids = cache.clip_ids.copy()
  let old_target_highs = cache.target_highs.copy()
  let old_target_lows = cache.target_lows.copy()
  let old_curves = cache.curves.copy()
  cache.stamps.clear()
  cache.clip_ids.clear()
  cache.target_highs.clear()
  cache.target_lows.clear()
  cache.curves.clear()
  cache.len = 0
  animation_frame_curve_cache_ensure_capacity(cache, new_capacity)
  for i in 0..<old_stamps.length() {
    if old_stamps[i] == old_stamp {
      animation_frame_curve_cache_insert_known(
        cache,
        old_clip_ids[i],
        old_target_highs[i],
        old_target_lows[i],
        old_curves[i],
      )
    }
  }
}

///|
fn animation_frame_curves_cached(
  frame_curve_cache : AnimationFrameCurveCache,
  clip_id : Int,
  clip : AnimationClip,
  target_id : AnimationTargetId,
) -> AnimationTargetCurves? {
  let target_key = animation_target_id_lookup_key(target_id)
  if frame_curve_cache.stamps.length() == 0 ||
    (frame_curve_cache.len + 1) * 3 >= frame_curve_cache.stamps.length() * 2 {
    animation_frame_curve_cache_grow(frame_curve_cache)
  }
  let capacity = frame_curve_cache.stamps.length()
  let mut index = animation_frame_curve_cache_hash(
    clip_id,
    target_key.0,
    target_key.1,
    capacity,
  )
  while frame_curve_cache.stamps[index] == frame_curve_cache.stamp {
    if frame_curve_cache.clip_ids[index] == clip_id &&
      frame_curve_cache.target_highs[index] == target_key.0 &&
      frame_curve_cache.target_lows[index] == target_key.1 {
      frame_curve_cache.hits = frame_curve_cache.hits + 1
      if frame_curve_cache.curves[index] is None {
        frame_curve_cache.empty_hits = frame_curve_cache.empty_hits + 1
      }
      return frame_curve_cache.curves[index]
    }
    index = (index + 1) % capacity
  }
  let curves = clip.curves_for_target(target_id)
  frame_curve_cache.misses = frame_curve_cache.misses + 1
  frame_curve_cache.stamps[index] = frame_curve_cache.stamp
  frame_curve_cache.clip_ids[index] = clip_id
  frame_curve_cache.target_highs[index] = target_key.0
  frame_curve_cache.target_lows[index] = target_key.1
  frame_curve_cache.curves[index] = curves
  frame_curve_cache.len = frame_curve_cache.len + 1
  curves
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
fn animation_prepared_active_by_node_into(
  graph : AnimationGraph,
  player : AnimationPlayer,
  active_by_node : Array[ActiveAnimation?],
) -> Array[ActiveAnimation?] {
  let node_count = graph.nodes.length()
  while active_by_node.length() < node_count {
    active_by_node.push(None)
  }
  while active_by_node.length() > node_count {
    ignore(active_by_node.remove(active_by_node.length() - 1))
  }
  for node_i in 0..<node_count {
    active_by_node[node_i] = None
  }
  for node_key in 0..<player.active_animations.length() {
    if node_key < active_by_node.length() &&
      player.active_animations[node_key] is Some(active) {
      active_by_node[node_key] = Some(active)
    }
  }
  active_by_node
}

///|
priv struct AnimationStackElement {
  mut graph_node : AnimationNodeIndex
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
  mut translation : @math.Vec3
  mut rotation : @math.Quat
  mut scale : @math.Vec3
  weights : Array[Float]
  mut text_color : @color.Color
}

///|
priv struct AnimationEvaluationState {
  stack : Array[AnimationStackElement]
  mut stack_len : Int
  register : AnimationStackElement
}

///|
priv struct AnimationEvaluationOutput {
  mut has_transform : Bool
  mut transform : @transform.Transform
  mut weights : AnimationWeights?
  mut text_color : @text.TextColor?
}

///|
fn animation_stack_element_empty(
  graph_node : AnimationNodeIndex,
) -> AnimationStackElement {
  {
    graph_node,
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
    translation: @math.Vec3::zero(),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::zero(),
    weights: [],
    text_color: @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
  }
}

///|
fn animation_stack_element_clear(
  element : AnimationStackElement,
  graph_node : AnimationNodeIndex,
) -> Unit {
  element.graph_node = graph_node
  element.has_translation = false
  element.has_rotation = false
  element.has_scale = false
  element.has_weights = false
  element.has_text_color = false
  element.translation_weight = 0.0F
  element.rotation_weight = 0.0F
  element.scale_weight = 0.0F
  element.weights_weight = 0.0F
  element.text_color_weight = 0.0F
  element.translation = @math.Vec3::zero()
  element.rotation = @math.Quat::identity()
  element.scale = @math.Vec3::zero()
  element.weights.clear()
  element.text_color = @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
fn animation_stack_element_has_value(element : AnimationStackElement) -> Bool {
  element.has_translation ||
  element.has_rotation ||
  element.has_scale ||
  element.has_weights ||
  element.has_text_color
}

///|
fn animation_weights_copy(values : Array[Float]) -> Array[Float] {
  let copied : Array[Float] = []
  for value in values {
    copied.push(value)
  }
  copied
}

///|
fn animation_weights_scaled(
  values : Array[Float],
  weight : Float,
) -> Array[Float] {
  let out : Array[Float] = []
  for value in values {
    out.push(value * weight)
  }
  out
}

///|
fn animation_weights_add_scaled(
  current : Array[Float],
  incoming : Array[Float],
  weight : Float,
) -> Array[Float] {
  let len = if current.length() > incoming.length() {
    current.length()
  } else {
    incoming.length()
  }
  let out : Array[Float] = []
  for i in 0..<len {
    let current_value = match current.get(i) {
      Some(value) => value
      None => 0.0F
    }
    let incoming_value = match incoming.get(i) {
      Some(value) => value * weight
      None => 0.0F
    }
    out.push(current_value + incoming_value)
  }
  out
}

///|
fn animation_color_add_scaled(
  current : @color.Color,
  incoming : @color.Color,
  weight : Float,
) -> @color.Color {
  @color.Color::new(
    current.r + incoming.r * weight,
    current.g + incoming.g * weight,
    current.b + incoming.b * weight,
    current.a + incoming.a * weight,
  )
}

///|
fn animation_evaluation_state_new() -> AnimationEvaluationState {
  {
    stack: [],
    stack_len: 0,
    register: animation_stack_element_empty(AnimationNodeIndex::new(-1)),
  }
}

///|
fn animation_evaluation_output_new() -> AnimationEvaluationOutput {
  {
    has_transform: false,
    transform: @transform.Transform::identity(),
    weights: None,
    text_color: None,
  }
}

///|
fn animation_evaluation_output_clear(
  output : AnimationEvaluationOutput,
) -> Unit {
  output.has_transform = false
  output.weights = None
  output.text_color = None
}

///|
fn animation_evaluation_state_reset(state : AnimationEvaluationState) -> Unit {
  state.stack_len = 0
  animation_stack_element_clear(state.register, AnimationNodeIndex::new(-1))
}

///|
fn animation_evaluation_state_next_stack_element(
  state : AnimationEvaluationState,
  graph_node : AnimationNodeIndex,
) -> AnimationStackElement {
  if state.stack_len < state.stack.length() {
    let existing = state.stack[state.stack_len]
    animation_stack_element_clear(existing, graph_node)
    existing
  } else {
    let created = animation_stack_element_empty(graph_node)
    state.stack.push(created)
    created
  }
}

///|
fn animation_evaluation_state_push_target_curves(
  state : AnimationEvaluationState,
  graph_node : AnimationNodeIndex,
  curves : AnimationTargetCurves,
  time_seconds : Float,
  weight : Float,
) -> Unit {
  let element = animation_evaluation_state_next_stack_element(state, graph_node)
  if curves.translation.length() > 0 {
    let translation = animation_sample_vec3_non_empty(
      curves.translation,
      time_seconds,
    )
    element.has_translation = true
    element.translation = translation
    element.translation_weight = weight
  }
  if curves.rotation.length() > 0 {
    let rotation = animation_sample_quat_non_empty(
      curves.rotation,
      time_seconds,
    )
    element.has_rotation = true
    element.rotation = rotation
    element.rotation_weight = weight
  }
  if curves.scale.length() > 0 {
    let scale = animation_sample_vec3_non_empty(curves.scale, time_seconds)
    element.has_scale = true
    element.scale = scale
    element.scale_weight = weight
  }
  if curves.weights.length() > 0 {
    let weights = animation_sample_weights_non_empty(
      curves.weights,
      time_seconds,
    )
    element.has_weights = true
    element.weights_weight = weight
    for value in weights {
      element.weights.push(value)
    }
  }
  if curves.text_color.length() > 0 {
    let text_color = animation_sample_color_non_empty(
      curves.text_color,
      time_seconds,
    )
    element.has_text_color = true
    element.text_color = text_color
    element.text_color_weight = weight
  }
  if animation_stack_element_has_value(element) {
    state.stack_len = state.stack_len + 1
  }
}

///|
fn animation_register_merge_translation(
  register : AnimationStackElement,
  incoming : AnimationStackElement,
  additive : Bool,
) -> Unit {
  if !incoming.has_translation {
    return
  }
  if !register.has_translation {
    register.has_translation = true
    register.translation_weight = incoming.translation_weight
    register.translation = if additive {
      incoming.translation.mul_scalar(incoming.translation_weight)
    } else {
      incoming.translation
    }
    return
  }
  register.translation_weight = register.translation_weight +
    incoming.translation_weight
  if additive {
    register.translation = register.translation.add(
      incoming.translation.mul_scalar(incoming.translation_weight),
    )
  } else {
    register.translation = animation_interpolate_vec3_unclamped(
      register.translation,
      incoming.translation,
      incoming.translation_weight / register.translation_weight,
    )
  }
}

///|
fn animation_register_merge_rotation(
  register : AnimationStackElement,
  incoming : AnimationStackElement,
  additive : Bool,
) -> Unit {
  if !incoming.has_rotation {
    return
  }
  if !register.has_rotation {
    register.has_rotation = true
    register.rotation_weight = incoming.rotation_weight
    register.rotation = if additive {
      animation_interpolate_quat_unclamped(
        @math.Quat::identity(),
        incoming.rotation,
        incoming.rotation_weight,
      )
    } else {
      incoming.rotation
    }
    return
  }
  register.rotation_weight = register.rotation_weight + incoming.rotation_weight
  if additive {
    register.rotation = animation_interpolate_quat_unclamped(
      @math.Quat::identity(),
      incoming.rotation,
      incoming.rotation_weight,
    ).mul(register.rotation)
  } else {
    register.rotation = animation_interpolate_quat_unclamped(
      register.rotation,
      incoming.rotation,
      incoming.rotation_weight / register.rotation_weight,
    )
  }
}

///|
fn animation_register_merge_scale(
  register : AnimationStackElement,
  incoming : AnimationStackElement,
  additive : Bool,
) -> Unit {
  if !incoming.has_scale {
    return
  }
  if !register.has_scale {
    register.has_scale = true
    register.scale_weight = incoming.scale_weight
    register.scale = if additive {
      incoming.scale.mul_scalar(incoming.scale_weight)
    } else {
      incoming.scale
    }
    return
  }
  register.scale_weight = register.scale_weight + incoming.scale_weight
  if additive {
    register.scale = register.scale.add(
      incoming.scale.mul_scalar(incoming.scale_weight),
    )
  } else {
    register.scale = animation_interpolate_vec3_unclamped(
      register.scale,
      incoming.scale,
      incoming.scale_weight / register.scale_weight,
    )
  }
}

///|
fn animation_register_merge_weights(
  register : AnimationStackElement,
  incoming : AnimationStackElement,
  additive : Bool,
) -> Unit {
  if !incoming.has_weights {
    return
  }
  if !register.has_weights {
    register.has_weights = true
    register.weights_weight = incoming.weights_weight
    register.weights.clear()
    let values = if additive {
      animation_weights_scaled(incoming.weights, incoming.weights_weight)
    } else {
      animation_weights_copy(incoming.weights)
    }
    for value in values {
      register.weights.push(value)
    }
    return
  }
  register.weights_weight = register.weights_weight + incoming.weights_weight
  let values = if additive {
    animation_weights_add_scaled(
      register.weights,
      incoming.weights,
      incoming.weights_weight,
    )
  } else {
    animation_interpolate_weights_unclamped(
      register.weights,
      incoming.weights,
      incoming.weights_weight / register.weights_weight,
    )
  }
  register.weights.clear()
  for value in values {
    register.weights.push(value)
  }
}

///|
fn animation_register_merge_text_color(
  register : AnimationStackElement,
  incoming : AnimationStackElement,
  additive : Bool,
) -> Unit {
  if !incoming.has_text_color {
    return
  }
  if !register.has_text_color {
    register.has_text_color = true
    register.text_color_weight = incoming.text_color_weight
    register.text_color = if additive {
      animation_color_add_scaled(
        @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
        incoming.text_color,
        incoming.text_color_weight,
      )
    } else {
      incoming.text_color
    }
    return
  }
  register.text_color_weight = register.text_color_weight +
    incoming.text_color_weight
  if additive {
    register.text_color = animation_color_add_scaled(
      register.text_color,
      incoming.text_color,
      incoming.text_color_weight,
    )
  } else {
    register.text_color = animation_interpolate_color_unclamped(
      register.text_color,
      incoming.text_color,
      incoming.text_color_weight / register.text_color_weight,
    )
  }
}

///|
fn animation_evaluation_state_combine_top(
  state : AnimationEvaluationState,
  graph_node : AnimationNodeIndex,
  additive : Bool,
) -> Unit {
  if state.stack_len == 0 {
    return
  }
  let top_index = state.stack_len - 1
  let incoming = state.stack[top_index]
  if incoming.graph_node != graph_node {
    return
  }
  state.stack_len = top_index
  animation_register_merge_translation(state.register, incoming, additive)
  animation_register_merge_rotation(state.register, incoming, additive)
  animation_register_merge_scale(state.register, incoming, additive)
  animation_register_merge_weights(state.register, incoming, additive)
  animation_register_merge_text_color(state.register, incoming, additive)
}

///|
fn animation_evaluation_state_push_blend_register(
  state : AnimationEvaluationState,
  weight : Float,
  graph_node : AnimationNodeIndex,
) -> Unit {
  if !animation_stack_element_has_value(state.register) {
    return
  }
  let element = animation_evaluation_state_next_stack_element(state, graph_node)
  if state.register.has_translation {
    element.has_translation = true
    element.translation = state.register.translation
    element.translation_weight = weight
  }
  if state.register.has_rotation {
    element.has_rotation = true
    element.rotation = state.register.rotation
    element.rotation_weight = weight
  }
  if state.register.has_scale {
    element.has_scale = true
    element.scale = state.register.scale
    element.scale_weight = weight
  }
  if state.register.has_weights {
    element.has_weights = true
    element.weights_weight = weight
    for value in state.register.weights {
      element.weights.push(value)
    }
  }
  if state.register.has_text_color {
    element.has_text_color = true
    element.text_color = state.register.text_color
    element.text_color_weight = weight
  }
  state.stack_len = state.stack_len + 1
  animation_stack_element_clear(state.register, AnimationNodeIndex::new(-1))
}

///|
fn animation_evaluation_state_commit_into(
  state : AnimationEvaluationState,
  base_transform : @transform.Transform?,
  output : AnimationEvaluationOutput,
) -> Unit {
  animation_evaluation_output_clear(output)
  if state.stack_len == 0 {
    return
  }
  let result = state.stack[state.stack_len - 1]
  if result.has_translation || result.has_rotation || result.has_scale {
    let base = match base_transform {
      Some(transform) => transform
      None => @transform.Transform::identity()
    }
    let mut changed = base_transform is None
    if result.has_translation {
      if !animation_vec3_eq(base.translation, result.translation) {
        base.translation = result.translation
        changed = true
      }
    }
    if result.has_rotation {
      if !animation_quat_eq(base.rotation, result.rotation) {
        base.rotation = result.rotation
        changed = true
      }
    }
    if result.has_scale {
      if !animation_vec3_eq(base.scale, result.scale) {
        base.scale = result.scale
        changed = true
      }
    }
    if changed {
      output.has_transform = true
      output.transform = base
    }
  }
  if result.has_weights {
    output.weights = Some(
      AnimationWeights::new(animation_weights_copy(result.weights)),
    )
  }
  if result.has_text_color {
    output.text_color = Some(@text.TextColor::new(result.text_color))
  }
}

///|
fn animation_apply_threaded_player_to_target(
  world : @ecs.World,
  writer : @core.MessageWriter[AnimationTriggeredEvent],
  player_entity : @core.Entity,
  target_entity : @core.Entity,
  target_id : AnimationTargetId,
  target_mask : AnimationMask,
  active_by_node : Array[ActiveAnimation?],
  graph : AnimationGraph,
  threaded_graph : ThreadedAnimationGraph,
  clip_cache : Map[Int, AnimationClip],
  frame_curve_cache : AnimationFrameCurveCache,
  evaluation_state : AnimationEvaluationState,
  base_transform : @transform.Transform?,
  output : AnimationEvaluationOutput,
  counters : AnimationTargetCounters,
) -> Unit {
  animation_evaluation_state_reset(evaluation_state)

  for node_index in threaded_graph.threaded_graph {
    let node_i = node_index.index()
    guard node_i >= 0 && node_i < graph.nodes.length() else { continue }
    let node = graph.nodes[node_i]
    match node.node_type {
      Blend => {
        let (edge_start, edge_end) = threaded_graph.sorted_edge_ranges[node_i]
        for edge_i in edge_start..<edge_end {
          animation_evaluation_state_combine_top(
            evaluation_state,
            threaded_graph.sorted_edges[edge_i],
            false,
          )
        }
        animation_evaluation_state_push_blend_register(
          evaluation_state,
          node.weight,
          node_index,
        )
      }
      Add => {
        let (edge_start, edge_end) = threaded_graph.sorted_edge_ranges[node_i]
        for edge_i in edge_start..<edge_end {
          animation_evaluation_state_combine_top(
            evaluation_state,
            threaded_graph.sorted_edges[edge_i],
            true,
          )
        }
        animation_evaluation_state_push_blend_register(
          evaluation_state,
          node.weight,
          node_index,
        )
      }
      Clip(clip_handle) => {
        guard active_by_node[node_i] is Some(active) else { continue }
        let computed_mask = threaded_graph.computed_masks[node_i]
        if active.weight() == 0.0F || (target_mask & computed_mask) != 0U {
          continue
        }
        guard animation_clip_cached_or_load(clip_handle, clip_cache)
          is Some(clip) else {
          continue
        }
        let clip_id = clip_handle.id()
        if !active.is_paused() && clip.events.length() > 0 {
          if animation_clip_events_for_target(clip, target_id) is Some(events) {
            let triggered = animation_clip_collect_triggered_events(
              events, active,
            )
            if triggered.length() > 0 {
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
          }
        }
        guard animation_frame_curves_cached(
            frame_curve_cache, clip_id, clip, target_id,
          )
          is Some(curves) else {
          continue
        }
        counters.sampled_curves = counters.sampled_curves + 1
        animation_evaluation_state_push_target_curves(
          evaluation_state,
          node_index,
          curves,
          active.seek_time(),
          active.weight() * node.weight,
        )
      }
    }
  }

  animation_evaluation_state_commit_into(
    evaluation_state, base_transform, output,
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
pub let animation_set_expire_transitions : @app.SystemSet = @app.system_set(
  "mgstudio.animation.expire_transitions",
)

///|
priv struct AnimationRuntimeScratch {
  mut frame_stamp : Int
  transform_updates : Array[(@core.Entity, @transform.Transform)]
  weights_updates : Array[(@core.Entity, AnimationWeights)]
  text_color_updates : Array[(@core.Entity, @text.TextColor)]
  prepared_player_values : Array[AnimationPreparedPlayer?]
  prepared_player_generations : Array[Int]
  prepared_player_stamps : Array[Int]
  frame_curve_cache : AnimationFrameCurveCache
  target_mask_cache : Map[(Int, UInt64, UInt64), AnimationMask]
  graph_cache : Map[Int, AnimationGraph]
  clip_cache : Map[Int, AnimationClip]
  threaded_graph_cache : Map[Int, ThreadedAnimationGraph]
}

///|
fn AnimationRuntimeScratch::AnimationRuntimeScratch() -> AnimationRuntimeScratch {
  {
    frame_stamp: 0,
    transform_updates: [],
    weights_updates: [],
    text_color_updates: [],
    prepared_player_values: [],
    prepared_player_generations: [],
    prepared_player_stamps: [],
    frame_curve_cache: animation_frame_curve_cache_new(),
    target_mask_cache: Map([]),
    graph_cache: Map([]),
    clip_cache: Map([]),
    threaded_graph_cache: Map([]),
  }
}

///|
let ecs_key_animation_runtime_scratch : @ecs.ResourceKey[
  AnimationRuntimeScratch,
] = @ecs.register_resource(debug_name="mgstudio.animation.runtime_scratch")

///|
priv struct AnimationTargetCounters {
  mut players_prepared : Int
  mut targets_processed : Int
  mut sampled_curves : Int
  mut transform_writes : Int
  mut morph_weight_writes : Int
  mut text_color_writes : Int
}

///|
fn AnimationTargetCounters::AnimationTargetCounters() -> AnimationTargetCounters {
  {
    players_prepared: 0,
    targets_processed: 0,
    sampled_curves: 0,
    transform_writes: 0,
    morph_weight_writes: 0,
    text_color_writes: 0,
  }
}

///|
fn animation_vec3_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

///|
fn animation_quat_eq(lhs : @math.Quat, rhs : @math.Quat) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
}

///|
fn animation_weights_eq(lhs : AnimationWeights, rhs : AnimationWeights) -> Bool {
  let lhs_values = lhs.values()
  let rhs_values = rhs.values()
  if lhs_values.length() != rhs_values.length() {
    return false
  }
  for index in 0..<lhs_values.length() {
    if lhs_values[index] != rhs_values[index] {
      return false
    }
  }
  true
}

///|
fn animation_color_eq(lhs : @color.Color, rhs : @color.Color) -> Bool {
  lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
}

///|
fn animation_text_color_eq(
  lhs : @text.TextColor,
  rhs : @text.TextColor,
) -> Bool {
  animation_color_eq(lhs.color, rhs.color)
}

///|
fn animation_runtime_scratch_ref_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[AnimationRuntimeScratch] {
  match world.get_resource_mut(ecs_key_animation_runtime_scratch) {
    Some(state_ref) => state_ref
    None => {
      world.insert_resource(
        ecs_key_animation_runtime_scratch,
        AnimationRuntimeScratch(),
      )
      match world.get_resource_mut(ecs_key_animation_runtime_scratch) {
        Some(state_ref) => state_ref
        None => abort("Missing AnimationRuntimeScratch resource")
      }
    }
  }
}

///|
fn animation_runtime_scratch_clear(state : AnimationRuntimeScratch) -> Unit {
  state.frame_stamp = state.frame_stamp + 1
  state.transform_updates.clear()
  state.weights_updates.clear()
  state.text_color_updates.clear()
  animation_frame_curve_cache_clear(state.frame_curve_cache)
  state.target_mask_cache.clear()
  state.graph_cache.clear()
  state.clip_cache.clear()
  state.threaded_graph_cache.clear()
}

///|
fn animation_runtime_scratch_store_prepared_player(
  state : AnimationRuntimeScratch,
  entity : @core.Entity,
  prepared : AnimationPreparedPlayer,
) -> Unit {
  let entity_id = entity.id
  if entity_id < 0 {
    return
  }
  while state.prepared_player_values.length() <= entity_id {
    state.prepared_player_values.push(None)
    state.prepared_player_generations.push(0)
    state.prepared_player_stamps.push(0)
  }
  state.prepared_player_values[entity_id] = Some(prepared)
  state.prepared_player_generations[entity_id] = entity.generation
  state.prepared_player_stamps[entity_id] = state.frame_stamp
}

///|
fn animation_runtime_scratch_prepared_player(
  state : AnimationRuntimeScratch,
  entity : @core.Entity,
) -> AnimationPreparedPlayer? {
  let entity_id = entity.id
  if entity_id < 0 || entity_id >= state.prepared_player_values.length() {
    return None
  }
  if entity_id >= state.prepared_player_generations.length() ||
    entity_id >= state.prepared_player_stamps.length() {
    return None
  }
  if state.prepared_player_generations[entity_id] != entity.generation ||
    state.prepared_player_stamps[entity_id] != state.frame_stamp {
    return None
  }
  state.prepared_player_values[entity_id]
}

///|
fn animation_runtime_scratch_active_by_node_storage(
  state : AnimationRuntimeScratch,
  entity : @core.Entity,
) -> Array[ActiveAnimation?] {
  let entity_id = entity.id
  if entity_id >= 0 &&
    entity_id < state.prepared_player_values.length() &&
    entity_id < state.prepared_player_generations.length() &&
    state.prepared_player_generations[entity_id] == entity.generation &&
    state.prepared_player_values[entity_id] is Some(prepared) {
    prepared.active_by_node
  } else {
    []
  }
}

///|
fn animation_target_mask_cached(
  target_mask_cache : Map[(Int, UInt64, UInt64), AnimationMask],
  graph_id : Int,
  graph : AnimationGraph,
  target_id : AnimationTargetId,
) -> AnimationMask {
  if graph.mask_groups.length() == 0 {
    return 0U
  }
  let target_key = animation_target_id_lookup_key(target_id)
  let cache_key = (graph_id, target_key.0, target_key.1)
  match target_mask_cache.get(cache_key) {
    Some(mask) => mask
    None => {
      let mask = graph.target_mask(target_id)
      target_mask_cache.set(cache_key, mask)
      mask
    }
  }
}

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
pub impl @ecs.Component for AnimationGraphHandle with fn component() {
  ecs_key_animation_graph_handle
}

///|
pub impl @ecs.Component for AnimationTransitions with fn component() {
  ecs_key_animation_transitions
}

///|
pub impl @ecs.Component for AnimationWeights with fn component() {
  ecs_key_animation_weights
}

///|
fn animation_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match world.get_resource(@time.default_time_resource_key) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in animation systems")
  }
}

///|
pub fn advance_animations(world : @ecs.World) -> Unit {
  let delta_seconds = animation_default_time_or_default(world).delta_seconds()
  let player_column = world.component_column(ecs_key_animation_player)
  let graph_handle_column = world.component_column(
    ecs_key_animation_graph_handle,
  )
  let write_tick : @core.Tick = {
    let tick = world.read_change_tick()
    if tick > 0 {
      tick
    } else {
      1
    }
  }
  if player_column is Some(player_column) &&
    graph_handle_column is Some(graph_handle_column) {
    player_column.for_each_with_fast_table_row(graph_handle_column, fn(
      entity,
      table_id,
      row_index,
      player,
      graph_handle,
    ) {
      guard animation_graph_get(graph_handle.graph()) is Some(graph) else {
        return
      }
      if animation_player_tick_in_place(player, graph, delta_seconds) {
        if table_id >= 0 && row_index >= 0 {
          ignore(
            player_column.record_changed_hot_at_table_row(
              table_id, row_index, write_tick,
            ),
          )
        } else {
          try! world.set_by_key(entity, ecs_key_animation_player, player)
        }
      }
    })
    return
  }
  let player_query : @ecs.Query[@ecs.Read[AnimationPlayer], @ecs.All] = @ecs.query(
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
    try! world.set_by_key(
      entity,
      ecs_key_animation_player,
      animation_player_tick(player.value(), graph, delta_seconds),
    )
  })
}

///|
pub fn animate_targets(world : @ecs.World) -> Unit {
  let runtime_scratch_ref = animation_runtime_scratch_ref_or_init(world)
  runtime_scratch_ref.modify(fn(runtime_scratch) {
    animation_runtime_scratch_clear(runtime_scratch)
    let transform_updates = runtime_scratch.transform_updates
    let weights_updates = runtime_scratch.weights_updates
    let text_color_updates = runtime_scratch.text_color_updates
    let target_mask_cache = runtime_scratch.target_mask_cache
    let threaded_graphs = world.get_resource(threaded_animation_graphs_key)
    let graph_cache = runtime_scratch.graph_cache
    let clip_cache = runtime_scratch.clip_cache
    let threaded_graph_cache = runtime_scratch.threaded_graph_cache
    let counters = AnimationTargetCounters::AnimationTargetCounters()

    let player_preparation_trace_start_us = @app.timeline_trace_begin_span(
      System,
      "animation_targets.player_preparation",
    )
    let prepare_player = fn(
      player_entity : @core.Entity,
      player : AnimationPlayer,
      graph_handle : AnimationGraphHandle,
    ) {
      let player_id = player_entity.id
      if player_id < 0 {
        return
      }
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
          match threaded_graphs.graphs.get(graph_handle_id) {
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
      let active_by_node = animation_prepared_active_by_node_into(
        graph,
        player,
        animation_runtime_scratch_active_by_node_storage(
          runtime_scratch, player_entity,
        ),
      )
      animation_runtime_scratch_store_prepared_player(
        runtime_scratch,
        player_entity,
        { graph_id: graph_handle_id, graph, active_by_node, threaded_graph },
      )
      counters.players_prepared = counters.players_prepared + 1
    }
    let player_column = world.component_column(ecs_key_animation_player)
    let graph_handle_column = world.component_column(
      ecs_key_animation_graph_handle,
    )
    if player_column is Some(player_column) &&
      graph_handle_column is Some(graph_handle_column) {
      player_column.for_each_with_fast_table_row(graph_handle_column, fn(
        player_entity,
        _table_id,
        _row_index,
        player,
        graph_handle,
      ) {
        prepare_player(player_entity, player, graph_handle)
      })
    } else {
      let player_query : @ecs.Query[
        (
          @core.Entity,
          @ecs.Read[AnimationPlayer],
          @ecs.Read[AnimationGraphHandle],
        ),
        @ecs.All,
      ] = @ecs.query(world)
      try! player_query.view(fn(_entity, player_data) {
        let (player_entity, player_comp, graph_handle_comp) = player_data
        prepare_player(
          player_entity,
          player_comp.value(),
          graph_handle_comp.value(),
        )
      })
    }
    @app.timeline_trace_end_span(
      System,
      "animation_targets.player_preparation",
      player_preparation_trace_start_us,
    )

    let target_id_column = world.component_column(ecs_key_animation_target_id)
    let animated_by_column = world.component_column(ecs_key_animated_by)
    let transform_column = world.component_column(@transform.ecs_key_transform)
    let weights_column = world.component_column(ecs_key_animation_weights)
    let text_color_column = world.component_column(@text.ecs_key_text_color)
    let mut cached_transform_table_id = -1
    let mut cached_transform_table_column : @ecs.ComponentTableColumn[
      @transform.Transform,
    ]? = None
    let mut cached_weights_table_id = -1
    let mut cached_weights_table_column : @ecs.ComponentTableColumn[
      AnimationWeights,
    ]? = None
    let mut cached_text_color_table_id = -1
    let mut cached_text_color_table_column : @ecs.ComponentTableColumn[
      @text.TextColor,
    ]? = None
    let transform_table_column_for = fn(
      table_id : Int,
    ) -> @ecs.ComponentTableColumn[@transform.Transform]? {
      if table_id < 0 {
        return None
      }
      if table_id == cached_transform_table_id {
        return cached_transform_table_column
      }
      cached_transform_table_id = table_id
      cached_transform_table_column = match transform_column {
        Some(column) => column.table_column(table_id)
        None => None
      }
      cached_transform_table_column
    }
    let weights_table_column_for = fn(
      table_id : Int,
    ) -> @ecs.ComponentTableColumn[AnimationWeights]? {
      if table_id < 0 {
        return None
      }
      if table_id == cached_weights_table_id {
        return cached_weights_table_column
      }
      cached_weights_table_id = table_id
      cached_weights_table_column = match weights_column {
        Some(column) => column.table_column(table_id)
        None => None
      }
      cached_weights_table_column
    }
    let text_color_table_column_for = fn(
      table_id : Int,
    ) -> @ecs.ComponentTableColumn[@text.TextColor]? {
      if table_id < 0 {
        return None
      }
      if table_id == cached_text_color_table_id {
        return cached_text_color_table_column
      }
      cached_text_color_table_id = table_id
      cached_text_color_table_column = match text_color_column {
        Some(column) => column.table_column(table_id)
        None => None
      }
      cached_text_color_table_column
    }
    let evaluation_state = animation_evaluation_state_new()
    let evaluation_output = animation_evaluation_output_new()
    let writer : @core.MessageWriter[AnimationTriggeredEvent] = @core.Message::writer(
      @app.current_system_ticks().this_run,
    )
    let write_tick : @core.Tick = {
      let tick = world.read_change_tick()
      if tick > 0 {
        tick
      } else {
        1
      }
    }
    if target_id_column is Some(target_id_column) &&
      animated_by_column is Some(animated_by_column) {
      let target_iteration_trace_start_us = @app.timeline_trace_begin_span(
        System,
        "animation_targets.target_iteration",
      )
      let process_target = fn(
        entity : @core.Entity,
        table_id : Int,
        row_index : Int,
        animated_by : AnimatedBy,
        target_id : AnimationTargetId,
        base_transform : @transform.Transform?,
      ) -> Bool {
        let player_entity = animated_by.player()
        let player_id = player_entity.id
        if player_id < 0 {
          return false
        }
        let prepared_player = match
          animation_runtime_scratch_prepared_player(
            runtime_scratch, player_entity,
          ) {
          Some(cached) => cached
          None => return false
        }
        counters.targets_processed = counters.targets_processed + 1
        let target_mask = animation_target_mask_cached(
          target_mask_cache,
          prepared_player.graph_id,
          prepared_player.graph,
          target_id,
        )
        animation_apply_threaded_player_to_target(
          world,
          writer,
          player_entity,
          entity,
          target_id,
          target_mask,
          prepared_player.active_by_node,
          prepared_player.graph,
          prepared_player.threaded_graph,
          clip_cache,
          runtime_scratch.frame_curve_cache,
          evaluation_state,
          base_transform,
          evaluation_output,
          counters,
        )

        if evaluation_output.has_transform {
          let transform = evaluation_output.transform
          let wrote = match transform_column {
            Some(column) =>
              if base_transform is Some(_) && table_id >= 0 && row_index >= 0 {
                match transform_table_column_for(table_id) {
                  Some(table_column) =>
                    table_column.record_changed_at_row(row_index, write_tick)
                  None =>
                    column.record_changed_hot_at_table_row(
                      table_id, row_index, write_tick,
                    )
                }
              } else {
                column.set_tick_only_hot(entity, transform)
              }
            None => false
          }
          if !wrote {
            transform_updates.push((entity, transform))
          }
          counters.transform_writes = counters.transform_writes + 1
        }
        if evaluation_output.weights is Some(weights) {
          let weights_changed = match weights_column {
            Some(_) =>
              if table_id >= 0 && row_index >= 0 {
                match weights_table_column_for(table_id) {
                  Some(table_column) =>
                    match table_column.value_at_row_unchecked(row_index) {
                      Some(current_weights) =>
                        !animation_weights_eq(current_weights, weights)
                      None => true
                    }
                  None => true
                }
              } else {
                true
              }
            None => true
          }
          let wrote = match weights_column {
            Some(column) =>
              if !weights_changed {
                true
              } else if table_id >= 0 && row_index >= 0 {
                match weights_table_column_for(table_id) {
                  Some(table_column) =>
                    table_column.set_tick_only_hot_at_row(
                      row_index, weights, write_tick,
                    )
                  None =>
                    column.set_tick_only_hot_at_table_row_value(
                      table_id, row_index, weights, write_tick,
                    )
                }
              } else {
                column.set_tick_only_hot(entity, weights)
              }
            None => false
          }
          if !wrote {
            weights_updates.push((entity, weights))
          }
          if weights_changed {
            counters.morph_weight_writes = counters.morph_weight_writes + 1
          }
        }
        if evaluation_output.text_color is Some(text_color) {
          let text_color_changed = match text_color_column {
            Some(_) =>
              if table_id >= 0 && row_index >= 0 {
                match text_color_table_column_for(table_id) {
                  Some(table_column) =>
                    match table_column.value_at_row_unchecked(row_index) {
                      Some(current_text_color) =>
                        !animation_text_color_eq(current_text_color, text_color)
                      None => true
                    }
                  None => true
                }
              } else {
                true
              }
            None => true
          }
          let wrote = match text_color_column {
            Some(column) =>
              if !text_color_changed {
                true
              } else if table_id >= 0 && row_index >= 0 {
                match text_color_table_column_for(table_id) {
                  Some(table_column) =>
                    table_column.set_tick_only_hot_at_row(
                      row_index, text_color, write_tick,
                    )
                  None =>
                    column.set_tick_only_hot_at_table_row_value(
                      table_id, row_index, text_color, write_tick,
                    )
                }
              } else {
                column.set_tick_only_hot(entity, text_color)
              }
            None => false
          }
          if !wrote {
            text_color_updates.push((entity, text_color))
          }
          if text_color_changed {
            counters.text_color_writes = counters.text_color_writes + 1
          }
        }
        false
      }
      match transform_column {
        Some(transform_column) =>
          target_id_column.for_each3_fast_table_row_mark_third_changed(
            animated_by_column,
            transform_column,
            write_tick,
            fn(entity, table_id, row_index, target_id, animated_by, transform) {
              process_target(
                entity,
                table_id,
                row_index,
                animated_by,
                target_id,
                Some(transform),
              )
            },
          )
        None =>
          animated_by_column.for_each_with_fast_table_row(target_id_column, fn(
            entity,
            table_id,
            row_index,
            animated_by,
            target_id,
          ) {
            ignore(
              process_target(
                entity,
                table_id,
                row_index,
                animated_by,
                target_id,
                None,
              ),
            )
          })
      }
      @app.timeline_trace_end_span(
        System,
        "animation_targets.target_iteration",
        target_iteration_trace_start_us,
      )
    }

    for update in transform_updates {
      try! world.set_by_key(update.0, @transform.ecs_key_transform, update.1)
    }

    for update in weights_updates {
      try! world.set_by_key(update.0, ecs_key_animation_weights, update.1)
    }

    for update in text_color_updates {
      try! world.set_by_key(update.0, @text.ecs_key_text_color, update.1)
    }
    @app.timeline_trace_emit_counter_int(
      "animation.targets.players_prepared",
      counters.players_prepared,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.targets_processed",
      counters.targets_processed,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.sampled_curves",
      counters.sampled_curves,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.transform_writes",
      counters.transform_writes,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.morph_weight_writes",
      counters.morph_weight_writes,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.text_color_writes",
      counters.text_color_writes,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.frame_curve_cache_hits",
      runtime_scratch.frame_curve_cache.hits,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.frame_curve_cache_misses",
      runtime_scratch.frame_curve_cache.misses,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.frame_curve_cache_empty_hits",
      runtime_scratch.frame_curve_cache.empty_hits,
    )
    @app.timeline_trace_emit_counter_int(
      "animation.targets.frame_curve_cache_entries",
      runtime_scratch.frame_curve_cache.len,
    )
  })
}

///|
pub fn trigger_untargeted_animation_events(world : @ecs.World) -> Unit {
  let writer : @core.MessageWriter[AnimationTriggeredEvent] = @core.Message::writer(
    @app.current_system_ticks().this_run,
  )
  let player_query : @ecs.Query[@ecs.Read[AnimationPlayer], @ecs.All] = @ecs.query(
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
    for node_key in 0..<player.active_animations.length() {
      guard player.active_animations[node_key] is Some(active) else { continue }
      if active.is_paused() {
        continue
      }
      let node_index = AnimationNodeIndex::new(node_key)
      guard graph.get(node_index) is Some(node) else { continue }
      guard node.node_type is Clip(clip_handle) else { continue }
      guard animation_clip_get(clip_handle) is Some(clip) else { continue }
      let triggered = animation_clip_collect_triggered_events(
        animation_clip_events_for_root(clip),
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
pub struct AnimationPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn AnimationPlugin::AnimationPlugin() -> AnimationPlugin {
  AnimationPlugin::{  }
}

///|
pub impl @app.Plugin for AnimationPlugin with fn name(_self) {
  ANIMATION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AnimationPlugin with fn build(self, app) {
  animation_plugin_with(app, self)
}

///|
pub fn animation_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  animation_plugin_with(app, AnimationPlugin())
}

///|
pub fn animation_plugin_with(
  app : @app.App[@ecs.World],
  plugin : AnimationPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  @asset.init_asset(@asset.init_asset(app, fn() { AnimationClip::new() }), fn() {
    AnimationGraph::new()
  })
  .init_resource(fn() { ThreadedAnimationGraphs::{ graphs: Map([]) } })
  .add_post_update_system_config(
    @app.system_config_param3(thread_animation_graphs).in_set(
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
    @app.system(expire_completed_transitions).in_set(
      animation_set_expire_transitions,
    ),
  )
  .configure_set(PostUpdate, animation_set_thread, before=[
    animation_set_advance_transitions,
  ])
  .configure_set(PostUpdate, animation_set_advance_transitions, before=[
    animation_set_advance_animations,
  ])
  .configure_set(PostUpdate, animation_set_advance_animations, before=[
    animation_set_animate_targets,
  ])
  .configure_set(PostUpdate, animation_set_animate_targets, before=[
    animation_set_trigger_untargeted_events,
  ])
  .configure_set(PostUpdate, animation_set_trigger_untargeted_events, before=[
    animation_set_expire_transitions,
  ])
  .configure_set(PostUpdate, animation_set_animate_targets, before=[
    @transform.transform_set_propagate,
  ])
}
