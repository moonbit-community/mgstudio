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
test "mipmap: odd dimensions follow GPU mip sizing" {
  let width = 640
  let height = 480
  let base = Bytes::make(width * height * 4, (0).to_byte())
  let levels = asset_generate_mip_chain_rgba8(width, height, base)
  debug_inspect(levels.length(), content="10")
  debug_inspect(levels[0].0, content="640")
  debug_inspect(levels[0].1, content="480")
  debug_inspect(levels[6].0, content="10")
  debug_inspect(levels[6].1, content="7")
  debug_inspect(levels[9].0, content="1")
  debug_inspect(levels[9].1, content="1")
}

///|
test "mipmap: 3x3 stops at 1x1 in two levels" {
  let width = 3
  let height = 3
  let base = Bytes::make(width * height * 4, (0).to_byte())
  let levels = asset_generate_mip_chain_rgba8(width, height, base)
  debug_inspect(levels.length(), content="2")
  debug_inspect(levels[0].0, content="3")
  debug_inspect(levels[0].1, content="3")
  debug_inspect(levels[1].0, content="1")
  debug_inspect(levels[1].1, content="1")
}
