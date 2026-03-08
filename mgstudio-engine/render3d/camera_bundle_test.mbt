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
test "render3d: Camera3dBundle stores window render target" {
  let world = @ecs.World::new()
  let target_window = @core.Entity::new(11, 3)
  let bundle = Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).with_target(
    @render2d.RenderTarget::Window(@window.WindowRef::Entity(target_window)),
  )
  let entity = bundle.spawn(world)

  let target : @render2d.RenderTarget? = try! world.get(
    entity, @render2d.ecs_key_render_target,
  )
  inspect(
    target.map(fn(value) {
      value.to_json() ==
      @render2d.RenderTarget::Window(@window.WindowRef::Entity(target_window)).to_json()
    }),
    content="Some(true)",
  )
}
