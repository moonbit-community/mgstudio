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
/// Path commands.
///
/// Ported from upstream `zeno/src/command.rs` (Apache-2.0 OR MIT).
pub(all) enum Command {
  MoveTo(Point)
  LineTo(Point)
  QuadTo(Point, Point)
  CurveTo(Point, Point, Point)
  Close
}

///|
pub fn Command::transform(self : Command, transform : Transform) -> Command {
  match self {
    Command::MoveTo(p) => Command::MoveTo(transform.transform_point(p))
    Command::LineTo(p) => Command::LineTo(transform.transform_point(p))
    Command::QuadTo(c, p) =>
      Command::QuadTo(
        transform.transform_point(c),
        transform.transform_point(p),
      )
    Command::CurveTo(c1, c2, p) =>
      Command::CurveTo(
        transform.transform_point(c1),
        transform.transform_point(c2),
        transform.transform_point(p),
      )
    Command::Close => Command::Close
  }
}

///|
/// Iterator over point/verb lists (equivalent to `PointsCommands` in upstream).
pub struct PointsCommands {
  points : Array[Point]
  verbs : Array[Verb]
  mut ppos : Int
  mut vpos : Int
}

///|
pub fn PointsCommands::new(
  points : Array[Point],
  verbs : Array[Verb],
) -> PointsCommands {
  PointsCommands::{ points, verbs, ppos: 0, vpos: 0 }
}

///|
pub fn PointsCommands::next(self : PointsCommands) -> Command? {
  if self.vpos >= self.verbs.length() {
    return None
  }
  let verb = self.verbs[self.vpos]
  self.vpos = self.vpos + 1
  match verb {
    Verb::MoveTo => {
      if self.ppos >= self.points.length() {
        return None
      }
      let p = self.points[self.ppos]
      self.ppos = self.ppos + 1
      Some(Command::MoveTo(p))
    }
    Verb::LineTo => {
      if self.ppos >= self.points.length() {
        return None
      }
      let p = self.points[self.ppos]
      self.ppos = self.ppos + 1
      Some(Command::LineTo(p))
    }
    Verb::QuadTo => {
      if self.ppos + 1 >= self.points.length() {
        return None
      }
      let c = self.points[self.ppos]
      let p = self.points[self.ppos + 1]
      self.ppos = self.ppos + 2
      Some(Command::QuadTo(c, p))
    }
    Verb::CurveTo => {
      if self.ppos + 2 >= self.points.length() {
        return None
      }
      let c1 = self.points[self.ppos]
      let c2 = self.points[self.ppos + 1]
      let p = self.points[self.ppos + 2]
      self.ppos = self.ppos + 3
      Some(Command::CurveTo(c1, c2, p))
    }
    Verb::Close => Some(Command::Close)
  }
}
