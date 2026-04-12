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
test "transmission phase: split range matches stepped partitioning" {
  let ranges = transmissive3d_split_range(10, 3)
  inspect(ranges.length(), content="3")
  inspect(ranges[0], content="(0, 4)")
  inspect(ranges[1], content="(4, 7)")
  inspect(ranges[2], content="(7, 10)")
}

///|
test "transmission node: pass config copy flag follows step count" {
  let config = MainTransmissivePass3dConfig::default().with_steps(3)
  inspect(
    main_transmissive_pass_3d_should_copy_texture_per_step(config),
    content="true",
  )
}
