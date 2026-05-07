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
fn clip_event_times(events : Array[AnimationClipEvent]) -> Array[Float] {
  let out : Array[Float] = []
  for event in events {
    out.push(event.time())
  }
  out
}

///|
fn approx_eq_animation(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
fn approx_eq_animation_slice(
  actual : Array[Float],
  expected : Array[Float],
) -> Bool {
  if actual.length() != expected.length() {
    return false
  }
  for i in 0..<actual.length() {
    if !approx_eq_animation(actual[i], expected[i]) {
      return false
    }
  }
  true
}

///|
struct TestTypedAnimationEvent {
  observer_entity : @core.Entity?
  value : String
}

///|
let test_typed_animation_event_key : @ecs.EventKey[TestTypedAnimationEvent] = @ecs.register_event(
  debug_name="tests.animation.typed_event",
)

///|
pub impl AnimationEvent for TestTypedAnimationEvent with animation_event_marker(
  _self,
) {

}

///|
pub impl @ecs.TriggerEvent for TestTypedAnimationEvent with observer_event() {
  test_typed_animation_event_key
}

///|
pub impl @ecs.TriggerEvent for TestTypedAnimationEvent with observer_entity(
  self,
) {
  self.observer_entity
}

///|
pub impl @ecs.TriggerEvent for TestTypedAnimationEvent with set_observer_entity(
  self,
  entity,
) {
  TestTypedAnimationEvent::{ observer_entity: Some(entity), value: self.value }
}

///|
pub impl @ecs.TriggerEvent for TestTypedAnimationEvent with auto_propagate(
  _self,
) {
  false
}

///|
pub impl @ecs.TriggerEvent for TestTypedAnimationEvent with debug_name() {
  "TestTypedAnimationEvent"
}

///|
struct ObservedTypedAnimationEvent {
  entity_id : Int
  value : String
} derive(Eq, Debug)

///|
let observed_typed_animation_events : Ref[
  @core.Messages[ObservedTypedAnimationEvent],
] = Ref(@core.Messages::new())

///|
pub impl @core.Message for ObservedTypedAnimationEvent with reader(sequence) {
  observed_typed_animation_events.val.reader(sequence)
}

///|
pub impl @core.Message for ObservedTypedAnimationEvent with writer(sequence) {
  observed_typed_animation_events.val.writer(sequence)
}

///|
fn observe_typed_animation_event(
  event : @ecs.On[TestTypedAnimationEvent],
  writer : @core.MessageWriter[ObservedTypedAnimationEvent],
) -> Unit {
  let entity_id = match event.entity() {
    Some(entity) => entity.id
    None => -1
  }
  writer.write({ entity_id, value: event.event().value })
}

///|
test "animation target id: deterministic and path-sensitive" {
  let a = AnimationTargetId::from_names(["Root", "Arm", "Hand"])
  let a_iter = AnimationTargetId::from_iter(["Root", "Arm", "Hand"])
  let b = AnimationTargetId::from_names(["Root", "Arm", "Hand"])
  let c = AnimationTargetId::from_names(["Root", "Hand", "Arm"])
  let d = AnimationTargetId::from_names(["Root", "ArmHand"])

  debug_inspect(a == a_iter, content="true")
  debug_inspect(a == b, content="true")
  debug_inspect(a == c, content="false")
  debug_inspect(a == d, content="false")
}

///|
test "animation clip: duration tracks added trs/weights curves" {
  let target = AnimationTargetId::from_name("Hip")
  let clip = AnimationClip::new()
    .add_translation_curve(target, [
      KeyframeVec3::new(0.0F, @math.Vec3::zero()),
      KeyframeVec3::new(2.0F, @math.Vec3::splat(1.0F)),
    ])
    .add_rotation_curve(target, [
      KeyframeQuat::new(3.0F, @math.Quat::identity()),
    ])
    .add_weights_curve(target, [KeyframeWeights::new(4.0F, [0.0F, 1.0F])])

  debug_inspect(clip.duration(), content="4")
}

///|
test "animation clip: text color curves sample and extend duration" {
  let target = AnimationTargetId::from_name("Label")
  let clip = AnimationClip::new().add_text_color_curve(target, [
    KeyframeColor::new(0.0F, @sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
    KeyframeColor::new(2.0F, @sprite.Color::srgb(0.0F, 0.0F, 1.0F)),
  ])

  debug_inspect(clip.duration(), content="2")
  debug_inspect(
    if clip.sample_target(target, 1.0F) is Some(sample) {
      if sample.text_color() is Some(color) {
        color.r > 0.49F &&
        color.r < 0.51F &&
        color.b > 0.49F &&
        color.b < 0.51F &&
        approx_eq_animation(color.g, 0.0F) &&
        approx_eq_animation(color.a, 1.0F)
      } else {
        false
      }
    } else {
      false
    },
    content="true",
  )
}

///|
test "animation clip: step interpolation keeps previous keyframe before boundary" {
  let target = AnimationTargetId::from_name("StepTarget")
  let clip = AnimationClip::new().add_translation_curve(target, [
    KeyframeVec3::new_stepped(0.0F, @math.Vec3::new(1.0F, 0.0F, 0.0F)),
    KeyframeVec3::new_stepped(1.0F, @math.Vec3::new(3.0F, 0.0F, 0.0F)),
  ])
  let sample = clip.sample_target(target, 0.5F).unwrap()
  let translation = sample.translation().unwrap()
  debug_inspect(translation.x.to_double(), content="1")
}

///|
test "animation clip: cubic spline interpolation uses tangents" {
  let target = AnimationTargetId::from_name("CubicTarget")
  let clip = AnimationClip::new().add_scale_curve(target, [
    KeyframeVec3::new_cubic(
      0.0F,
      @math.Vec3::new(1.0F, 1.0F, 1.0F),
      @math.Vec3::zero(),
      @math.Vec3::zero(),
    ),
    KeyframeVec3::new_cubic(
      1.0F,
      @math.Vec3::new(3.0F, 3.0F, 3.0F),
      @math.Vec3::zero(),
      @math.Vec3::zero(),
    ),
  ])
  let sample = clip.sample_target(target, 0.25F).unwrap()
  let scale = sample.scale().unwrap()
  debug_inspect(approx_eq_animation(scale.x, 1.3125F), content="true")
}

///|
test "animation gltf curves: decode translation cubic spline keyframes" {
  let target = AnimationTargetId::from_name("GltfTranslation")
  let keyframes = gltf_translation_keyframes_from_samples(
    [0.0F, 1.0F],
    [
      @math.Vec3::zero(),
      @math.Vec3::new(1.0F, 1.0F, 1.0F),
      @math.Vec3::zero(),
      @math.Vec3::zero(),
      @math.Vec3::new(3.0F, 3.0F, 3.0F),
      @math.Vec3::zero(),
    ],
    gltf_interpolation_from_name(Some("CUBICSPLINE")),
  ).unwrap()
  let clip = AnimationClip::new().add_translation_curve(target, keyframes)
  let translation = clip
    .sample_target(target, 0.25F)
    .unwrap()
    .translation()
    .unwrap()
  debug_inspect(approx_eq_animation(translation.x, 1.3125F), content="true")
}

///|
test "animation gltf curves: decode rotation step keyframes" {
  let target = AnimationTargetId::from_name("GltfRotation")
  let keyframes = gltf_rotation_keyframes_from_samples(
    [0.0F, 1.0F],
    [
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
      @math.Vec4::new(0.0F, 0.70710677F, 0.0F, 0.70710677F),
    ],
    gltf_interpolation_from_name(Some("STEP")),
  ).unwrap()
  let clip = AnimationClip::new().add_rotation_curve(target, keyframes)
  let rotation_mid = clip
    .sample_target(target, 0.5F)
    .unwrap()
    .rotation()
    .unwrap()
  let rotation_end = clip
    .sample_target(target, 1.0F)
    .unwrap()
    .rotation()
    .unwrap()
  debug_inspect(
    rotation_mid.w >= 0.99F && rotation_mid.w <= 1.01F,
    content="true",
  )
  debug_inspect(
    rotation_end.w >= 0.70F && rotation_end.w <= 0.71F,
    content="true",
  )
}

///|
test "animation gltf curves: decode weights cubic spline keyframes" {
  let target = AnimationTargetId::from_name("GltfWeights")
  let keyframes = gltf_weight_keyframes_from_flat_samples(
    [0.0F, 1.0F],
    [0.0F, 0.0F, 0.1F, 0.9F, 0.0F, 0.0F, 0.0F, 0.0F, 0.2F, 0.8F, 0.0F, 0.0F],
    gltf_interpolation_from_name(Some("CUBICSPLINE")),
  ).unwrap()
  let clip = AnimationClip::new().add_weights_curve(target, keyframes)
  let weights = clip.sample_target(target, 1.0F).unwrap().weights().unwrap()
  debug_inspect(weights.length(), content="2")
  debug_inspect(weights[0] >= 0.19F && weights[0] <= 0.21F, content="true")
  debug_inspect(weights[1] >= 0.79F && weights[1] <= 0.81F, content="true")
}

///|
test "animation graph: from_clip/from_clips/add APIs" {
  let clips : @asset.Assets[AnimationClip] = @asset.Assets::new()
  let h0 = clips.add(AnimationClip::new())
  let h1 = clips.add(AnimationClip::new())
  let h2 = clips.add(AnimationClip::new())

  let (g0, n0) = AnimationGraph::from_clip(h0)
  debug_inspect(g0.get(n0) is Some(_), content="true")

  let (g1, nodes) = AnimationGraph::from_clips([h0, h1])
  debug_inspect(nodes.length(), content="2")
  debug_inspect(g1.nodes().length(), content="3")

  let blend = g1.add_blend(0.5F, g1.root())
  let add = g1.add_add(0.25F, blend)
  let clip = g1.add_clip(h0, 0.75F, add)
  let extra = g1.add_clips([h1, h2], 0.5F, blend)
  debug_inspect(g1.get(clip) is Some(_), content="true")
  debug_inspect(extra.length(), content="2")
  debug_inspect(g1.nodes().length(), content="8")

  if g1.get_mut(blend) is Some(blend_node) {
    blend_node.set_weight(0.25F).add_mask(4U) |> ignore
  }
  debug_inspect(
    if g1.get(blend) is Some(blend_node) {
      approx_eq_animation(blend_node.weight(), 0.25F) && blend_node.mask() == 4U
    } else {
      false
    },
    content="true",
  )
}

///|
test "active animation: repeat semantics" {
  let never = ActiveAnimation::default()
    .set_repeat(RepeatAnimation::Never)
    .update(0.6F, 1.0F)
    .update(0.6F, 1.0F)
  debug_inspect(never.is_finished(), content="true")
  debug_inspect(never.completions(), content="1")

  let count = ActiveAnimation::default()
    .set_repeat(RepeatAnimation::Count(2))
    .update(1.1F, 1.0F)
    .update(1.1F, 1.0F)
  debug_inspect(count.is_finished(), content="true")
  debug_inspect(count.completions(), content="2")

  let forever = ActiveAnimation::default().repeat_forever().update(3.1F, 1.0F)
  debug_inspect(forever.is_finished(), content="false")
  debug_inspect(forever.completions() >= 1, content="true")
}

///|
test "active animation: replay and weight semantics match bevy" {
  let weighted = ActiveAnimation::default().set_weight(-0.5F)
  assert_true(approx_eq_animation(weighted.weight(), -0.5F))

  let replayed = ActiveAnimation::default()
    .pause()
    .seek_to(0.7F)
    .set_repeat(RepeatAnimation::Count(3))
    .replay()
  debug_inspect(replayed.is_paused(), content="true")
  assert_true(approx_eq_animation(replayed.seek_time(), 0.0F))
  debug_inspect(replayed.completions(), content="0")
}

///|
test "active animation: zero-speed at clip end does not complete" {
  let stationary = ActiveAnimation::default()
    .set_speed(0.0F)
    .seek_to(1.0F)
    .set_repeat(RepeatAnimation::Never)
    .update(0.25F, 1.0F)
  debug_inspect(stationary.just_completed(), content="false")
  debug_inspect(stationary.completions(), content="0")
  debug_inspect(stationary.is_finished(), content="false")
}

///|
test "active animation: zero-duration clip completes for non-repeating playback" {
  let completed = ActiveAnimation::default()
    .set_repeat(RepeatAnimation::Never)
    .update(0.1F, 0.0F)
  debug_inspect(completed.just_completed(), content="true")
  debug_inspect(completed.completions(), content="1")
  debug_inspect(completed.is_finished(), content="true")
}

///|
test "animation transitions: play updates main animation and starts new clip" {
  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)

  let player = AnimationPlayer::default()
  let transitions = AnimationTransitions::new()
  transitions.play(player, node_a, 0.2F).repeat() |> ignore

  debug_inspect(transitions.main_animation() is Some(_), content="true")
  debug_inspect(transitions.get_main_animation() is Some(_), content="true")
  debug_inspect(player.animation(node_a) is Some(_), content="true")

  transitions.play(player, node_b, 0.5F).repeat() |> ignore
  assert_true(
    if transitions.main_animation() is Some(main_node) {
      main_node == node_b
    } else {
      false
    },
  )
  debug_inspect(player.animation(node_b) is Some(_), content="true")
  debug_inspect(transitions.transitions.length(), content="1")
}

///|
test "animation transitions: zero-duration switch expires via transition systems" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  fn set_delta(delta_seconds : Float) -> Unit {
    let time = @time.Time::new_with(()).advance_by(
      @core.Duration::from_secs_f32(delta_seconds),
    )
    world.insert_resource(@time.default_time_resource_key(), time)
  }

  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)
  let player = AnimationPlayer::default()
  let transitions = AnimationTransitions::new()
  transitions.play(player, node_a, 0.2F).repeat() |> ignore
  transitions.play(player, node_b, 0.0F).repeat() |> ignore

  debug_inspect(player.animation(node_a) is Some(_), content="true")
  debug_inspect(transitions.transitions.length(), content="1")

  let entity = world.spawn_empty()
  try! world.set_by_key(entity, ecs_key_animation_player, player)
  try! world.set_by_key(entity, ecs_key_animation_transitions, transitions)

  set_delta(0.016F)
  advance_transitions(world)
  expire_completed_transitions(world)
  let after_player = (try! world.get_by_key(entity, ecs_key_animation_player)).unwrap_or(
    AnimationPlayer::default(),
  )
  let after_transitions = (try! world.get_by_key(
    entity, ecs_key_animation_transitions,
  )).unwrap_or(AnimationTransitions::new())
  debug_inspect(after_transitions.transitions.length(), content="0")
  debug_inspect(after_player.animation(node_a) is None, content="true")
  debug_inspect(after_player.animation(node_b) is Some(_), content="true")
}

///|
test "animation transitions: remaining weight is not clamped like bevy" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  fn set_delta(delta_seconds : Float) -> Unit {
    let time = @time.Time::new_with(()).advance_by(
      @core.Duration::from_secs_f32(delta_seconds),
    )
    world.insert_resource(@time.default_time_resource_key(), time)
  }

  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)
  let player = AnimationPlayer::default()
  let transitions = AnimationTransitions::new()
  transitions.play(player, node_a, 0.2F).repeat() |> ignore
  player.set_weight(node_a, 2.0F) |> ignore
  transitions.play(player, node_b, 1.0F).repeat() |> ignore

  let entity = world.spawn_empty()
  try! world.set_by_key(entity, ecs_key_animation_player, player)
  try! world.set_by_key(entity, ecs_key_animation_transitions, transitions)

  set_delta(0.0F)
  advance_transitions(world)
  let after_player = (try! world.get_by_key(entity, ecs_key_animation_player)).unwrap_or(
    AnimationPlayer::default(),
  )
  debug_inspect(
    if after_player.animation(node_a) is Some(active_a) {
      approx_eq_animation(active_a.weight(), 2.0F)
    } else {
      false
    },
    content="true",
  )
  debug_inspect(
    if after_player.animation(node_b) is Some(active_b) {
      approx_eq_animation(active_b.weight(), -1.0F)
    } else {
      false
    },
    content="true",
  )
}

///|
test "animation transitions: advance/expire keep frame-snapshot weight decline semantics" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  fn set_delta(delta_seconds : Float) -> Unit {
    let time = @time.Time::new_with(()).advance_by(
      @core.Duration::from_secs_f32(delta_seconds),
    )
    world.insert_resource(@time.default_time_resource_key(), time)
  }

  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)
  let player = AnimationPlayer::default()
  let transitions = AnimationTransitions::new()
  transitions.play(player, node_a, 0.2F).repeat() |> ignore
  transitions.play(player, node_b, 0.5F).repeat() |> ignore

  let entity = world.spawn_empty()
  try! world.set_by_key(entity, ecs_key_animation_player, player)
  try! world.set_by_key(entity, ecs_key_animation_transitions, transitions)

  set_delta(0.25F)
  advance_transitions(world)
  let after_first_player = (try! world.get_by_key(
    entity, ecs_key_animation_player,
  )).unwrap_or(AnimationPlayer::default())
  debug_inspect(
    if after_first_player.animation(node_a) is Some(active_a) {
      approx_eq_animation(active_a.weight(), 0.5F)
    } else {
      false
    },
    content="true",
  )
  debug_inspect(
    if after_first_player.animation(node_b) is Some(active_b) {
      approx_eq_animation(active_b.weight(), 0.5F)
    } else {
      false
    },
    content="true",
  )

  set_delta(0.3F)
  advance_transitions(world)
  expire_completed_transitions(world)
  let after_second_transitions = (try! world.get_by_key(
    entity, ecs_key_animation_transitions,
  )).unwrap_or(AnimationTransitions::new())
  let after_second_player = (try! world.get_by_key(
    entity, ecs_key_animation_player,
  )).unwrap_or(AnimationPlayer::default())
  debug_inspect(after_second_transitions.transitions.length(), content="0")
  debug_inspect(after_second_player.animation(node_a) is None, content="true")
  debug_inspect(
    if after_second_player.animation(node_b) is Some(active_b) {
      approx_eq_animation(active_b.weight(), 1.0F)
    } else {
      false
    },
    content="true",
  )
}

///|
test "animation player: live active handles and bulk helpers mutate in place" {
  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)
  let player = AnimationPlayer::default()

  player.play(node_a).set_speed(1.5F).repeat().pause() |> ignore
  player.play(node_b).seek_to(0.25F) |> ignore

  debug_inspect(player.animation_mut(node_a) is Some(_), content="true")
  debug_inspect(player.playing_animations_mut().length(), content="2")
  debug_inspect(player.all_paused(), content="false")

  player.pause_all() |> ignore
  debug_inspect(player.all_paused(), content="true")

  player.resume_all().adjust_speeds(2.0F).seek_all_by(0.25F) |> ignore
  debug_inspect(player.all_paused(), content="false")
  debug_inspect(
    if player.animation(node_a) is Some(active_a) {
      approx_eq_animation(active_a.speed(), 3.0F) &&
      approx_eq_animation(active_a.seek_time(), 0.25F)
    } else {
      false
    },
    content="true",
  )
  debug_inspect(
    if player.animation(node_b) is Some(active_b) {
      approx_eq_animation(active_b.seek_time(), 0.5F)
    } else {
      false
    },
    content="true",
  )

  player.rewind_all() |> ignore
  debug_inspect(
    if player.animation(node_b) is Some(active_b) {
      approx_eq_animation(active_b.seek_time(), 0.0F)
    } else {
      false
    },
    content="true",
  )
}

///|
test "animation graph: blend/add weights and mask groups" {
  let clips : @asset.Assets[AnimationClip] = @asset.Assets::new()
  let clip = clips.add(AnimationClip::new())
  let graph = AnimationGraph::new()
  let blend = graph.add_blend(0.5F, graph.root())
  let idle = graph.add_clip(clip, 1.0F, graph.root())
  let walk = graph.add_clip(clip, 1.0F, blend)
  let run = graph.add_clip(clip, 1.0F, blend)

  let idle_weight = graph.effective_weight(idle)
  let walk_weight = graph.effective_weight(walk)
  let run_weight = graph.effective_weight(run)
  debug_inspect(idle_weight > 0.66F && idle_weight < 0.67F, content="true")
  debug_inspect(walk_weight > 0.16F && walk_weight < 0.17F, content="true")
  debug_inspect(run_weight > 0.16F && run_weight < 0.17F, content="true")

  let target = AnimationTargetId::from_name("Hips")
  graph.add_target_to_mask_group(target, 3) |> ignore
  debug_inspect(
    graph.target_mask(target).reinterpret_as_int() > 0,
    content="true",
  )
  debug_inspect(graph.add_node_mask_group(run, 3), content="true")
  debug_inspect(
    (graph.computed_mask(run) & graph.target_mask(target)) != 0U,
    content="true",
  )
}

///|
test "animation graph: Bevy-shaped edge add/remove updates DAG parents" {
  let clips : @asset.Assets[AnimationClip] = @asset.Assets::new()
  let clip = clips.add(AnimationClip::new())
  let graph = AnimationGraph::new()
  let blend = graph.add_blend(1.0F, graph.root())
  let leaf = graph.add_clip(clip, 1.0F, blend)
  let target = AnimationTargetId::from_name("Shared")
  graph.add_target_to_mask_group(target, 1) |> ignore
  debug_inspect(graph.add_node_mask_group(blend, 1), content="true")
  debug_inspect(
    (graph.computed_mask(leaf) & graph.target_mask(target)) != 0U,
    content="true",
  )

  graph.add_edge(graph.root(), leaf)
  debug_inspect(
    (graph.computed_mask(leaf) & graph.target_mask(target)) != 0U,
    content="true",
  )
  debug_inspect(graph.remove_edge(blend, leaf), content="true")
  debug_inspect(graph.remove_edge(blend, leaf), content="false")
  debug_inspect(
    (graph.computed_mask(leaf) & graph.target_mask(target)) == 0U,
    content="true",
  )
}

///|
test "animation clip events: forward and looping intervals" {
  let clip = AnimationClip::new()
    .set_duration(1.0F)
    .add_event(0.1F, "first", "")
    .add_event(0.6F, "second", "")

  let active0 = ActiveAnimation::default().repeat_forever()
  let active1 = active0.update(0.5F, clip.duration())
  let events1 = clip.triggered_root_events(active1)
  debug_inspect(events1.length(), content="1")
  debug_inspect(events1[0].label(), content="\"first\"")

  let active2 = active1.update(0.7F, clip.duration())
  let events2 = clip.triggered_root_events(active2)
  debug_inspect(events2.length(), content="2")
  debug_inspect(events2[0].label(), content="\"second\"")
  debug_inspect(events2[1].label(), content="\"first\"")
}

///|
test "animation clip events: match bevy forward reverse and looping edge cases" {
  let clip = AnimationClip::new()
    .add_event(0.5F, "half-a", "")
    .add_event(0.5F, "half-b", "")
    .add_event(0.5F, "half-c", "")
  clip.set_duration(1.0F) |> ignore

  let active0 = ActiveAnimation::default().repeat_forever()
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active0)),
    content="[]",
  )

  let active1 = active0.update(0.8F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active1)),
    content="[0.5, 0.5, 0.5]",
  )

  clip
  .add_event(1.0F, "end-a", "")
  .add_event(0.0F, "start-a", "")
  .add_event(1.0F, "end-b", "")
  .add_event(0.0F, "start-b", "")
  |> ignore

  let active2 = active1.update(0.4F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active2)),
    content="[1, 1, 0, 0]",
  )
}

///|
test "animation clip events: bevy reverse and looping traversal cases" {
  let clip = AnimationClip::new()
    .add_event(0.2F, "middle", "")
    .add_event(0.0F, "start", "")
  debug_inspect(approx_eq_animation(clip.duration(), 0.2F), content="true")

  let active0 = ActiveAnimation::default()
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active0)),
    content="[]",
  )

  let active1 = active0.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active1)),
    content="[0]",
  )

  let active2 = active1.update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(active2)),
      [0.2F],
    ),
    content="true",
  )

  let active3 = active2.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active3)),
    content="[]",
  )

  let reverse0 = ActiveAnimation::default()
    .set_speed(-1.0F)
    .set_seek_time(clip.duration())
  let reverse1 = reverse0.update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(reverse1)),
      [0.2F],
    ),
    content="true",
  )

  let reverse2 = reverse1.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(reverse2)),
    content="[]",
  )

  let reverse3 = reverse2.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(reverse3)),
    content="[0]",
  )

  let reverse4 = reverse3.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(reverse4)),
    content="[]",
  )
}

///|
test "animation clip events: bevy looping forward and reverse traversal cases" {
  let clip = AnimationClip::new()
    .add_event(0.3F, "end", "")
    .add_event(0.0F, "start", "")
    .add_event(0.2F, "middle", "")
  debug_inspect(approx_eq_animation(clip.duration(), 0.3F), content="true")

  let active0 = ActiveAnimation::default().repeat_forever()
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active0)),
    content="[]",
  )

  let active1 = active0.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active1)),
    content="[0]",
  )

  let active2 = active1.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active2)),
    content="[]",
  )

  let active3 = active2.update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(active3)),
      [0.2F, 0.3F],
    ),
    content="true",
  )

  let active4 = active3.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active4)),
    content="[0]",
  )

  let active5 = active4.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(active5)),
    content="[]",
  )

  let reverse1 = active5.set_speed(-1.0F).update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(reverse1)),
      [0.2F],
    ),
    content="true",
  )

  let reverse2 = reverse1.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(reverse2)),
    content="[]",
  )

  let reverse3 = reverse2.update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(reverse3)),
      [0.0F, 0.3F],
    ),
    content="true",
  )

  let reverse4 = reverse3.update(0.1F, clip.duration())
  debug_inspect(
    approx_eq_animation_slice(
      clip_event_times(clip.triggered_root_events(reverse4)),
      [0.2F],
    ),
    content="true",
  )

  let reverse5 = reverse4.update(0.1F, clip.duration())
  debug_inspect(
    clip_event_times(clip.triggered_root_events(reverse5)),
    content="[]",
  )
}

///|
test "animation runtime: animate_targets applies sampled transform and weights" {
  let default_time : @time.Time[Unit] = @time.Time::default()
  let mut app = @app.App::new(@ecs.World::new())
    .insert_resource(default_time)
    .add_plugins(AnimationPlugin::default())
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("Hip")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new()
    .add_translation_curve(target_id, [
      KeyframeVec3::new(0.0F, @math.Vec3::zero()),
      KeyframeVec3::new(1.0F, @math.Vec3::new(2.0F, 0.0F, 0.0F)),
    ])
    .add_weights_curve(target_id, [
      KeyframeWeights::new(0.0F, [0.0F, 1.0F]),
      KeyframeWeights::new(1.0F, [1.0F, 0.0F]),
    ])
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).seek_to(0.5F) |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )
  try! world.set_by_key(
    target_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )

  app = app.run_once()

  let transform = (try! app
  .world()
  .get_by_key(target_entity, @transform.ecs_key_transform)).unwrap()
  debug_inspect(
    approx_eq_animation(transform.translation.x, 1.0F),
    content="true",
  )

  let weights = (try! app
  .world()
  .get_by_key(target_entity, ecs_key_animation_weights)).unwrap()
  debug_inspect(weights.values(), content="[0.5, 0.5]")
}

///|
test "animation runtime: evaluator stack overwrites animated fields like Bevy" {
  let default_time : @time.Time[Unit] = @time.Time::default()
  let mut app = @app.App::new(@ecs.World::new())
    .insert_resource(default_time)
    .add_plugins(AnimationPlugin::default())
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("Hip")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new().add_translation_curve(target_id, [
    KeyframeVec3::new(0.0F, @math.Vec3::new(2.0F, 0.0F, 0.0F)),
  ])
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).set_weight(0.25F) |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )
  try! world.set_by_key(
    target_entity,
    @transform.ecs_key_transform,
    @transform.Transform::new(
      @math.Vec3::new(10.0F, 0.0F, 0.0F),
      @math.Quat::identity(),
      @math.Vec3::splat(1.0F),
    ),
  )

  app = app.run_once()

  let transform = (try! app
  .world()
  .get_by_key(target_entity, @transform.ecs_key_transform)).unwrap()
  debug_inspect(
    approx_eq_animation(transform.translation.x, 2.0F),
    content="true",
  )
}

///|
test "animation runtime: trigger_events emits root and target messages" {
  let captured : Array[AnimationTriggeredEvent] = []
  let delta_time : @time.Time[Unit] = @time.Time::default().advance_by(
    @core.Duration::from_millis(250L),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(AnimationPlugin::default())
    .insert_resource(delta_time)
    .add_post_update_system_config(
      @app.system(
        @app.system_param(fn(
          reader : @core.MessageReader[AnimationTriggeredEvent],
        ) {
          for message in reader.read() {
            captured.push(message)
          }
        }),
      ).after(animation_set_trigger_untargeted_events),
    )
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("Foot")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new()
    .set_duration(1.0F)
    .add_event(0.1F, "root", "player")
    .add_event_to_target(target_id, 0.2F, "target", "bone")
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).repeat() |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )

  app = app.run_once()

  debug_inspect(captured.length(), content="2")
  debug_inspect(captured[0].label(), content="\"target\"")
  debug_inspect(captured[0].payload(), content="\"bone\"")
  debug_inspect(captured[0].target().id == target_entity.id, content="true")
  debug_inspect(
    if captured[0].target_id() is Some(id) {
      id == target_id
    } else {
      false
    },
    content="true",
  )
  debug_inspect(captured[1].label(), content="\"root\"")
  debug_inspect(captured[1].payload(), content="\"player\"")
  debug_inspect(captured[1].player().id == player_entity.id, content="true")
  debug_inspect(captured[1].target().id == player_entity.id, content="true")
  debug_inspect(captured[1].target_id() is None, content="true")
}

///|
test "animation runtime: targeted events are emitted in animate_targets stage" {
  let animate_targets_stage_labels : Array[String] = []
  let untargeted_stage_labels : Array[String] = []
  let delta_time : @time.Time[Unit] = @time.Time::default().advance_by(
    @core.Duration::from_millis(250L),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(AnimationPlugin::default())
    .insert_resource(delta_time)
    .add_post_update_system_config(
      @app.system(
        @app.system_param(fn(
          reader : @core.MessageReader[AnimationTriggeredEvent],
        ) {
          for message in reader.read() {
            animate_targets_stage_labels.push(message.label())
          }
        }),
      )
      .after(animation_set_animate_targets)
      .before(animation_set_trigger_untargeted_events),
    )
    .add_post_update_system_config(
      @app.system(
        @app.system_param(fn(
          reader : @core.MessageReader[AnimationTriggeredEvent],
        ) {
          for message in reader.read() {
            untargeted_stage_labels.push(message.label())
          }
        }),
      ).after(animation_set_trigger_untargeted_events),
    )
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("Foot")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new()
    .set_duration(1.0F)
    .add_event(0.1F, "root", "player")
    .add_event_to_target(target_id, 0.2F, "target", "bone")
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).repeat() |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )

  app = app.run_once()

  debug_inspect(animate_targets_stage_labels.contains("target"), content="true")
  debug_inspect(untargeted_stage_labels.contains("root"), content="true")
}

///|
test "animation runtime: trigger_events dispatches typed root and target observers" {
  let delta_time : @time.Time[Unit] = @time.Time::default().advance_by(
    @core.Duration::from_millis(250L),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(AnimationPlugin::default())
    .add_observer2(observe_typed_animation_event)
    .insert_resource(delta_time)
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("Foot")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new()
    .set_duration(1.0F)
    .add_typed_event(0.1F, TestTypedAnimationEvent::{
      observer_entity: None,
      value: "root",
    })
    .add_typed_event_to_target(target_id, 0.2F, TestTypedAnimationEvent::{
      observer_entity: None,
      value: "target",
    })
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).repeat() |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )

  app = app.run_once()

  let reader = observed_typed_animation_events.val.reader(
    @core.SystemSequence::new(0, world.read_sequence()),
  )
  let captured = reader.read()
  debug_inspect(captured.length(), content="2")
  debug_inspect(captured[0].entity_id, content="1")
  debug_inspect(captured[0].value, content="\"target\"")
  debug_inspect(captured[1].entity_id, content="0")
  debug_inspect(captured[1].value, content="\"root\"")
}

///|
test "animation runtime: animate_targets updates text color" {
  let delta_time : @time.Time[Unit] = @time.Time::default().advance_by(
    @core.Duration::from_millis(500L),
  )
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(AnimationPlugin::default())
    .insert_resource(delta_time)
  let world = app.world()
  let player_entity = world.spawn()
  let target_entity = world.spawn()
  let target_id = AnimationTargetId::from_name("AnimatedText")
  let clip_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationClip]] = @asset.assets_resource_key()
  let graph_assets_key : @ecs.ResourceKey[@asset.Assets[AnimationGraph]] = @asset.assets_resource_key()
  let clip_assets = (try! world.get_resource(clip_assets_key)).unwrap()
  let graph_assets = (try! world.get_resource(graph_assets_key)).unwrap()

  let clip = AnimationClip::new()
    .add_scale_curve(target_id, [
      KeyframeVec3::new(0.0F, @math.Vec3::splat(1.0F)),
      KeyframeVec3::new(1.0F, @math.Vec3::splat(3.0F)),
    ])
    .add_text_color_curve(target_id, [
      KeyframeColor::new(0.0F, @sprite.Color::srgb(1.0F, 0.0F, 0.0F)),
      KeyframeColor::new(1.0F, @sprite.Color::srgb(0.0F, 1.0F, 0.0F)),
    ])
  let clip_handle = clip_assets.add(clip)
  let (graph, node) = AnimationGraph::from_clip(clip_handle)
  let graph_handle = graph_assets.add(graph)
  let player = AnimationPlayer::default()
  player.play(node).repeat() |> ignore

  try! world.set_by_key(player_entity, ecs_key_animation_player, player)
  try! world.set_by_key(
    player_entity,
    ecs_key_animation_graph_handle,
    AnimationGraphHandle::new(graph_handle),
  )
  try! world.set_by_key(target_entity, ecs_key_animation_target_id, target_id)
  try! world.set_by_key(
    target_entity,
    ecs_key_animated_by,
    AnimatedBy::new(player_entity),
  )
  try! world.set_by_key(
    target_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  try! world.set_by_key(
    target_entity,
    @text.ecs_key_text_color,
    @text.TextColor::white(),
  )

  app = app.run_once()

  let transform = (try! app
  .world()
  .get_by_key(target_entity, @transform.ecs_key_transform)).unwrap()
  let color = (try! app
  .world()
  .get_by_key(target_entity, @text.ecs_key_text_color)).unwrap()

  debug_inspect(
    transform.scale.x > 1.9F && transform.scale.x < 2.1F,
    content="true",
  )
  debug_inspect(color.color.r > 0.49F && color.color.r < 0.51F, content="true")
  debug_inspect(color.color.g > 0.49F && color.color.g < 0.51F, content="true")
  debug_inspect(approx_eq_animation(color.color.b, 0.0F), content="true")
}
