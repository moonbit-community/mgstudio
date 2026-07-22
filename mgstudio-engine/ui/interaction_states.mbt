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
// Bevy source: `bevy/crates/bevy_ui/src/interaction_states.rs`.
pub struct RelativeCursorPosition {
  normalized_visible_node_rect : @math.Rect
  normalized : @math.Vec2?
} derive(ToJson, FromJson)

///|
pub fn RelativeCursorPosition::RelativeCursorPosition() -> RelativeCursorPosition {
  {
    normalized_visible_node_rect: @math.Rect::new(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ),
    normalized: None,
  }
}

///|
pub fn RelativeCursorPosition::cursor_over(
  self : RelativeCursorPosition,
) -> Bool {
  match self.normalized {
    Some(normalized) => self.normalized_visible_node_rect.contains(normalized)
    None => false
  }
}

///|
pub struct InteractionDisabled {} derive(ToJson, FromJson)

///|
#warnings("-unnecessary_annotation")
pub fn InteractionDisabled::InteractionDisabled() -> InteractionDisabled {
  InteractionDisabled::{  }
}

///|
pub struct Pressed {} derive(ToJson, FromJson)

///|
#warnings("-unnecessary_annotation")
pub fn Pressed::Pressed() -> Pressed {
  Pressed::{  }
}

///|
pub struct Checkable {} derive(ToJson, FromJson)

///|
#warnings("-unnecessary_annotation")
pub fn Checkable::Checkable() -> Checkable {
  Checkable::{  }
}

///|
pub struct Checked {} derive(ToJson, FromJson)

///|
#warnings("-unnecessary_annotation")
pub fn Checked::Checked() -> Checked {
  Checked::{  }
}

///|
fn update_accessibility_node(
  world : @ecs.World,
  entity : @core.Entity,
  update : (@a11y.AccessibilityNode) -> Unit,
) -> Unit {
  match (try! world.get_by_key(entity, @a11y.ecs_key_accessibility_node)) {
    Some(accessibility) => {
      update(accessibility)
      ignore(
        try! world.replace(
          entity, @a11y.ecs_key_accessibility_node, accessibility,
        ),
      )
    }
    None => ()
  }
}

///|
pub fn on_add_disabled(
  add : @ecs.ComponentOn[@ecs.Add, InteractionDisabled],
) -> Unit {
  update_accessibility_node(add.world(), add.entity(), fn(accessibility) {
    accessibility.set_disabled()
  })
}

///|
pub fn on_remove_disabled(
  remove : @ecs.ComponentOn[@ecs.Remove, InteractionDisabled],
) -> Unit {
  update_accessibility_node(remove.world(), remove.entity(), fn(accessibility) {
    accessibility.clear_disabled()
  })
}

///|
pub fn on_add_checkable(add : @ecs.ComponentOn[@ecs.Add, Checked]) -> Unit {
  let world = add.world()
  let entity = add.entity()
  let checked = try! world.contains_by_key(entity, ecs_key_checked)
  update_accessibility_node(world, entity, fn(accessibility) {
    accessibility.set_toggled(@moon_accesskit.Toggled::from_bool(checked))
  })
}

///|
pub fn on_remove_checkable(add : @ecs.ComponentOn[@ecs.Add, Checked]) -> Unit {
  update_accessibility_node(add.world(), add.entity(), fn(accessibility) {
    accessibility.clear_toggled()
  })
}

///|
pub fn on_add_checked(add : @ecs.ComponentOn[@ecs.Add, Checked]) -> Unit {
  update_accessibility_node(add.world(), add.entity(), fn(accessibility) {
    accessibility.set_toggled(True)
  })
}

///|
pub fn on_remove_checked(
  remove : @ecs.ComponentOn[@ecs.Remove, Checked],
) -> Unit {
  update_accessibility_node(remove.world(), remove.entity(), fn(accessibility) {
    accessibility.set_toggled(False)
  })
}
