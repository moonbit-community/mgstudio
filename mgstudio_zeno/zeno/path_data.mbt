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
/// Path data abstraction.
///
/// Ported from upstream `zeno/src/path_data.rs` (Apache-2.0 OR MIT).
pub(open) trait PathData {
  commands(Self) -> Iter[Command]
  copy_to(Self, &PathBuilder) -> Unit
}

///|
pub struct PointsVerbsPathData {
  points : Array[Point]
  verbs : Array[Verb]
}

///|
pub fn PointsVerbsPathData::new(
  points : Array[Point],
  verbs : Array[Verb],
) -> PointsVerbsPathData {
  PointsVerbsPathData::{ points, verbs }
}

///|
pub impl PathData for PointsVerbsPathData with commands(self) {
  let it = PointsCommands::new(self.points, self.verbs)
  Iter::new(fn() { it.next() })
}

///|
pub impl PathData for PointsVerbsPathData with copy_to(self, sink) {
  let it = self.commands()
  while it.next() is Some(cmd) {
    match cmd {
      Command::MoveTo(p) => sink.move_to(p)
      Command::LineTo(p) => sink.line_to(p)
      Command::QuadTo(c, p) => sink.quad_to(c, p)
      Command::CurveTo(c1, c2, p) => sink.curve_to(c1, c2, p)
      Command::Close => sink.close()
    }
  }
}
