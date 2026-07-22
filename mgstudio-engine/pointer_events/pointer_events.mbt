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
pub type PointerId = Int

///|
pub(all) enum PointerEventKind {
  Move
  Enter
  Leave
  Down
  Up
  Click
  DragStart
  Drag
  DragEnd
} derive(Eq, Debug, ToJson, FromJson)

///|
pub struct PointerEvent {
  pointer : PointerId
  kind : PointerEventKind
  position : @math.Vec2
  target : @core.Entity?
  delta : @math.Vec2
  distance : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn PointerEvent::new(
  pointer : PointerId,
  kind : PointerEventKind,
  position : @math.Vec2,
  target? : @core.Entity? = None,
  delta? : @math.Vec2 = @math.Vec2::zero(),
  distance? : @math.Vec2 = @math.Vec2::zero(),
) -> PointerEvent {
  { pointer, kind, position, target, delta, distance }
}
