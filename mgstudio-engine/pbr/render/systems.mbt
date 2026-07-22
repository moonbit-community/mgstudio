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

// Bevy-aligned `pbr/render/systems` container.

///|
pub let render3d_extract_system_label : String = "mgstudio.render3d.extract"

///|
pub let render3d_prepare_system_label : String = "mgstudio.render3d.prepare"

///|
pub let render3d_queue_system_label : String = "mgstudio.render3d.queue"

///|
pub let render3d_execute_system_label : String = "mgstudio.render3d.execute"

///|
pub fn render3d_system_labels() -> Array[String] {
  [
    render3d_extract_system_label, render3d_prepare_system_label, render3d_queue_system_label,
    render3d_execute_system_label,
  ]
}

///|
pub fn[T : @ecs.Component] render3d_update_frusta_system_by_projection_key(
  world : @ecs.World,
  projection_key : @ecs.ComponentKey[T],
  compute_frustum : (T, @transform.Transform) -> Frustum,
) -> Unit {
  let query : @ecs.Query[
    (
      @ecs.ReadValue[@transform.Transform],
      @ecs.ReadValue[T],
      @ecs.Write[Frustum],
    ),
    @ecs.Or[(@ecs.Changed[@transform.Transform], @ecs.Changed[T])],
  ] = @ecs.query_filtered(
    world,
    @ecs.Or::new(
      (
        @ecs.Changed::new(@transform.ecs_key_transform),
        @ecs.Changed::new(projection_key),
      ),
    ),
  )
  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let transforms = batch.read(@transform.ecs_key_transform).unwrap()
    let projections = batch.read(projection_key).unwrap()
    let frusta = batch.write(ecs_key_frustum).unwrap()
    try! rows.for_each(fn(row_index) {
      let next = compute_frustum(
        projections.value(row_index), transforms.value(row_index),
      )
      if frusta.peek(row_index) != next {
        frusta.set(row_index, next)
      }
    })
  })
  if !used_batch {
    try! query.for_each(fn(_entity, data) {
      let (transform, projection, frustum) = data
      let next = compute_frustum(projection.value(), transform.value())
      if frustum.peek() != next {
        frustum.set(next)
      }
    })
  }
}
