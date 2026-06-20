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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::extract_shadow_filtering_method`.
fn insert_extracted_shadow_filtering_method(
  render_world : @ecs.World,
  component_column : @ecs.ComponentColumn[ShadowFilteringMethod]?,
  render_entity : @core.Entity,
  shadow_filtering_method : ShadowFilteringMethod,
) -> Unit {
  match component_column {
    Some(column) =>
      if column.set_tick_only(render_entity, shadow_filtering_method) {
        return
      }
    None => ()
  }
  render_world.set_by_key(
    render_entity, ecs_key_shadow_filtering_method, shadow_filtering_method,
  ) catch {
    _ =>
      abort(
        "extract_shadow_filtering_method: failed to write extracted component to render world",
      )
  }
}

///|
fn extract_shadow_filtering_method(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  ignore(
    render_world
    .components_registrator()
    .register_component_by_key(ecs_key_shadow_filtering_method),
  )
  let values : Array[(@core.Entity, ShadowFilteringMethod)] = []
  let query : @ecs.Query[
    (@ecs.Read[@render.RenderEntity], @ecs.Read[ShadowFilteringMethod]),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! query.view(fn(_entity, data) {
    let (render_entity, shadow_filtering_method) = data
    values.push((render_entity.value().id(), shadow_filtering_method.value()))
  })
  let component_column = render_world.component_column(
    ecs_key_shadow_filtering_method,
  )
  for value in values {
    insert_extracted_shadow_filtering_method(
      render_world,
      component_column,
      value.0,
      value.1,
    )
  }
}
