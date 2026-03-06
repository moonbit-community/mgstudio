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
pub let ecs_key_global_transform : @ecs.ComponentKey[GlobalTransform] = @ecs.register_component(
  debug_name="transform.global_transform",
)

///|
pub fn update_children_system_ecs(world : @ecs.World) -> Unit {
  let existing_children : Array[@core.Entity] = []
  try! world
  .query1(@hierarchy.ecs_key_children)
  .view(fn(entity, _children) { existing_children.push(entity) })
  for entity in existing_children {
    try! (world.remove(entity, @hierarchy.ecs_key_children) |> ignore)
  }

  let pairs : Array[(@core.Entity, @core.Entity)] = []
  try! world
  .query1(@hierarchy.ecs_key_parent)
  .view(fn(child, parent) { pairs.push((parent.entity(), child)) })

  if pairs.length() == 0 {
    return
  }

  sort_by_parent_id(pairs)
  let mut i = 0
  while i < pairs.length() {
    let parent = pairs[i].0
    let children : Array[@core.Entity] = []
    while i < pairs.length() && pairs[i].0.id == parent.id {
      children.push(pairs[i].1)
      i = i + 1
    }
    try! world.set(
      parent,
      @hierarchy.ecs_key_children,
      @hierarchy.Children::new(children),
    )
  }
}

///|
pub fn propagate_transforms_system_ecs(world : @ecs.World) -> Unit {
  let roots : Array[@core.Entity] = []
  try! world
  .query1(@math.ecs_key_transform)
  .view(fn(entity, _transform) {
    if (try! world.get(entity, @hierarchy.ecs_key_parent)) is None {
      roots.push(entity)
    }
  })

  let stack : Array[(@core.Entity, GlobalTransform)] = []
  for root in roots {
    stack.push((root, GlobalTransform::identity()))
  }

  while stack.length() > 0 {
    let (entity, parent_global) = stack.pop().unwrap()
    guard (try! world.get(entity, @math.ecs_key_transform))
      is Some(local_transform) else {
      continue
    }

    let global = parent_global.mul(
      GlobalTransform::from_transform(local_transform),
    )
    try! world.set(entity, ecs_key_global_transform, global)

    if (try! world.get(entity, @hierarchy.ecs_key_children)) is Some(children) {
      for child in children.entities() {
        stack.push((child, global))
      }
    }
  }
}

///|
pub fn transform_plugin_ecs(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system_config(
    @app.system(update_children_system_ecs).in_set(
      transform_set_update_children,
    ),
  )
  .add_pre_update_system_config(
    @app.system(propagate_transforms_system_ecs).in_set(transform_set_propagate),
  )
  .configure_set(@app.PreUpdate, transform_set_update_children, before=[
    transform_set_propagate,
  ])
  .add_system_config(
    @app.system(propagate_transforms_system_ecs).run_if(fn(
      _world : @ecs.World,
    ) {
      @time.time_fixed_did_run_this_frame()
    }),
  )
}
