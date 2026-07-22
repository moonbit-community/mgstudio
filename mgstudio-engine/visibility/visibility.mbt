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
/// Bevy-like visibility components (2D-first).

///|
pub(all) enum Visibility {
  Inherited
  Hidden
  Visible
} derive(Eq, Debug)

///|
pub impl ToJson for Visibility with fn to_json(self) {
  match self {
    Hidden => (0).to_json()
    Inherited => (1).to_json()
    Visible => (2).to_json()
  }
}

///|
pub impl @json.FromJson for Visibility with fn from_json(json, _path) {
  let tag : Int = try! @json.from_json(json)
  match tag {
    0 => Hidden
    1 => Inherited
    2 => Visible
    _ => Inherited
  }
}

///|
pub fn Visibility::is_visible(self : Visibility) -> Bool {
  match self {
    Hidden => false
    Inherited | Visible => true
  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::Visibility::toggle_inherited_visible`.
pub fn Visibility::toggle_inherited_visible(self : Visibility) -> Visibility {
  match self {
    Inherited => Visible
    Visible => Inherited
    Hidden => Hidden
  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::Visibility::toggle_inherited_hidden`.
pub fn Visibility::toggle_inherited_hidden(self : Visibility) -> Visibility {
  match self {
    Inherited => Hidden
    Hidden => Inherited
    Visible => Visible
  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::Visibility::toggle_visible_hidden`.
pub fn Visibility::toggle_visible_hidden(self : Visibility) -> Visibility {
  match self {
    Visible => Hidden
    Hidden => Visible
    Inherited => Inherited
  }
}

///|
#valtype
pub struct InheritedVisibility {
  visible : Bool
} derive(Eq, Debug)

///|
pub impl ToJson for InheritedVisibility with fn to_json(self) {
  self.visible.to_json()
}

///|
pub impl @json.FromJson for InheritedVisibility with fn from_json(json, _path) {
  let visible : Bool = try! @json.from_json(json)
  InheritedVisibility::new(visible)
}

///|
pub fn InheritedVisibility::new(visible : Bool) -> InheritedVisibility {
  { visible, }
}

///|
pub fn InheritedVisibility::hidden() -> InheritedVisibility {
  InheritedVisibility::new(false)
}

///|
pub fn InheritedVisibility::visible() -> InheritedVisibility {
  InheritedVisibility::new(true)
}

///|
pub fn InheritedVisibility::get(self : InheritedVisibility) -> Bool {
  self.visible
}

///|
pub fn InheritedVisibility::is_visible(self : InheritedVisibility) -> Bool {
  self.visible
}

///|
#valtype
pub struct ViewVisibility {
  bits : Int
} derive(Eq, Debug)

///|
pub impl ToJson for ViewVisibility with fn to_json(self) {
  self.get().to_json()
}

///|
pub impl @json.FromJson for ViewVisibility with fn from_json(json, _path) {
  let visible : Bool = try! @json.from_json(json)
  ViewVisibility::new(visible)
}

///|
pub fn ViewVisibility::new(visible : Bool) -> ViewVisibility {
  { bits: if visible { 1 } else { 0 } }
}

///|
pub fn ViewVisibility::hidden() -> ViewVisibility {
  ViewVisibility::new(false)
}

///|
/// Returns the state used by entities that are visible in both the current and
/// previous frame.
pub fn ViewVisibility::visible() -> ViewVisibility {
  { bits: 3 }
}

///|
pub fn ViewVisibility::get(self : ViewVisibility) -> Bool {
  (self.bits & 1) != 0
}

///|
pub fn ViewVisibility::is_visible(self : ViewVisibility) -> Bool {
  self.get()
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::ViewVisibility::was_visible_now_hidden`.
pub fn ViewVisibility::was_visible_now_hidden(self : ViewVisibility) -> Bool {
  (self.bits & 3) == 2
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::ViewVisibility::update`.
// This value-returning API intentionally does not keep Bevy's mutating method
// name: an old `value.update()` call would otherwise compile and discard the
// replacement value after the MoonBit value-type migration.
pub fn ViewVisibility::advance_frame(self : ViewVisibility) -> ViewVisibility {
  { bits: (self.bits & 1) << 1 }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::SetViewVisibility::set_visible`.
pub fn ViewVisibility::with_visible(self : ViewVisibility) -> ViewVisibility {
  { bits: self.bits | 1 }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::SetViewVisibility`.
pub(open) trait SetViewVisibility {
  fn set_visible(Self) -> Unit
}

///|
pub impl SetViewVisibility for @ecs.Write[ViewVisibility] with fn set_visible(
  self,
) {
  let current = self.peek()
  if (current.bits & 1) == 0 {
    if (current.bits & 2) != 0 {
      self.bypass_change_detection(fn(value) { value.with_visible() })
    } else {
      self.set(current.with_visible())
    }
  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::VisibilityClass`.
pub struct VisibilityClass {
  classes : Array[Int]
} derive(Eq, Debug)

///|
pub fn VisibilityClass::VisibilityClass(
  classes? : Array[Int] = [],
) -> VisibilityClass {
  { classes, }
}

///|
pub fn VisibilityClass::single(class_id : Int) -> VisibilityClass {
  { classes: [class_id] }
}

///|
pub fn VisibilityClass::add(self : VisibilityClass, class_id : Int) -> Unit {
  for current in self.classes {
    if current == class_id {
      return
    }
  }
  self.classes.push(class_id)
}

///|
pub fn VisibilityClass::iter(self : VisibilityClass) -> Array[Int] {
  self.classes
}

///|
pub fn VisibilityClass::is_empty(self : VisibilityClass) -> Bool {
  self.classes.length() == 0
}

///|
pub struct NoFrustumCulling {} derive(Eq, Debug)

///|
#warnings("-unnecessary_annotation")
pub fn NoFrustumCulling::NoFrustumCulling() -> NoFrustumCulling {
  NoFrustumCulling::{  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::NoAutoAabb`.
// Add this marker to disable automatic AABB recomputation systems.
pub struct NoAutoAabb {} derive(Eq, Debug)

///|
#warnings("-unnecessary_annotation")
pub fn NoAutoAabb::NoAutoAabb() -> NoAutoAabb {
  NoAutoAabb::{  }
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::NoCpuCulling`.
// This can be attached to cameras or entities to bypass CPU-side frustum
// culling while keeping the rest of the visibility flow unchanged.
pub struct NoCpuCulling {} derive(Eq, Debug)

///|
#warnings("-unnecessary_annotation")
pub fn NoCpuCulling::NoCpuCulling() -> NoCpuCulling {
  NoCpuCulling::{  }
}

///|
//
// Mirrors Bevy's `VisibilityRange` shape:
// - `start_margin_*` defines the near-side visible threshold range.
// - `end_margin_*` defines the far-side visible threshold range.
// - `use_aabb` switches distance origin from entity translation to mesh AABB
//   center when available.
pub struct VisibilityRange {
  start_margin_min : Float
  start_margin_max : Float
  end_margin_min : Float
  end_margin_max : Float
  use_aabb : Bool
}

///|
pub fn VisibilityRange::new(
  start_margin_min : Float,
  start_margin_max : Float,
  end_margin_min : Float,
  end_margin_max : Float,
  use_aabb : Bool,
) -> VisibilityRange {
  {
    start_margin_min,
    start_margin_max,
    end_margin_min,
    end_margin_max,
    use_aabb,
  }
}

///|
pub fn VisibilityRange::abrupt(start : Float, end : Float) -> VisibilityRange {
  VisibilityRange::new(start, start, end, end, false)
}

///|
pub impl ToJson for VisibilityRange with fn to_json(self) {
  (
    self.start_margin_min,
    self.start_margin_max,
    self.end_margin_min,
    self.end_margin_max,
    self.use_aabb,
  ).to_json()
}

///|
pub impl @json.FromJson for VisibilityRange with fn from_json(json, path) {
  let (
    start_margin_min,
    start_margin_max,
    end_margin_min,
    end_margin_max,
    use_aabb,
  ) : (Float, Float, Float, Float, Bool) = @json.from_json(json, path~)
  VisibilityRange::new(
    start_margin_min, start_margin_max, end_margin_min, end_margin_max, use_aabb,
  )
}

///|
pub fn VisibilityRange::always_visible() -> VisibilityRange {
  VisibilityRange::new(0.0F, 0.0F, 1_000_000.0F, 1_000_000.0F, false)
}

///|
pub fn VisibilityRange::invisible() -> VisibilityRange {
  VisibilityRange::new(0.0F, 0.0F, 0.0F, 0.0F, false)
}

///|
pub fn VisibilityRange::start_margin_min(self : VisibilityRange) -> Float {
  self.start_margin_min
}

///|
pub fn VisibilityRange::start_margin_max(self : VisibilityRange) -> Float {
  self.start_margin_max
}

///|
pub fn VisibilityRange::end_margin_min(self : VisibilityRange) -> Float {
  self.end_margin_min
}

///|
pub fn VisibilityRange::end_margin_max(self : VisibilityRange) -> Float {
  self.end_margin_max
}

///|
pub fn VisibilityRange::use_aabb(self : VisibilityRange) -> Bool {
  self.use_aabb
}

///|
pub fn VisibilityRange::is_abrupt(self : VisibilityRange) -> Bool {
  self.start_margin_min == self.start_margin_max &&
  self.end_margin_min == self.end_margin_max
}

///|
pub fn VisibilityRange::is_visible_at_all(
  self : VisibilityRange,
  camera_distance : Float,
) -> Bool {
  camera_distance >= self.start_margin_min &&
  camera_distance < self.end_margin_max
}

///|
pub fn VisibilityRange::is_culled(
  self : VisibilityRange,
  camera_distance : Float,
) -> Bool {
  !self.is_visible_at_all(camera_distance)
}
