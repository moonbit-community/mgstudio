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
// Bevy source: `bevy/crates/bevy_sprite_render/src/tilemap_chunk/tile_orientation.rs`.

///|
pub(all) enum TileOrientation {
  Default
  Rotate90
  Rotate180
  Rotate270
  MirrorH
  MirrorHRotate90
  MirrorHRotate180
  MirrorHRotate270
} derive(Eq, Debug)

///|
pub fn TileOrientation::from_bools(
  mirror_h : Bool,
  mirror_v : Bool,
  mirror_d : Bool,
) -> TileOrientation {
  match (mirror_h, mirror_v, mirror_d) {
    (false, false, false) => TileOrientation::Default
    (false, true, true) => TileOrientation::Rotate90
    (true, true, false) => TileOrientation::Rotate180
    (true, false, true) => TileOrientation::Rotate270
    (true, false, false) => TileOrientation::MirrorH
    (false, false, true) => TileOrientation::MirrorHRotate90
    (false, true, false) => TileOrientation::MirrorHRotate180
    (true, true, true) => TileOrientation::MirrorHRotate270
  }
}

///|
pub fn TileOrientation::to_int(self : TileOrientation) -> Int {
  match self {
    TileOrientation::Default => 0
    TileOrientation::Rotate90 => 3
    TileOrientation::Rotate180 => 6
    TileOrientation::Rotate270 => 5
    TileOrientation::MirrorH => 4
    TileOrientation::MirrorHRotate90 => 1
    TileOrientation::MirrorHRotate180 => 2
    TileOrientation::MirrorHRotate270 => 7
  }
}

///|
pub fn TileOrientation::mirror_h(self : TileOrientation) -> Bool {
  (self.to_int() & 0b100) != 0
}

///|
pub fn TileOrientation::mirror_v(self : TileOrientation) -> Bool {
  (self.to_int() & 0b010) != 0
}

///|
pub fn TileOrientation::mirror_d(self : TileOrientation) -> Bool {
  (self.to_int() & 0b001) != 0
}

///|
pub fn TileOrientation::inverse(self : TileOrientation) -> TileOrientation {
  match self {
    TileOrientation::Default => TileOrientation::Default
    TileOrientation::Rotate90 => TileOrientation::Rotate270
    TileOrientation::Rotate180 => TileOrientation::Rotate180
    TileOrientation::Rotate270 => TileOrientation::Rotate90
    TileOrientation::MirrorH => TileOrientation::MirrorH
    TileOrientation::MirrorHRotate90 => TileOrientation::MirrorHRotate90
    TileOrientation::MirrorHRotate180 => TileOrientation::MirrorHRotate180
    TileOrientation::MirrorHRotate270 => TileOrientation::MirrorHRotate270
  }
}

///|
pub fn TileOrientation::apply_to_ivec2(
  self : TileOrientation,
  pos : @math.IVec2,
) -> @math.IVec2 {
  let mut x = pos.x
  let mut y = -pos.y
  if self.mirror_d() {
    let previous_x = x
    x = y
    y = previous_x
  }
  if self.mirror_h() {
    x = -x
  }
  if self.mirror_v() {
    y = -y
  }
  @math.IVec2::new(x, -y)
}

///|
pub fn TileOrientation::and_then(
  self : TileOrientation,
  then : TileOrientation,
) -> TileOrientation {
  let mut mirror_h = self.mirror_h()
  let mut mirror_v = self.mirror_v()
  let mut mirror_d = self.mirror_d()
  if then.mirror_d() {
    mirror_d = !mirror_d
    let previous_h = mirror_h
    mirror_h = mirror_v
    mirror_v = previous_h
  }
  if then.mirror_h() {
    mirror_h = !mirror_h
  }
  if then.mirror_v() {
    mirror_v = !mirror_v
  }
  TileOrientation::from_bools(mirror_h, mirror_v, mirror_d)
}

///|
pub fn TileOrientation::to_string(self : TileOrientation) -> String {
  match self {
    TileOrientation::Default => "Default"
    TileOrientation::Rotate90 => "Rotate90"
    TileOrientation::Rotate180 => "Rotate180"
    TileOrientation::Rotate270 => "Rotate270"
    TileOrientation::MirrorH => "MirrorX"
    TileOrientation::MirrorHRotate90 => "MirrorXRotate90"
    TileOrientation::MirrorHRotate180 => "MirrorXRotate180"
    TileOrientation::MirrorHRotate270 => "MirrorXRotate270"
  }
}

///|
test "tile orientation bit flags match Bevy" {
  let cases : Array[(TileOrientation, Bool, Bool, Bool, Int)] = [
    (TileOrientation::Default, false, false, false, 0),
    (TileOrientation::Rotate90, false, true, true, 3),
    (TileOrientation::Rotate180, true, true, false, 6),
    (TileOrientation::Rotate270, true, false, true, 5),
    (TileOrientation::MirrorH, true, false, false, 4),
    (TileOrientation::MirrorHRotate90, false, false, true, 1),
    (TileOrientation::MirrorHRotate180, false, true, false, 2),
    (TileOrientation::MirrorHRotate270, true, true, true, 7),
  ]
  let mut ok = true
  for entry in cases {
    let (orientation, mirror_h, mirror_v, mirror_d, raw) = entry
    ok = ok &&
      TileOrientation::from_bools(mirror_h, mirror_v, mirror_d) == orientation &&
      orientation.mirror_h() == mirror_h &&
      orientation.mirror_v() == mirror_v &&
      orientation.mirror_d() == mirror_d &&
      orientation.to_int() == raw
  }
  debug_inspect(ok, content="true")
}

///|
test "tile orientation inverse composes to default" {
  let cases : Array[TileOrientation] = [
    TileOrientation::Default,
    TileOrientation::Rotate90,
    TileOrientation::Rotate180,
    TileOrientation::Rotate270,
    TileOrientation::MirrorH,
    TileOrientation::MirrorHRotate90,
    TileOrientation::MirrorHRotate180,
    TileOrientation::MirrorHRotate270,
  ]
  let mut ok = true
  for orientation in cases {
    ok = ok &&
      orientation.and_then(orientation.inverse()) == TileOrientation::Default &&
      orientation.inverse().and_then(orientation) == TileOrientation::Default
  }
  debug_inspect(ok, content="true")
}

///|
test "tile orientation transforms integer coordinates like Bevy" {
  let cases : Array[(TileOrientation, @math.IVec2)] = [
    (TileOrientation::Default, @math.IVec2::new(1, 2)),
    (TileOrientation::Rotate90, @math.IVec2::new(-2, 1)),
    (TileOrientation::Rotate180, @math.IVec2::new(-1, -2)),
    (TileOrientation::Rotate270, @math.IVec2::new(2, -1)),
    (TileOrientation::MirrorH, @math.IVec2::new(-1, 2)),
    (TileOrientation::MirrorHRotate90, @math.IVec2::new(-2, -1)),
    (TileOrientation::MirrorHRotate180, @math.IVec2::new(1, -2)),
    (TileOrientation::MirrorHRotate270, @math.IVec2::new(2, 1)),
  ]
  let mut ok = true
  for entry in cases {
    let (orientation, expected) = entry
    let actual = orientation.apply_to_ivec2(@math.IVec2::new(1, 2))
    ok = ok && actual.x == expected.x && actual.y == expected.y
  }
  debug_inspect(ok, content="true")
}
