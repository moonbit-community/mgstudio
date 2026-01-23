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
/// Hit testing.
///
/// Ported from upstream `zeno/src/hit_test.rs` (Apache-2.0 OR MIT).

///|
/// Builder for configuring and executing a hit test.
pub struct HitTest {
  data : &PathData
  mut style : Style
  mut transform : Transform?
  mut threshold : Int
  scratch : Ref[Scratch]?
}

///|
pub fn HitTest::new(data : &PathData) -> HitTest {
  HitTest::{
    data,
    style: Style::Fill(Fill::NonZero),
    transform: None,
    threshold: 0,
    scratch: None,
  }
}

///|
pub fn HitTest::with_scratch(
  data : &PathData,
  scratch : Ref[Scratch],
) -> HitTest {
  HitTest::{
    data,
    style: Style::Fill(Fill::NonZero),
    transform: None,
    threshold: 0,
    scratch: Some(scratch),
  }
}

///|
pub fn HitTest::style(self : HitTest, style : Style) -> HitTest {
  self.style = style
  self
}

///|
pub fn HitTest::transform(self : HitTest, transform : Transform?) -> HitTest {
  self.transform = transform
  self
}

///|
pub fn HitTest::threshold(self : HitTest, threshold : Int) -> HitTest {
  self.threshold = threshold
  self
}

///|
pub fn HitTest::hit(self : HitTest, point : Point) -> Bool {
  let buf : Array[Byte] = [0]
  let p = point.scale(-1.0)
  let mask = match self.scratch {
    Some(s) => Mask::with_scratch(self.data, s)
    None => Mask::new(self.data)
  }
  mask
  .style(self.style)
  .offset(p)
  .transform(self.transform)
  .size(1U, 1U)
  .render_into(buf)
  |> ignore
  let v = buf[0].to_int()
  if self.threshold == 0xFF {
    v >= self.threshold
  } else {
    v > self.threshold
  }
}
