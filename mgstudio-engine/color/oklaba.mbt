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
pub type Oklaba = Color

///|
pub fn oklaba_from_color(color : Color) -> Oklaba {
  color
}

///|
pub fn oklaba_to_color(color : Oklaba) -> Color {
  color
}

///|
pub fn oklaba_gray(lightness : Float) -> Oklaba {
  color_gray(lightness)
}
