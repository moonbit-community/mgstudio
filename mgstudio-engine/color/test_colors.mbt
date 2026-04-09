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
pub struct TestColor {
  name : String
  color : Color
  hsla : Hsla
  hsva : Hsva
  hwba : Hwba
}

///|
pub fn test_colors() -> Array[TestColor] {
  [
    TestColor::{
      name: "black",
      color: Color::black(),
      hsla: Hsla::new(0.0F, 0.0F, 0.0F, 1.0F),
      hsva: Hsva::new(0.0F, 0.0F, 0.0F, 1.0F),
      hwba: Hwba::new(0.0F, 0.0F, 1.0F, 1.0F),
    },
    TestColor::{
      name: "white",
      color: Color::white(),
      hsla: Hsla::new(0.0F, 0.0F, 1.0F, 1.0F),
      hsva: Hsva::new(0.0F, 0.0F, 1.0F, 1.0F),
      hwba: Hwba::new(0.0F, 1.0F, 0.0F, 1.0F),
    },
    TestColor::{
      name: "red",
      color: Color::srgba(1.0F, 0.0F, 0.0F, 1.0F),
      hsla: Hsla::new(0.0F, 1.0F, 0.5F, 1.0F),
      hsva: Hsva::new(0.0F, 1.0F, 1.0F, 1.0F),
      hwba: Hwba::new(0.0F, 0.0F, 0.0F, 1.0F),
    },
    TestColor::{
      name: "green",
      color: Color::srgba(0.0F, 1.0F, 0.0F, 1.0F),
      hsla: Hsla::new(120.0F, 1.0F, 0.5F, 1.0F),
      hsva: Hsva::new(120.0F, 1.0F, 1.0F, 1.0F),
      hwba: Hwba::new(120.0F, 0.0F, 0.0F, 1.0F),
    },
    TestColor::{
      name: "blue",
      color: Color::srgba(0.0F, 0.0F, 1.0F, 1.0F),
      hsla: Hsla::new(240.0F, 1.0F, 0.5F, 1.0F),
      hsva: Hsva::new(240.0F, 1.0F, 1.0F, 1.0F),
      hwba: Hwba::new(240.0F, 0.0F, 0.0F, 1.0F),
    },
  ]
}
