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
pub type Oklcha = Color

///|
pub fn oklcha_from_color(color : Color) -> Oklcha {
  color
}

///|
pub fn oklcha_to_color(color : Oklcha) -> Color {
  color
}

///|
pub fn oklcha_gray(lightness : Float) -> Oklcha {
  color_gray(lightness)
}
