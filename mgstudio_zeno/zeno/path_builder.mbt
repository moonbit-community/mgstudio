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
/// Path builder sink interface.
///
/// Ported from upstream `zeno/src/path_builder.rs` (Apache-2.0 OR MIT).
pub(open) trait PathBuilder {
  move_to(Self, Point) -> Unit
  line_to(Self, Point) -> Unit
  quad_to(Self, Point, Point) -> Unit
  curve_to(Self, Point, Point, Point) -> Unit
  close(Self) -> Unit
}
