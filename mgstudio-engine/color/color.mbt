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
pub struct Color {
  r : Float
  g : Float
  b : Float
  a : Float
}

///|
pub fn Color::new(r : Float, g : Float, b : Float, a : Float) -> Color {
  Color::{ r, g, b, a }
}

///|
pub impl ToJson for Color with to_json(self) {
  (self.r, self.g, self.b, self.a).to_json()
}

///|
pub impl @json.FromJson for Color with from_json(json, _path) {
  match (@json.from_json(json) catch { _ => None }) {
    Some((r, g, b, a)) => Color::new(r, g, b, a)
    None => {
      let values : Array[Float] = @json.from_json(json)
      if values.length() >= 4 {
        Color::new(values[0], values[1], values[2], values[3])
      } else if values.length() == 3 {
        Color::new(values[0], values[1], values[2], 1.0F)
      } else {
        Color::white()
      }
    }
  }
}
