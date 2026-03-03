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
test "animation target id: deterministic and path-sensitive" {
  let a = AnimationTargetId::from_names(["Root", "Arm", "Hand"])
  let b = AnimationTargetId::from_names(["Root", "Arm", "Hand"])
  let c = AnimationTargetId::from_names(["Root", "Hand", "Arm"])
  let d = AnimationTargetId::from_names(["Root", "ArmHand"])

  inspect(a == b, content="true")
  inspect(a == c, content="false")
  inspect(a == d, content="false")
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

  inspect(clip.duration(), content="4")
}

///|
test "animation graph: from_clip/from_clips/add APIs" {
  let h0 = animation_clip_add(AnimationClip::new())
  let h1 = animation_clip_add(AnimationClip::new())

  let (g0, n0) = AnimationGraph::from_clip(h0)
  inspect(g0.get(n0) is Some(_), content="true")

  let (g1, nodes) = AnimationGraph::from_clips([h0, h1])
  inspect(nodes.length(), content="2")

  let blend = g1.add_blend(0.5F, g1.root())
  let add = g1.add_add(0.25F, blend)
  let clip = g1.add_clip(h0, 0.75F, add)
  inspect(g1.get(clip) is Some(_), content="true")
}

///|
test "active animation: repeat semantics" {
  let never = ActiveAnimation::default()
    .set_repeat(RepeatAnimation::Never)
    .update(0.6F, 1.0F)
    .update(0.6F, 1.0F)
  inspect(never.is_finished(), content="true")
  inspect(never.completions(), content="1")

  let count = ActiveAnimation::default()
    .set_repeat(RepeatAnimation::Count(2))
    .update(1.1F, 1.0F)
    .update(1.1F, 1.0F)
  inspect(count.is_finished(), content="true")
  inspect(count.completions(), content="2")

  let forever = ActiveAnimation::default().repeat_forever().update(3.1F, 1.0F)
  inspect(forever.is_finished(), content="false")
  inspect(forever.completions() >= 1, content="true")
}

///|
test "animation transitions: play updates main animation and starts new clip" {
  let node_a = AnimationNodeIndex::new(1)
  let node_b = AnimationNodeIndex::new(2)

  let player0 = AnimationPlayer::default().play(node_a)
  let transitions0 = AnimationTransitions::new()
  let (transitions1, player1) = transitions0.play(player0, node_a, 0.2F)

  inspect(transitions1.main_animation() is Some(_), content="true")
  inspect(player1.animation(node_a) is Some(_), content="true")

  let (transitions2, player2) = transitions1.play(player1, node_b, 0.5F)
  assert_true(
    if transitions2.main_animation() is Some(main_node) {
      main_node == node_b
    } else {
      false
    },
  )
  inspect(player2.animation(node_b) is Some(_), content="true")
}

///|
test "animation graph: blend/add weights and mask groups" {
  let clip = animation_clip_add(AnimationClip::new())
  let graph = AnimationGraph::new()
  let blend = graph.add_blend(0.5F, graph.root())
  let idle = graph.add_clip(clip, 1.0F, graph.root())
  let walk = graph.add_clip(clip, 1.0F, blend)
  let run = graph.add_clip(clip, 1.0F, blend)

  let idle_weight = graph.effective_weight(idle)
  let walk_weight = graph.effective_weight(walk)
  let run_weight = graph.effective_weight(run)
  inspect(idle_weight > 0.66F && idle_weight < 0.67F, content="true")
  inspect(walk_weight > 0.16F && walk_weight < 0.17F, content="true")
  inspect(run_weight > 0.16F && run_weight < 0.17F, content="true")

  let target = AnimationTargetId::from_name("Hips")
  graph.add_target_to_mask_group(target, 3) |> ignore
  inspect(graph.target_mask(target).reinterpret_as_int() > 0, content="true")
  inspect(graph.add_node_mask_group(run, 3), content="true")
  inspect(
    (graph.computed_mask(run) & graph.target_mask(target)) != 0U,
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
  inspect(events1.length(), content="1")
  inspect(events1[0].label(), content="first")

  let active2 = active1.update(0.7F, clip.duration())
  let events2 = clip.triggered_root_events(active2)
  inspect(events2.length(), content="2")
  inspect(events2[0].label(), content="second")
  inspect(events2[1].label(), content="first")
}
