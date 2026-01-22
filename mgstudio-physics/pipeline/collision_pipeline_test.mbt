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
/// Ported from rapier/src/pipeline/collision_pipeline.rs (dim2 test_no_rigid_bodies).
test "collision pipeline no rigid bodies" {
  let rigid_body_set = @dynamics.RigidBodySet::new()
  let collider_set = @collision.ColliderSet::new()
  let collider_a = @collision.ColliderBuilder::cuboid(1.0F, 1.0F)
    .active_collision_types(@collision.ActiveCollisionTypes::all())
    .sensor(true)
    .active_events(@collision.ActiveEvents::CollisionEvents)
    .build()
  let a_handle = collider_set.insert(collider_a)
  let collider_b = @collision.ColliderBuilder::cuboid(1.0F, 1.0F)
    .active_collision_types(@collision.ActiveCollisionTypes::all())
    .sensor(true)
    .active_events(@collision.ActiveEvents::CollisionEvents)
    .build()
  collider_set.insert(collider_b) |> ignore
  let integration_parameters = IntegrationParameters::default()
  let islands = @dynamics.IslandManager::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let collision_pipeline = CollisionPipeline::new()
  collision_pipeline.step(
    integration_parameters.prediction_distance(),
    islands,
    broad_phase,
    narrow_phase,
    rigid_body_set,
    collider_set,
    (),
    (),
  )
  let mut hit = false
  for pair in narrow_phase.intersection_pairs_with(a_handle) {
    if pair.intersecting {
      hit = true
    }
  }
  inspect(hit, content="true")
}

///|
/// Ported from rapier/src/pipeline/collision_pipeline.rs (dim3 test_no_rigid_bodies) adapted for 2D.
test "collision pipeline no rigid bodies (dim3 adapted)" {
  let rigid_body_set = @dynamics.RigidBodySet::new()
  let collider_set = @collision.ColliderSet::new()
  let collider_a = @collision.ColliderBuilder::cuboid(1.0F, 1.0F)
    .active_collision_types(@collision.ActiveCollisionTypes::all())
    .sensor(true)
    .active_events(@collision.ActiveEvents::CollisionEvents)
    .build()
  let a_handle = collider_set.insert(collider_a)
  let collider_b = @collision.ColliderBuilder::cuboid(1.0F, 1.0F)
    .active_collision_types(@collision.ActiveCollisionTypes::all())
    .sensor(true)
    .active_events(@collision.ActiveEvents::CollisionEvents)
    .build()
  collider_set.insert(collider_b) |> ignore
  let integration_parameters = IntegrationParameters::default()
  let islands = @dynamics.IslandManager::new()
  let broad_phase = @collision.BroadPhaseBvh::new()
  let narrow_phase = @collision.NarrowPhase::new()
  let collision_pipeline = CollisionPipeline::new()
  collision_pipeline.step(
    integration_parameters.prediction_distance(),
    islands,
    broad_phase,
    narrow_phase,
    rigid_body_set,
    collider_set,
    (),
    (),
  )
  let mut hit = false
  for pair in narrow_phase.intersection_pairs_with(a_handle) {
    if pair.intersecting {
      hit = true
    }
  }
  inspect(hit, content="true")
}
