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
struct PickableSpriteColors {
  normal : @sprite.Color
  hover : @sprite.Color
  pressed : @sprite.Color
}

///|
let ecs_key_pickable_sprite_colors : @ecs.ComponentKey[PickableSpriteColors] = @ecs.register_component(
  debug_name="examples.picking.sprite.pickable_sprite_colors",
)

///|
impl @ecs.Component for PickableSpriteColors with component() {
  ecs_key_pickable_sprite_colors
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      @sprite.Camera2dBundle::new(
        @sprite.Camera::default(),
        @transform.Transform::identity(),
      ),
    ),
  )

  let colors = PickableSpriteColors::{
    normal: @sprite.Color::srgb(1.0F, 0.2F, 0.2F),
    hover: @sprite.Color::srgb(0.2F, 1.0F, 0.2F),
    pressed: @sprite.Color::srgb(0.2F, 0.2F, 1.0F),
  }
  let spacing = 140.0F
  for row in 0..<3 {
    for col in 0..<3 {
      let x = Float::from_double((col - 1).to_double()) * spacing
      let y = Float::from_double((row - 1).to_double()) * spacing
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::sized(@math.Vec2::new(72.0F, 72.0F)).with_color(
              colors.normal,
            ),
            @transform.Transform::from_xyz(x, y, 0.0F),
            PickableSpriteColors::{ ..colors },
          ),
        ),
      )
    }
  }
}

///|
fn apply_target_sprite_color(
  target : @core.Entity?,
  color_selector : (PickableSpriteColors) -> @sprite.Color,
  query : @ecs.Query[
    (@ecs.Mut[@sprite.Sprite], @ecs.Comp[PickableSpriteColors]),
    @ecs.All,
  ],
) -> Unit {
  guard target is Some(entity) else { return }
  guard (try! query.get(entity)) is Some((sprite, colors)) else { return }
  let current = sprite.get_ref().val
  sprite.get_ref().val = current.with_color(color_selector(colors.value()))
}

///|
fn pointer_enter_sprite(
  pointer : @app.OnPointer[@app.PointerEnter],
  query : @ecs.Query[
    (@ecs.Mut[@sprite.Sprite], @ecs.Comp[PickableSpriteColors]),
    @ecs.All,
  ],
) -> Unit {
  apply_target_sprite_color(
    pointer.target(),
    fn(colors) { colors.hover },
    query,
  )
}

///|
fn pointer_leave_sprite(
  pointer : @app.OnPointer[@app.PointerLeave],
  query : @ecs.Query[
    (@ecs.Mut[@sprite.Sprite], @ecs.Comp[PickableSpriteColors]),
    @ecs.All,
  ],
) -> Unit {
  apply_target_sprite_color(
    pointer.target(),
    fn(colors) { colors.normal },
    query,
  )
}

///|
fn pointer_down_sprite(
  pointer : @app.OnPointer[@app.PointerDown],
  query : @ecs.Query[
    (@ecs.Mut[@sprite.Sprite], @ecs.Comp[PickableSpriteColors]),
    @ecs.All,
  ],
) -> Unit {
  apply_target_sprite_color(
    pointer.target(),
    fn(colors) { colors.pressed },
    query,
  )
}

///|
fn pointer_up_sprite(
  pointer : @app.OnPointer[@app.PointerUp],
  query : @ecs.Query[
    (@ecs.Mut[@sprite.Sprite], @ecs.Comp[PickableSpriteColors]),
    @ecs.All,
  ],
) -> Unit {
  apply_target_sprite_color(
    pointer.target(),
    fn(colors) { colors.hover },
    query,
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system_param(setup)
  .add_pointer_observer2(fn(pointer, query) {
    pointer_enter_sprite(pointer, query)
  })
  .add_pointer_observer2(fn(pointer, query) {
    pointer_leave_sprite(pointer, query)
  })
  .add_pointer_observer2(fn(pointer, query) {
    pointer_down_sprite(pointer, query)
  })
  .add_pointer_observer2(fn(pointer, query) {
    pointer_up_sprite(pointer, query)
  })
  .run()
}
