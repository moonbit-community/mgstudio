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
test "render mesh morph: lowest texture rectangle matches Bevy search" {
  guard render_morph_lowest_2d(27, max_edge=9) is Some(rect) else {
    fail("expected morph rect")
  }
  debug_inspect(rect.width(), content="3")
  debug_inspect(rect.height(), content="9")
  debug_inspect(rect.padding(), content="0")
}

///|
test "render mesh morph: image plan accounts for target layers and padding" {
  let plan = render_morph_target_image_plan(2, 3) catch {
    _ => fail("expected morph target image plan")
  }
  debug_inspect(plan.component_count_per_layer(), content="27")
  debug_inspect(plan.depth_or_array_layers(), content="2")
  debug_inspect(plan.byte_count(), content="216")
}
